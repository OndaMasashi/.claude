#!/bin/bash
# Skill usage logging (PostToolUse, Skill matcher)
# Extracts skill name from tool_input JSON and appends a line to usage.log
# via the existing usage_logger.py.
#
# Why a hook: relying on Claude to call usage_logger.py manually causes drift
# (entries went missing for 10+ days when manual rule was the only mechanism).
# PostToolUse fires unconditionally on Skill invocation, so coverage is complete.

SKILL_NAME=$(jq -r '.tool_input.skill // empty')
if [ -n "$SKILL_NAME" ]; then
  python C:/work/utility/skills-main/skills-main/skills/usage_logger.py "$SKILL_NAME" >/dev/null 2>&1
fi
exit 0
