#!/bin/bash
# フォーマット対象のキューイング (PostToolUse: Edit|Write)
#
# 【2026-07 方針転換】以前はこの時点で Prettier 整形を実行していた。しかし
# Edit/Write 直後にディスクが書き換わると、モデルが把握しているファイル像と
# 乖離し、続く Edit が old_string 不一致で失敗→再 Read ループに陥る事故が
# あった。そこで整形はターン終了時 (Stop フック: format-on-stop.sh) へ移し、
# ここでは「整形候補パスをセッション別キューへ追記するだけ」に留める。
# このスクリプト自体はファイルを一切書き換えない。
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

# 対象拡張子でなければ何もしない
case "$FILE_PATH" in
  *.ts | *.tsx | *.js | *.jsx) ;;
  *) exit 0 ;;
esac

# session_id が無いとキューをセッション分離できない → 記録せず終了
[ -z "$SESSION_ID" ] && exit 0

. "$(dirname "$0")/format-queue-common.sh" 2>/dev/null
[ -n "$FORMAT_QUEUE_DIR" ] || exit 0   # 共通定義が読めなければ何もしない (壊すより no-op)
QUEUE_DIR="$FORMAT_QUEUE_DIR"
mkdir -p "$QUEUE_DIR" 2>/dev/null || exit 0
printf '%s\n' "$FILE_PATH" >> "$QUEUE_DIR/$SESSION_ID.txt"
exit 0
