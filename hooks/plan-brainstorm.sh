#!/bin/bash
# PreToolUse hook for EnterPlanMode: ブレスト・フェーズのリマインド
cat > /dev/null
echo "[Auto-Trigger] CLAUDE.md のブレスト・フェーズ（目的確認→アプローチ比較→段階的質問→YAGNI）に従ってください。単純作業・ユーザー指示があればスキップ可。"
exit 0
