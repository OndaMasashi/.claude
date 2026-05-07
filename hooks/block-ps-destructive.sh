#!/bin/bash
# 危険な PowerShell コマンド（再帰削除・フォーマット等）をブロックする PreToolUse フック
COMMAND=$(jq -r '.tool_input.command')

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# 1. Remove-Item -Recurse （同一コマンド内、順序問わず／; や | で区切られた別コマンドは対象外）
if echo "$COMMAND" | grep -qiE 'Remove-Item[^|;]*-Recurse|-Recurse[^|;]*Remove-Item'; then
  deny "Remove-Item -Recurse is blocked by PowerShell guard hook (~/.claude/hooks/block-ps-destructive.sh)"
fi

# 2. PowerShell の Remove-Item alias (rm/ri/rmdir/rd/del/erase) + -r/-Recurse
if echo "$COMMAND" | grep -qiE '\b(rm|ri|rmdir|rd|del|erase)\b[[:space:]]+[^|;]*-r(ecurse)?\b'; then
  deny "Recursive delete via PowerShell alias is blocked by PowerShell guard hook"
fi

# 3. cmd スタイルの再帰削除 (rd /s, rmdir /s, del /s)
if echo "$COMMAND" | grep -qiE '\b(rd|rmdir|del)\b[[:space:]]+[^|;]*/s\b'; then
  deny "cmd-style recursive delete (/s) is blocked by PowerShell guard hook"
fi

# 4. パイプライン経由の削除 (Get-ChildItem -Recurse | Remove-Item -Force 等)
if echo "$COMMAND" | grep -qiE '\|[[:space:]]*(Remove-Item|rm|ri|rmdir|rd|del|erase)\b'; then
  deny "Pipeline to Remove-Item/alias is blocked by PowerShell guard hook"
fi

# 5. Format-Volume / Format-Disk
if echo "$COMMAND" | grep -qiE 'Format-(Volume|Disk)\b'; then
  deny "Format-Volume/Disk is blocked by PowerShell guard hook"
fi

# 6. Clear-Disk
if echo "$COMMAND" | grep -qiE 'Clear-Disk\b'; then
  deny "Clear-Disk is blocked by PowerShell guard hook"
fi

# 7. Stop-Computer / Restart-Computer
if echo "$COMMAND" | grep -qiE '(Stop|Restart)-Computer\b'; then
  deny "Stop/Restart-Computer is blocked by PowerShell guard hook"
fi

# 8. Set-ExecutionPolicy の弱化 (Unrestricted/Bypass)
if echo "$COMMAND" | grep -qiE 'Set-ExecutionPolicy[[:space:]]+[^|;]*(Unrestricted|Bypass)\b'; then
  deny "Set-ExecutionPolicy weakening is blocked by PowerShell guard hook"
fi

exit 0
