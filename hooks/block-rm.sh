#!/bin/bash
# 危険コマンド（rm -rf）をブロックする PreToolUse フック
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "rm -rf is blocked by hook"
    }
  }'
else
  exit 0
fi
