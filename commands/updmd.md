---
allowed-tools: Bash(git log:*), Bash(git status:*), Bash(git diff:*), Bash(ls:*), Bash(find:*), Bash(wc:*), Read, Edit, Write, Glob, Grep
description: プロジェクト内の各種 MD ファイル（CLAUDE.md / README.md / INDEX.md / ROADMAP.md / memory/）を現状に合わせて更新する
---

## Context

- Current branch: !`git branch --show-current 2>/dev/null || echo "(not a git repo)"`
- Recent commits: !`git log --oneline -10 2>/dev/null`
- Git status (short): !`git status --short 2>/dev/null | head -30`
- Project root files: !`ls -1 2>/dev/null | head -30`

## Your task

カレントプロジェクトの以下の MD ファイルを、現在のリポジトリ状態に合わせて更新してください。

### 更新対象

1. **CLAUDE.md**（プロジェクトルート）— 構造・運用手順・規約の最新化
2. **README.md**（プロジェクトルート）— 概要・セットアップ・使い方の最新化
3. **INDEX.md**（`docs/` `docs_ja/` 等の配下に存在する場合）— ファイル一覧・ページ数・取得日の最新化
4. **ROADMAP.md / ROADMAP.*.md / roadmap.md** およびそれに準ずるファイル（`PLAN.md`, `MILESTONES.md`, `TODO.md`, `plan.md`, `docs/roadmap/*.md` 等）— マイルストーン達成状況・次ステップ・優先度の最新化
5. **memory/** 配下（`~/.claude/projects/{project-slug}/memory/` の MEMORY.md + `*.md`）— 今セッションで判明した知見・参照先の追加

### 手順

1. **現状把握**
   - 各対象ファイルを Read
   - `docs_ja/` `claude_resources/` 等のディレクトリ数・ファイル数を Bash `ls ... | wc -l` で実測
   - `git log` で直近の変更を把握し、ドキュメントに反映されていない変更を特定

2. **差分の特定**
   - CLAUDE.md の Structure セクションに書かれたディレクトリ一覧と実態のズレ
   - ページ数・取得日・バージョン等の数字のズレ
   - README.md の概要・セットアップ手順の古さ
   - INDEX.md のページ数・更新日・新規ページ
   - ROADMAP / PLAN / MILESTONES のマイルストーン達成状況・未消化タスク・優先順位変更（直近コミットや完了済み PR から逆算して `[ ]` → `[x]` 更新、不要になった項目の削除）
   - memory/MEMORY.md の更新履歴表に追記すべき新しい作業、または新しく判明した "非自明な知見"（コードを読めば分かることは保存しない）

3. **更新の実行**
   - 各ファイルを Edit で **最小差分** で更新（全面書き換えは禁止）
   - 設計思想・運用ルール・ユーザーのポリシー記述は勝手に書き換えない
   - 新規 memory ファイルを作る場合は frontmatter（name / description / type）必須で、MEMORY.md 側にも 1 行のインデックスエントリを追加する
   - README.md が存在しない場合は作成しない（ユーザーに確認）

4. **スキップ判断**
   - 対象ファイルが存在しない → その旨を報告
   - 実体が既に最新 → 「変更なし」と明示し触らない
   - 変更内容が "コードを読めば分かる" 範疇の memory → 保存しない

5. **完了報告**
   - 表形式で各対象ファイルの状態（✅ 更新 / ⏭️ 変更なし / ⏭️ 対象外）と変更点の要約を 1-2 行で
   - スキップしたものは理由を明記
   - 追加で判断が必要な項目（例: README.md 新規作成の是非）はユーザーに質問
