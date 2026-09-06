---
last_updated: 2026-09-06
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
| Next.js | 16.3.4 |
| React | 19.2.8 |
| Vue | 3.5.42 |
| Nuxt | 4.5.2 |
| SvelteKit | 2.70.3 |
| Vite | 8.2.2 |

## Styling

| 技術 | 最新版 |
|---|---|
| Tailwind CSS | 4.3.3 |

## Language / Runtime

| 技術 | 最新版 |
|---|---|
| TypeScript | 7.0.2 |
| Node.js (Current) | 26.8.1 |
| Node.js (LTS) | 24.20.0 |
| Python (Stable) | 3.13.15 |
| Python (Latest) | 3.14.7 |
| Bun | 1.4.2 |
| pnpm | 12.3.4 |

## Backend / API

| 技術 | 最新版 |
|---|---|
| FastAPI | 0.141.1 |
| Hono | 4.13.7 |

## AI SDK

| 技術 | 最新版 |
|---|---|
| @anthropic-ai/sdk | 0.124.0 |
| @anthropic-ai/claude-agent-sdk | 0.3.263 |
| anthropic (Python) | 1.4.0 |
| openai | 7.10.0 |

## Anthropic Models

| 技術 | 最新版 |
|---|---|
| Claude Fable | 5.1 |
| Claude Opus | 5 |
| Claude Sonnet | 5 |
| Claude Haiku | 4.5 |
