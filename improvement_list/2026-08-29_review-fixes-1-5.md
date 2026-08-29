# 直近修正のレビュー指摘 1〜5 の是正

計画: `plans/1-5-gleaming-moth.md`

直近の未コミット変更（日本語作文フック新設・コミットメッセージのファイル渡し化・CLAUDE.md 増補・orchestration-guide 更新）をレビューし、検出した5件を修正した。

## 対象

- `hooks/ja-writing-guard.sh`
- `commands/commit.md`
- `commands/cp.md`
- `ng-words-ja.md`
- `CLAUDE.md`
- `orchestration-guide.md`

## 変更内容

### 1. フックが一度も発火しない不具合（`hooks/ja-writing-guard.sh`）

標準入力 JSON から読むフィールド名が `user_prompt` だったが、`UserPromptSubmit` が実際に渡すのは `prompt`。抽出失敗時は無音 exit 0 する設計のため、**新設した日本語作文ガードが一度も鳴っていなかった**。`.prompt // .user_prompt` の両対応に修正。

あわせて `/refine`（code-simplifier）の指摘で、jq / python フォールバックを `if`＋`if` から `if`＋`elif` に変更。jq があるのに抽出が空になるケース（JSON 破損等）では python でも結果は同じく空になるため、毎プロンプト走るホットパスで無駄なプロセス起動をしていた。

### 2. `/commit`・`/cp` が worktree 内で必ず失敗する不具合

メッセージファイルの置き場所を `.git/` の固定文字列で指定していた。**リンク worktree では `.git` はディレクトリではなくファイル**なので `.git/CLAUDE_COMMIT_MSG.txt` は `Not a directory` で失敗する。`git rev-parse --absolute-git-dir` の出力を使う形に変更し、両コマンドの `allowed-tools` に `Bash(git rev-parse:*)` を追加した。

### 3. ラベル形式の規則衝突（`ng-words-ja.md`）

`**ラベル:** 内容` 形式の箇条書き禁止が報告書・週報を適用対象に含んでおり、CLAUDE.md が義務づける完了報告の `**依頼**:` 形式と正面衝突していた。禁止の対象を「人に納品する文章」に限定し、Claude からユーザーへの完了報告・AskUserQuestion の設問文を対象外と明記。CLAUDE.md 側は変更していない。

### 4. 「初出1回だけ」の範囲が未定義（`CLAUDE.md` の補足説明ルール②）

1つの報告の中でなのかセッション全体でなのかが書かれておらず、長い作業で判定がぶれる。「1つの報告・1つの質問の中で数える」と定義する1文を追記。

### 5. バージョン記述が導入済み CLI より先行（`orchestration-guide.md`）

追記されていた挙動が v2.1.224 / 232 / 234〜239 のもので、導入済み CLI は 2.1.220。全項目に `✅導入済み` / `⏳未到達` の印と確認日（2026-08-29 / CLI 2.1.220）を付けた。うち2箇所は実測に基づき記述そのものを訂正:

- **fork サブエージェント**: 「v2.1.232 でデフォルト on」と書かれていたが、`subagent_type: "fork"` の起動を試すと `Agent type 'fork' not found`。Agent ツールの説明文には fork の記載があるため誤解しやすい点も併記した。
- **セッション間メッセージング**: 「Windows は v2.1.239 で対応」は観測と矛盾。2.1.220 の本環境で `ListAgents` が14セッションを列挙した。「一覧取得は動作／送信は未検証」に書き換えて元の記述を撤回。

## 理由

指摘1・2 は実害のある不具合。特に2は `orchestration-guide.md` が worktree を主要な分離手段として推奨しているため、遠からず必ず踏む。指摘3・4 は規則同士の矛盾で、放置すると修正の往復を招く。指摘5 は「使えない機能を選択肢として提示する」リスク。

## 検証

- **フック**: `prompt` / `user_prompt` の両形式で発火、コード作業（「この関数のテストコードを書いて」）と非作文（「ビルドエラーを直して」）で無音、をスクリプト単体で確認。
- **worktree**: 使い捨てリポジトリに worktree を作り、`--absolute-git-dir` 経由で日本語コミットメッセージが化けずに通ること、旧方式の `.git/` 固定が `Not a directory` で落ちることの両方を確認。
- **fork の未到達**: 実際に起動を試みてエラーを確認（憶測でなく実測）。
- `/refine` 実施: code-simplifier=1件適用（上記1の elif 化）。`/code-review`=確定バグ0件。security-reviewer=下記。

## 残作業

1. **フックの実環境確認（必須）**: 上の検証はスクリプト単体テストであって、ハーネスが実際に渡すフィールド名の証明ではない。対話セッションで作文依頼を打ち `[Auto-Trigger]` が出ることを確認するまで、修正1は完了と見なさない。
2. **未コミット状態の解消**: `ng-words-ja.md` と `hooks/ja-writing-guard.sh` が未追跡のまま。CLAUDE.md は既にこれらを参照しており、参照先だけがバージョン管理外になっている。
3. **今回スコープ外とした指摘**（レビューでは検出済み）:
   - `.bak` 7ファイルと `CLAUDE - コピー (3).md` の `.gitignore` 漏れ
   - `Co-Authored-By` の三者不一致（commit.md は `Claude`、cp.md は `Claude Opus 4.8`、実際は Opus 5）
   - フックの除外語が包含語を無条件に上書きする件（「リリースノートを書いて。実装した内容を反映して」で黙る）
   - `commands/*.md` の `allowed-tools` に入れた `Write` が無制限
4. **バージョン印の更新**: `autoUpdatesChannel: latest` で自動更新されるため、CLI 更新後に `orchestration-guide.md` の `⏳未到達` を見直す。
