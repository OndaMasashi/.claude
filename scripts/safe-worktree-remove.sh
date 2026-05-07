#!/bin/bash
# safe-worktree-remove.sh — Safely remove a git worktree by first unlinking
# any NTFS junctions inside it (backend/.venv, frontend/node_modules) to
# prevent the junction-follow delete trap (see
# ~/.claude/projects/c--work-FX-auto-trader/memory/tech_gotcha_backend_venv_corruption.md)
#
# Usage:
#   bash ~/.claude/scripts/safe-worktree-remove.sh <worktree-path> [git worktree remove flags...]
#
# Example:
#   bash ~/.claude/scripts/safe-worktree-remove.sh /c/work/FX-auto-trader-s5-99 --force
#   bash ~/.claude/scripts/safe-worktree-remove.sh c:/work/FX-auto-trader-s5-42

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <worktree-path> [git worktree remove flags...]" >&2
  exit 1
fi

WT="$1"
shift

if [ ! -e "$WT" ]; then
  echo "Error: worktree path does not exist: $WT" >&2
  exit 1
fi

# Normalize to forward-slash form (PowerShell accepts both, but we use forward
# slash consistently to avoid bash-escape headaches when passing to cmd/powershell).
case "$WT" in
  /[a-zA-Z]/*)
    drive=$(echo "$WT" | cut -c2)
    rest=$(echo "$WT" | cut -c4-)
    PS_WT="${drive}:/${rest}"
    ;;
  [a-zA-Z]:[/\\]*)
    PS_WT="${WT//\\/\/}"
    ;;
  *)
    echo "Error: unsupported path form: $WT (expected /c/... or c:/...)" >&2
    exit 1
    ;;
esac

# Known junction locations to unlink BEFORE git worktree remove. Add new
# patterns here if more shared resources are linked into worktrees.
JUNCTIONS=(
  "backend/.venv"
  "frontend/node_modules"
)

for sub in "${JUNCTIONS[@]}"; do
  full="${PS_WT}/${sub}"

  # Detect: returns "Junction" if junction, empty if regular dir or absent.
  link_type=$(powershell -NoProfile -Command "(Get-Item -Path '$full' -Force -ErrorAction SilentlyContinue).LinkType" 2>/dev/null | tr -d '[:space:]\r')

  if [ "$link_type" = "Junction" ]; then
    echo "[safe-worktree-remove] Unlinking junction: $full"
    # [System.IO.Directory]::Delete($path, $false) deletes only the directory
    # entry (the junction). The second arg is recursive=$false, so the target
    # contents are NOT followed/deleted. This is the safe equivalent of
    # `cmd /c rmdir <junction>` (without /s).
    if ! powershell -NoProfile -Command "[System.IO.Directory]::Delete('$full', \$false)" 2>&1; then
      echo "[safe-worktree-remove] Failed to unlink junction $full" >&2
      exit 1
    fi
    # Sanity: verify it's gone
    still_exists=$(powershell -NoProfile -Command "Test-Path '$full'" 2>/dev/null | tr -d '[:space:]\r')
    if [ "$still_exists" = "True" ]; then
      echo "[safe-worktree-remove] Junction still exists after unlink: $full" >&2
      exit 1
    fi
  fi
done

echo "[safe-worktree-remove] Running: git worktree remove $* \"$WT\""
git worktree remove "$@" "$WT"
echo "[safe-worktree-remove] Done."
