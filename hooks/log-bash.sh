#!/bin/bash
# Bash command log with secret redaction (PreToolUse, S13-3)
# Redacts UNIVERSAL secret patterns before writing to ~/.claude/bash-command-log.txt
# Project-specific legacy secrets are intentionally NOT embedded here as literals
# to avoid their text propagating via the hook script itself.
# Hash-based redaction for project-specific legacy secrets is layered separately
# (see LEGACY_SECRET_HASHES env var, applied if set).
#
# Redaction patterns:
#   - sk-ant-api03-* (Anthropic API key, public prefix)
#   - FX_*_(SECRET|KEY|PASSWORD)=* (backend env var assignment, FX-prefix is public, value redacted)
#   - [A-Z2-7]{32} (TOTP Base32 secret shape, word-boundary; SHA1 hex collision possible)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMAND=$(jq -r '.tool_input.command' | sed -E \
  -e 's/sk-ant-api03-[A-Za-z0-9_-]+/[REDACTED_ANTHROPIC]/g' \
  -e 's/(FX_[A-Z_]*(SECRET|KEY|PASSWORD))=[^ "$]+/\1=[REDACTED]/g' \
  -e 's/(^|[^A-Z2-7])([A-Z2-7]{32})($|[^A-Z2-7])/\1[REDACTED_BASE32]\3/g')

# Hash-based redaction for legacy project-specific secrets (S13-3, no literal embedded)
# LEGACY_SECRET_HASHES env var: space-separated SHA256 hex (64 char) values
if [ -n "$LEGACY_SECRET_HASHES" ]; then
  REDACTED=$(printf '%s' "$COMMAND" | grep -oE '[A-Za-z0-9#@!_-]{6,40}' | sort -u | while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    h=$(printf '%s' "$tok" | sha256sum 2>/dev/null | awk '{print $1}')
    for target in $LEGACY_SECRET_HASHES; do
      if [ "$h" = "$target" ]; then
        echo "$tok"
        break
      fi
    done
  done)
  if [ -n "$REDACTED" ]; then
    while IFS= read -r tok; do
      [ -z "$tok" ] && continue
      # sed escape special chars in token
      esc=$(printf '%s' "$tok" | sed 's/[][\/.*^$#&]/\\&/g')
      COMMAND=$(printf '%s' "$COMMAND" | sed "s|$esc|[REDACTED_LEGACY]|g")
    done <<< "$REDACTED"
  fi
fi

DESC=$(jq -r '.tool_input.description // "No description"')
echo "${TIMESTAMP} | ${COMMAND} | ${DESC}" >> ~/.claude/bash-command-log.txt
exit 0
