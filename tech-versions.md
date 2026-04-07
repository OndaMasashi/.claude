---
last_updated: 2026-04-07
update_schedule: 毎週日曜 00:00 (Windows タスクスケジューラによる自動更新)
update_script: ~/.claude/scripts/update-tech-versions.sh
sources: ~/.claude/tech-versions-sources.tsv
---

# 技術バージョン最新版リスト

> このファイルはモデル訓練時の知識を上書きする「最新版の真実」です。
> FW・ライブラリ・ランタイムのバージョンに言及／コード生成する際は必ず参照してください。
>
> **新規技術の追加**: `~/.claude/tech-versions-sources.tsv` に1行追加してスクリプト再実行。

## Frontend Framework

| 技術 | 最新版 |
|---|---|
| Next.js | 16.2.2 |
| React | 19.2.4 |
| Vue | 3.5.32 |
| Nuxt | 4.4.2 |
| SvelteKit | 2.56.1 |
| Vite | 8.0.6 |

## Styling

| 技術 | 最新版 |
|---|---|
| Tailwind CSS | 4.2.2 |

## Language / Runtime

| 技術 | 最新版 |
|---|---|
| TypeScript | 6.0.2 |
| Node.js (Current) | 25.9.0 |
| Node.js (LTS) | 24.14.1 |
| Python (Stable) | 3.13.12 |
| Python (Latest) | 3.14.3 |
| Bun | 1.3.11 |
| pnpm | 10.33.0 |

## Backend / API

| 技術 | 最新版 |
|---|---|
| FastAPI | 0.135.3 |
| Hono | 4.12.12 |

## AI SDK

| 技術 | 最新版 |
|---|---|
| @anthropic-ai/sdk | 0.82.0 |
| @anthropic-ai/claude-agent-sdk | 0.2.92 |
| anthropic (Python) | 0.89.0 |
| openai | 6.33.0 |
