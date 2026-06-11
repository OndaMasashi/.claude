#!/bin/bash
# PreToolUse hook for EnterPlanMode: ブレスト・フェーズのリマインド
cat > /dev/null
echo "[Auto-Trigger] CLAUDE.md のブレスト・フェーズ（目的確認→アプローチ比較→段階的質問→YAGNI）に従ってください。単純作業・ユーザー指示があればスキップ可。"
echo "[Auto-Trigger] 並列化・自動化手段を検討する規模の計画なら ~/.claude/orchestration-guide.md を Read（サブエージェント/Agent Teams/動的ワークフロー(ultracode)/ワークツリー/batch/Agent SDK/CCR の適用条件・選択軸）。新規プロダクト起案・未経験領域なら CLAUDE.md「最上流の3点」「定石調査」も適用。"
exit 0
