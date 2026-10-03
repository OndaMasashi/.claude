---
last_updated: 2026-10-03
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
| Next.js | 16.3.8 |
| React | 19.3.0 |
| Vue | 3.5.43 |
| Nuxt | 4.5.2 |
| SvelteKit | 3.0.0 |
| Vite | 8.3.2 |

## Styling

| 技術 | 最新版 |
|---|---|
| Tailwind CSS | 4.3.3 |

## Language / Runtime

| 技術 | 最新版 |
|---|---|
| TypeScript | 7.0.2 |
| Node.js (Current) | 26.10.0 |
| Node.js (LTS) | 24.21.0 |
| Python (Stable) | 3.13.16 |
| Python (Latest) | 3.14.8 |
| Bun | 1.4.2 |
| pnpm | 12.8.1 |

## Backend / API

| 技術 | 最新版 |
|---|---|
| FastAPI | 0.142.2 |
| Hono | 4.13.12 |

## AI SDK

| 技術 | 最新版 |
|---|---|
| @anthropic-ai/sdk | 0.131.0 |
| @anthropic-ai/claude-agent-sdk | 0.3.288 |
| anthropic (Python) | 1.11.0 |
| openai | 7.27.0 |

## Anthropic Models

| 技術 | 最新版 |
|---|---|
| Claude Fable | 5.1 |
| Claude Opus | 5.5 |
| Claude Sonnet | 5.5 |
| Claude Haiku | 4.5 |
