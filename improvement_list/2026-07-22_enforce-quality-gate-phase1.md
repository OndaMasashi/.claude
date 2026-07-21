# 品質ゲート強制化 Phase 1: post-commit-simplify.sh の「届く化」

計画: `plans/fancy-riding-brooks.md`（二段階方針: 届く化 → 実測 → 必要なら Stop 強制）

## 対象

- `hooks/post-commit-simplify.sh`（settings.json は無変更 — 既存の PostToolUse:Bash 配線を流用）

## 変更内容

- `git commit` 検知時の出力を、プレーン `echo`（exit0）から `hookSpecificOutput.additionalContext`（exit0+JSON、`jq -nc ... | tr -d '\r'`）へ昇格。
- 誘導文を拡張: /refine 実行に加えて improvement_list/ への改修記録も促す（軽微な変更は対象外の免責付き）。
- 冒頭コメントに出力方式の設計理由（additionalContext が正規ルートであること・CRLF 対策）を記載。

## 理由

- ハーネス棚卸しで最優先負債とされた「品質ゲートの強制力の非対称」の是正 Phase 1。
- Claude Code 公式仕様（https://code.claude.com/docs/en/hooks）では、PostToolUse の exit0 プレーン stdout は debug ログ止まりでモデルのコンテキストに入らない（入る例外は UserPromptSubmit / UserPromptExpansion / SessionStart のみ）。旧実装の /refine 誘導は**届かず空振りしていた疑いが濃厚**だった。
- additionalContext(JSON) は PostToolUse でモデルへ確実に注入される正規ルート（公式例・導入済み公式プラグイン security-guidance の実装とも一致）。

## 検証

- 単体テスト: `git commit` 入力→ 正しい JSON 出力・jq パース OK / 非 commit 入力→無出力 exit0 / 不正入力→no-op exit0。
- CRLF: 出力の生 CR=0、スクリプトファイル CR=0、JSON 内 `\r` エスケープ=0 を生バイト直採で確認（`od|grep` は `/refine` 文字列等への誤マッチで使えないと判明。検証パイプの jq.exe 自身が行末 CR を付けることも対照実験で証明）。
- /refine 実施: code-simplifier=変更不要（兄弟フックと整合・堅牢性合格）。code-review 相当（4視点並列＋信頼度検証）=確定バグ 0 件。

## 残作業

1. **Phase 1.5 実測**（数日後）: commit 後に /refine が実際に実行されたかを bash-command-log.txt / skills usage.log / improvement_list 増分で確認（反証条件は計画に事前登録済み）。不足なら Phase 2（Stop フックの decision:block 強制）へ。
2. **[スコア75] コメント表現2件**（報告のみ・未修正）: (a) 「届かない」が本番実測前なのに断定形（HYPOTHESIS 明記が規律に合う）。(b) CRLF コメントが「MSG 値内に CR が入った場合は jq が `\r` エスケープ化し tr では守れない」経路を説明していない（コメント腐敗の芽）。
3. **[スコア50] リポジトリ設定の時限リスク**: `core.autocrlf=true` かつ `.gitattributes` なし。git がフックを書き直すと CRLF 化し、構文エラーまたは JSON 汚染の恐れ（全12フック共通）。恒久対策候補: `.gitattributes` に `*.sh text eol=lf`。
4. **[スコア55] 非コードコミットでも誘導が発火**: トリガーが `git commit` 文字列のみでコード/非コードを区別しない。誘導文の免責（軽微は対象外）で緩和済みだが、ノイズが目立てば tool_input の差分内容での絞り込みを検討。
5. **plan-brainstorm.sh の届く化**（意図的スコープ外）: PreToolUse での additionalContext は公式明文が弱く要実測。別タスク。
