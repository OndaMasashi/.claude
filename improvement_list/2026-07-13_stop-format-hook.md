# フォーマット整形フックの Stop 遅延方式への移行

## 対象

- `hooks/auto-format.sh`（PostToolUse: Edit|Write|MultiEdit）
- `hooks/format-on-stop.sh`（新設・Stop フック）
- `hooks/format-queue-common.sh`（新設・キュー置き場の共通定義）
- `settings.json`（`hooks.Stop` 追加、PostToolUse matcher を `Edit|Write` → `Edit|Write|MultiEdit` へ拡張）

## 変更内容

- 従来 PostToolUse（Edit/Write 直後）で即 Prettier 整形していた方式を廃止。
- `auto-format.sh` を producer 化: 整形はせず、編集された `.ts/.tsx/.js/.jsx` のパスを
  `${TMPDIR:-/tmp}/claude-format-queue/<session_id>.txt` へ追記するだけに変更。
- `format-on-stop.sh` を新設（consumer）: Stop（end_turn ごと）にキューを読み、祖先に
  `node_modules/prettier` がある PJ のファイルのみ `npx --no-install prettier --write` で整形。
- `settings.json` に Stop フックを配線、PostToolUse matcher を MultiEdit まで拡張。

## 理由

- PostToolUse 即整形は Edit 直後にディスクを書き換え、モデルのファイル像と乖離させ、続く Edit が
  `old_string` 不一致で失敗 → 再 Read ループに陥る事故があった。
- 整形を Stop（ターン終了）へ遅延することで、1ターン内の Edit 連鎖中はディスクを触らず乖離を防ぐ。

## 敵対的レビュー（動的ワークフロー・4軸 × 反証検証）で確定・反映した堅牢化

- 孤児キュー掃除 `-mtime +1` → `+7`（生存中セッションのキュー誤削除窓を実質排除）。
- キュー退避を `cat→rm` から `mv`（rename）へ（同一 session_id 並行時の追記取りこぼしを回避）。
- docstring 精密化: 同一ターン内 edit+commit は未整形コミットになる制約、Yarn PnP 非対応を明記。
- 却下（refuted）: 並行 prettier 破損（決定論整形で無害）／サブエージェント別 session_id（実測で親と同一）／
  失敗 Edit のキュー混入（PostToolUse は成功時のみ発火・失敗は PostToolUseFailure）。

## /refine での追加改善（code-simplifier → code-review）

- `format-on-stop.sh`: 祖先探索を `find_prettier_root()` 関数へ抽出（可読性）。
- 正確性レビューで4件検出し、①②③を修正・④は既存 mv 方式で実質解決と判断:
  - ① 孤児掃除が退避ファイル `.processing` を回収しない（`*.txt` 限定）→ 掃除対象に `.processing` を追加。
  - ② キュー置き場 `${TMPDIR:-/tmp}/claude-format-queue` の2ファイル重複 → `format-queue-common.sh` に集約し両フックで source（読めなければ no-op）。
  - ③ 孤児掃除が自セッションのアクティブキューを消しうる → find に自 session の `.txt`/`.processing` 除外条件を追加。
  - ④ 同一 session_id 並行時の追記取りこぼし → mv アトミック退避で退避後の追記は次 Stop へ繰り越すため実質解決。flock は環境（Git Bash）に無く、mkdir ロックはデッドロックリスクのため見送り。

## 既知の残存制約

- 同一ターン内で「編集 → git commit」すると、コミット時点は未整形（整形は Stop 後）。
- Yarn PnP（node_modules を物理的に持たない構成）は非対応（サイレント no-op）。
- settings.json 変更のフック反映は、次回セッション/再起動後になる可能性。

## 検証

- fake PJ + npx スタブでキュー記録・prettier 判定・`stop_hook_active` 安全弁・スペースパス・mv 退避を確認（全項目パス）。
- settings.json はラウンドトリップ検証（加えた2変更を戻すと元と完全一致）＋ LF 改行維持で反映。
  - 注意: Windows ビルドの `jq.exe` は stdout を CRLF 出力するため、`tr -d '\r'` で LF 正規化が必須だった。
