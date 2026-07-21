#!/bin/bash
# PostToolUse hook for Bash: git commit 検出時に /refine + improvement_list 記録を誘導する。
#
# 出力方式の理由 (2026-07-22 変更):
#   旧実装のプレーン echo (exit0) は PostToolUse ではモデルのコンテキストに届かない
#   （公式仕様では debug ログ止まり。exit0 stdout がコンテキストへ入るのは
#    UserPromptSubmit / UserPromptExpansion / SessionStart のみ）。
#   PostToolUse で確実に届く正規ルートは hookSpecificOutput.additionalContext (exit0+JSON)。
#   参照: https://code.claude.com/docs/en/hooks
#
# CRLF 対策: Windows の jq.exe は stdout を CRLF で出すため tr -d '\r' で LF に正規化する
# （\r 混入は Claude Code 側の JSON パースを壊しうる）。
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')

if printf '%s' "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  MSG="コミットが完了しました。変更したコードについて、完了報告の前に (1) /refine（品質改善→正確性バグ検出）を実行し、(2) プロジェクトの improvement_list/ に改修履歴（対象ファイル・変更内容・理由）を1プラン=1ファイルで記録してください。軽微な変更（誤字・整形のみ）の場合は対象外です。"
  jq -nc --arg ctx "$MSG" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}' | tr -d '\r'
fi

exit 0
