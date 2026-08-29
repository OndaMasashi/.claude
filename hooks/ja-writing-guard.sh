#!/bin/bash
# UserPromptSubmit hook: 日本語の作文・推敲の依頼を検出し、NG ワード表の参照を促す。
# 該当しなければ何も出力しない。どんな失敗でもプロンプトは止めない（常に exit 0）。

input=$(cat)

# フィールド名は公式ドキュメントでは prompt。ただし公式プラグイン hookify は
# user_prompt を読んでいるため、将来どちらに寄っても壊れないよう両方受ける。
prompt=""
if command -v jq >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // .user_prompt // empty' 2>/dev/null)
elif command -v python >/dev/null 2>&1; then
  # jq が無い環境向けのフォールバック。jq がある場合はここに来ない
  # （JSON 破損時など jq の結果が空でも python の結果も同じく空になるため、
  # 二重起動しても得られる結果は変わらない）
  prompt=$(printf '%s' "$input" | python -c 'import sys,json;d=json.load(sys.stdin);sys.stdout.write(d.get("prompt") or d.get("user_prompt") or "")' 2>/dev/null)
fi
# 抽出できなければ何もしない。生 JSON を対象にすると transcript_path の .jsonl が
# 除外語 json に必ずマッチし、永久に無音になる
[ -z "$prompt" ] && exit 0

# 作文・推敲の依頼を示す語（動詞 + 文書の種類）
WRITE_RE='書いて|書き直|書き換え|執筆|作文|推敲|校正|添削|リライト|下書き|清書|要約して'
WRITE_RE="$WRITE_RE"'|文案|文面|文言|原稿|文章|文書|記事|ブログ|コラム|投稿'
WRITE_RE="$WRITE_RE"'|メール|メッセージ|返信|返事|お礼|お詫び|依頼文|案内文|挨拶|あいさつ'
WRITE_RE="$WRITE_RE"'|レポート|報告書|提案書|企画書|週報|日報|月報|議事録|要旨|所感'
WRITE_RE="$WRITE_RE"'|お知らせ|アナウンス|告知|プレスリリース|リリースノート'
WRITE_RE="$WRITE_RE"'|紹介文|説明文|自己紹介|プレゼン|スライド|レジュメ'

# コード・設定の作業（作文ではないので対象外）
CODE_RE='コード|関数|クラス|メソッド|スクリプト|SQL|クエリ|設定ファイル|yaml|YAML|json|JSON|正規表現|型定義|コミットメッセージ|リファクタ|実装して'
CODE_RE="$CODE_RE"'|テストコード|テストケース|ユニットテスト|E2E'

printf '%s' "$prompt" | grep -qE "$WRITE_RE" || exit 0
printf '%s' "$prompt" | grep -qE "$CODE_RE" && exit 0

echo "[Auto-Trigger] 日本語の作文・推敲の依頼を検出しました。出力する前に ~/.claude/ng-words-ja.md を Read し、NG ワード（特にセクション 2「空語」）と NG 構文を除いてから出力してください。記事・レポートなど長文なら japanese-longform-writing スキルの併用も検討してください。"
exit 0
