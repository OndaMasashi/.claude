#!/bin/bash
# Block git commit/push if sensitive files (.env, config.yaml) are included

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

SENSITIVE_PATTERN='(^|/)(\.(env|env\.[^.]+)|config\.yaml)$'
EXCLUDE_PATTERN='\.(example|sample|template)$'

# Check git commit: inspect staged files
if echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  BLOCKED=$(git diff --cached --name-only 2>/dev/null | grep -E "$SENSITIVE_PATTERN" | grep -vE "$EXCLUDE_PATTERN")
  if [ -n "$BLOCKED" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"Sensitive files detected in staging area:\\n${BLOCKED}\\n\\nRemove with: git reset HEAD <file>\"}"
  fi
  exit 0
fi

# Check git push: inspect unpushed commits
if echo "$COMMAND" | grep -qE '^\s*git\s+push'; then
  # Detect default remote branch
  REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -z "$REMOTE_BRANCH" ]; then
    # No upstream set, skip check
    exit 0
  fi
  BLOCKED=$(git diff --name-only "${REMOTE_BRANCH}...HEAD" 2>/dev/null | grep -E "$SENSITIVE_PATTERN" | grep -vE "$EXCLUDE_PATTERN")
  if [ -n "$BLOCKED" ]; then
    echo "{\"decision\":\"block\",\"reason\":\"Sensitive files found in unpushed commits:\\n${BLOCKED}\\n\\nRemove from history with: git filter-repo --path <file> --invert-paths\"}"
  fi
  exit 0
fi
