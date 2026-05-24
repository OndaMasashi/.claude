#!/bin/bash
# Block secrets in WRITE surfaces (S13-1 / S13-3):
#   1. git commit/push with .env/config.yaml files (file path scan, original)
#   2. git commit with staged content containing secret patterns (S13-1 content scan)
#   3. Bash tool with literal secret patterns in command (S13-3 secret scan)
#
# Hook script intentionally contains NO project-specific secret literals.
# Project-specific legacy secrets are matched via LEGACY_SECRET_HASHES env var
# (space-separated SHA256 hex values; user populates after rotation).
#
# READ tool intentionally NOT blocked — Claude must be able to inspect
# .env.example, ~/.claude/config.json etc. for debugging. Secrets are stopped
# at the write layer (this hook) and at log-write layer (log-bash.sh).

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

SENSITIVE_PATTERN='(^|/)(\.(env|env\.[^.]+)|config\.yaml)$'
EXCLUDE_PATTERN='\.(example|sample|template)$'

# Universal secret patterns (public prefixes, no leak risk to embed here)
UNIVERSAL_SECRET='(sk-ant-api03-[A-Za-z0-9_-]{20,}|FX_[A-Z_]*(SECRET|KEY|PASSWORD)\s*=\s*[^ "$]+)'

# Hash-based legacy secret detection (no plaintext embedded)
# LEGACY_SECRET_HASHES env var: space-separated SHA256 hex (64 char) values.
# Tokens of length 6-40 with password-like character class are extracted from content,
# hashed, and compared against the env-provided allowlist.
hash_match_found() {
  local content="$1"
  [ -z "$LEGACY_SECRET_HASHES" ] && return 1
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    h=$(printf '%s' "$tok" | sha256sum 2>/dev/null | awk '{print $1}')
    for target in $LEGACY_SECRET_HASHES; do
      if [ "$h" = "$target" ]; then
        return 0
      fi
    done
  done < <(printf '%s' "$content" | grep -oE '[A-Za-z0-9#@!_-]{6,40}' | sort -u)
  return 1
}

# ----- Bash tool: scan command for literal secret patterns (S13-3) -----
if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  if echo "$COMMAND" | grep -qE "$UNIVERSAL_SECRET"; then
    echo "{\"decision\":\"block\",\"reason\":\"S13-3: Bash command contains literal secret pattern (Anthropic key or FX env-var assignment). Use env-var indirection or .env file reference instead.\"}"
    exit 0
  fi
  if hash_match_found "$COMMAND"; then
    echo "{\"decision\":\"block\",\"reason\":\"S13-3: Bash command contains a legacy secret (SHA256 hash match against LEGACY_SECRET_HASHES). Rotate the secret first and use a placeholder.\"}"
    exit 0
  fi
fi

# ----- git commit: inspect staged files + content (S13-1) -----
if echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  BLOCKED_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E "$SENSITIVE_PATTERN" | grep -vE "$EXCLUDE_PATTERN")
  if [ -n "$BLOCKED_FILES" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"Sensitive files in staging:\\n${BLOCKED_FILES}\\n\\nRemove with: git reset HEAD <file>\"}"
    exit 0
  fi
  # S13-1: scan staged diff for universal secret patterns
  STAGED_DIFF=$(git diff --cached 2>/dev/null)
  BLOCKED_CONTENT=$(printf '%s' "$STAGED_DIFF" | grep -E "^\+.*${UNIVERSAL_SECRET}" | head -3)
  if [ -n "$BLOCKED_CONTENT" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"S13-1: Plaintext secret detected in staged content:\\n${BLOCKED_CONTENT}\\n\\nUse .env.production placeholder instead.\"}"
    exit 0
  fi
  # S13-1: hash-based legacy secret match in staged content
  if hash_match_found "$STAGED_DIFF"; then
    echo "{\"decision\":\"block\",\"reason\":\"S13-1: Legacy secret detected in staged content (SHA256 hash match). Replace with placeholder.\"}"
    exit 0
  fi
  exit 0
fi

# ----- git push: inspect unpushed commits -----
if echo "$COMMAND" | grep -qE '^\s*git\s+push'; then
  REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -z "$REMOTE_BRANCH" ]; then
    exit 0
  fi
  BLOCKED=$(git diff --name-only "${REMOTE_BRANCH}...HEAD" 2>/dev/null | grep -E "$SENSITIVE_PATTERN" | grep -vE "$EXCLUDE_PATTERN")
  if [ -n "$BLOCKED" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"Sensitive files found in unpushed commits:\\n${BLOCKED}\\n\\nRemove from history with: git filter-repo --path <file> --invert-paths\"}"
  fi
  exit 0
fi
