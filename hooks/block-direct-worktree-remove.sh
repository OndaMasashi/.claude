#!/bin/bash
# Block direct `git worktree remove` invocations to enforce the
# safe-worktree-remove.sh wrapper. Without the wrapper, NTFS junctions
# inside the worktree (backend/.venv, frontend/node_modules) get followed
# during deletion and the main targets get silently emptied.
# See ~/.claude/projects/c--work-FX-auto-trader/memory/tech_gotcha_backend_venv_corruption.md
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -qE '\bgit[[:space:]]+worktree[[:space:]]+remove\b'; then
  # Allow if invoked through the wrapper script
  if echo "$COMMAND" | grep -qE 'safe-worktree-remove\.sh'; then
    exit 0
  fi

  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Direct \"git worktree remove\" is blocked. NTFS junctions inside worktrees (backend/.venv, frontend/node_modules) get followed during deletion and silently EMPTY the main targets. Use the wrapper instead:\n  bash ~/.claude/scripts/safe-worktree-remove.sh <worktree-path> [--force]\nBackground: ~/.claude/projects/c--work-FX-auto-trader/memory/tech_gotcha_backend_venv_corruption.md"
    }
  }'
  exit 0
fi

exit 0
