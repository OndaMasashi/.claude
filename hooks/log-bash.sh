#!/bin/bash
# Bash コマンドのログ記録 (PreToolUse)
# すべての Bash 実行をファイルに記録する
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMAND=$(jq -r '.tool_input.command')
DESC=$(jq -r '.tool_input.description // "No description"')
echo "${TIMESTAMP} | ${COMMAND} | ${DESC}" >> ~/.claude/bash-command-log.txt
exit 0
