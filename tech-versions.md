---
last_updated: 2026-07-19
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
| Next.js | 16.2.10 |
| React | 19.2.7 |
| Vue | 3.5.40 |
| Nuxt | 4.4.8 |
| SvelteKit | 2.70.0 |
| Vite | 8.1.5 |

## Styling

| 技術 | 最新版 |
|---|---|
| Tailwind CSS | 4.3.3 |

## Language / Runtime

| 技術 | 最新版 |
|---|---|
| TypeScript | 7.0.2 |
| Node.js (Current) | 26.5.0 |
| Node.js (LTS) | 24.18.0 |
| Python (Stable) | 3.13.14 |
| Python (Latest) | 3.14.6 |
| Bun | 1.3.14 |
| pnpm | 11.14.0 |

## Backend / API

| 技術 | 最新版 |
|---|---|
| FastAPI | 0.139.2 |
| Hono | 4.12.30 |

## AI SDK

| 技術 | 最新版 |
|---|---|
| @anthropic-ai/sdk | 0.112.3 |
| @anthropic-ai/claude-agent-sdk | 0.3.214 |
| anthropic (Python) | 0.117.0 |
| openai | 6.48.0 |

## Anthropic Models

| 技術 | 最新版 |
|---|---|
| Claude Opus | 4.8 |
| Claude Sonnet | 4.6 |
| Claude Haiku | 4.5 |
