#!/bin/bash
# safe-worktree-remove.sh — Safely remove a git worktree by first unlinking
# every NTFS junction / directory symlink inside it, to prevent the
# junction-follow delete trap (git deletes through a leftover link into the
# shared folder it points at; see
# ~/.claude/projects/c--work-FX-auto-trader/memory/tech_gotcha_backend_venv_corruption.md)
#
# The whole tree is searched, not a fixed list of paths: a fixed list
# (backend/.venv, frontend/node_modules) missed apps-script/node_modules in
# AGS_PJ_MANAGEMENT on 2026-10-14 and deleted part of the main checkout's
# node_modules.
#
# Usage:
#   bash ~/.claude/scripts/safe-worktree-remove.sh <worktree-path> [git worktree remove flags...]
#
# Example:
#   bash ~/.claude/scripts/safe-worktree-remove.sh /c/work/FX-auto-trader-s5-99 --force
#   bash ~/.claude/scripts/safe-worktree-remove.sh c:/work/FX-auto-trader-s5-42

set -euo pipefail

fail() {
  echo "[safe-worktree-remove] $*" >&2
  echo "[safe-worktree-remove] Stopped: no link was unlinked and git worktree remove was not run." >&2
  exit 1
}

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

# Ask git first whether it will accept the removal, and stop before touching
# any link when it would not. Unlinking and then having git refuse leaves a
# worktree that is still registered but has lost its node_modules / .venv
# links; a mistyped path such as ~/.claude would lose every junction inside it.
force=0
for arg in "$@"; do
  case "$arg" in -f|--force) force=$((force + 1)) ;; esac
done

prefix=$(git -C "$PS_WT" rev-parse --show-prefix 2>/dev/null) ||
  fail "not inside a git worktree (if it is a broken leftover, run git worktree prune): $PS_WT"
[ -z "$prefix" ] || fail "not the top of a worktree (it is the folder '$prefix' inside one): $PS_WT"
top=$(git -C "$PS_WT" rev-parse --show-toplevel)

# `worktree list --porcelain` lists the main worktree first. Paths are
# compared without case: git may spell the drive letter differently in the two
# outputs, and NTFS paths are case-insensitive.
list=$(git -C "$PS_WT" worktree list --porcelain) || fail "git worktree list failed for: $PS_WT"
main="" entry="" registered=0 locked=0
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      entry="${line#worktree }"
      if [ -z "$main" ]; then main="$entry"; fi
      if [ "${entry,,}" = "${top,,}" ]; then registered=1; fi
      ;;
    locked | "locked "*)
      if [ "${entry,,}" = "${top,,}" ]; then locked=1; fi
      ;;
  esac
done <<< "$list"

[ "${top,,}" != "${main,,}" ] || fail "this is the main worktree, not a linked one: $top"
[ "$registered" -eq 1 ] || fail "not a registered worktree of its repository: $top"
if [ "$locked" -eq 1 ] && [ "$force" -lt 2 ]; then
  fail "the worktree is locked (in use?). Run git worktree unlock first, or pass --force twice: $top"
fi
# Same test git uses: tracked changes or untracked files (ignored files do not count)
if [ "$force" -eq 0 ] && [ -n "$(git -C "$top" status --porcelain --ignore-submodules=none)" ]; then
  fail "the worktree has modified or untracked files. Keep them elsewhere, or pass --force: $top"
fi

# Walks the worktree without entering any reparse point, so a link is listed
# but its target is never read. Each link is removed with
# [System.IO.Directory]::Delete($path, $false): recursive = $false deletes only
# the link entry, never the target contents (the safe equivalent of
# `cmd /c rmdir <junction>` without /s). The script stops before git runs when
# the worktree path is itself a link, a reparse point is neither a junction nor
# a symlink, a directory cannot be read, or a link is still present afterwards.
# The \\?\ prefix lets the walk reach paths beyond the .NET Framework MAX_PATH
# limit (deep real node_modules).
UNLINK_PS=$(cat <<'PS'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$reparse = [IO.FileAttributes]::ReparsePoint
$longPathPrefix = '\\?\'

function Get-LinkDirs([string]$root) {
  $found = New-Object System.Collections.Generic.List[string]
  $stack = New-Object System.Collections.Generic.Stack[IO.DirectoryInfo]
  $stack.Push((New-Object IO.DirectoryInfo ($longPathPrefix + $root)))
  while ($stack.Count -gt 0) {
    foreach ($d in $stack.Pop().EnumerateDirectories()) {
      if (($d.Attributes -band $reparse) -ne 0) { $found.Add($d.FullName) } else { $stack.Push($d) }
    }
  }
  return ,$found
}

try {
  $root = [IO.Path]::GetFullPath($env:SWR_ROOT).TrimEnd('\')
  if (((Get-Item -LiteralPath $root -Force).Attributes -band $reparse) -ne 0) {
    throw "the worktree path itself is a link: $root"
  }
  foreach ($p in (Get-LinkDirs $root)) {
    $plain = $p.Substring($longPathPrefix.Length)
    $type = (Get-Item -LiteralPath $p -Force).LinkType
    if ($type -ne 'Junction' -and $type -ne 'SymbolicLink') {
      throw "not a junction or symlink (reparse type '$type'), left as is: $plain"
    }
    Write-Output "[safe-worktree-remove] Unlinking $($type.ToLower()): $plain"
    [IO.Directory]::Delete($p, $false)
  }
  $left = Get-LinkDirs $root
  if ($left.Count -gt 0) {
    $plainLeft = $left | ForEach-Object { $_.Substring($longPathPrefix.Length) }
    throw ("links still present after unlink: " + ($plainLeft -join ', '))
  }
} catch {
  [Console]::Error.WriteLine("[safe-worktree-remove] $($_.Exception.Message)")
  exit 1
}
PS
)

encoded=$(printf '%s' "$UNLINK_PS" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)
# The walk starts from the path as given (not git's $top), so a link passed in
# place of the worktree is still refused instead of being resolved by git
if ! SWR_ROOT="$PS_WT" powershell -NoProfile -NonInteractive -EncodedCommand "$encoded"; then
  echo "[safe-worktree-remove] Stopped: git worktree remove was not run." >&2
  exit 1
fi

# Run git from the main worktree: the caller's current folder may belong to
# another repository (git then refuses after the links are already gone).
echo "[safe-worktree-remove] Running: git -C \"$main\" worktree remove $* \"$top\""
git -C "$main" worktree remove "$@" "$top"
echo "[safe-worktree-remove] Done."
