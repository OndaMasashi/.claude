#!/bin/bash
# PostToolUse hook for Bash: git commit 検出時に /simplify リマインド
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')

if printf '%s' "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  echo "[Auto-Trigger] コミット完了。変更ファイルに対して /simplify を実行してコード品質を確認してください。"
fi

exit 0
