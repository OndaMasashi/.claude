---
last_updated: 2026-10-25
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
| Next.js | 16.4.3 |
| React | 19.3.1 |
| Vue | 3.5.44 |
| Nuxt | 4.6.2 |
| SvelteKit | 3.1.0 |
| Vite | 8.3.5 |

## Styling

| 技術 | 最新版 |
|---|---|
| Tailwind CSS | 4.3.3 |

## Language / Runtime

| 技術 | 最新版 |
|---|---|
| TypeScript | 7.0.2 |
| Node.js (Current) | 26.12.1 |
| Node.js (LTS) | 24.22.1 |
| Python (Stable) | 3.13.17 |
| Python (Latest) | 3.14.9 |
| Bun | 1.4.4 |
| pnpm | 12.15.0 |

## Backend / API

| 技術 | 最新版 |
|---|---|
| FastAPI | 0.162.0 |
| Hono | 4.13.13 |

## AI SDK

| 技術 | 最新版 |
|---|---|
| @anthropic-ai/sdk | 1.3.0 |
| @anthropic-ai/claude-agent-sdk | 0.3.310 |
| anthropic (Python) | 2.3.0 |
| openai | 7.43.0 |

## Anthropic Models

| 技術 | 最新版 |
|---|---|
| Claude Fable | 5.1 |
| Claude Opus | 5.5 |
| Claude Sonnet | 5.5 |
| Claude Haiku | 4.5 |
