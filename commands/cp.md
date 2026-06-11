---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*), Bash(gh pr list:*)
description: ブランチ作成 + コミット + push + PR 作成
---

## Context
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`

## Your task
上記の変更内容に基づいて、ブランチ作成・コミット・push・PR 作成を実行してください。

### 手順
1. 現在 main または master ブランチにいる場合、変更内容に基づいた名前で新しいブランチを作成する
   - ブランチ名の例: `fix/login-validation`, `feature/add-export`, `docs/update-readme`
2. 変更されたファイルをステージングする（.env, credentials 等の秘密情報ファイルは除外）
3. 変更内容を分析し、**日本語で**簡潔なコミットメッセージを作成する
   - 末尾に `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` を付与
4. コミットを作成する
5. ブランチをリモートに push する（`git push -u origin ブランチ名`）
6. `gh pr create` で PR を作成する
   - **`gh pr view` での既存 PR 判定はしないこと**: `gh pr view <ブランチ>` はマージ済み/closed の PR も返すため、新規作成すべき場面で「既存 PR あり」と誤検出する。`gh pr create` を直接実行する
   - `gh pr create` が "already exists" で失敗するのは **open PR が既にある場合のみ**（マージ済み PR とは衝突しない）。失敗した場合は push 済みコミットがその open PR に反映されているので、`gh pr list --state open --head <ブランチ名>` で URL を確認して報告する
   - タイトル: 日本語で簡潔に
   - 本文: 以下の形式で日本語で記述

```
## 概要
- （変更内容を1-3行で）

## テスト計画
- [ ] （確認すべき項目）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 注意事項
- コミットメッセージ・PR タイトル・PR 本文は必ず日本語で書くこと
- HEREDOC 形式でコミットメッセージと PR 本文を渡すこと
- 全ての操作を1回のレスポンスで完了すること。余計なテキストやメッセージは出力しないこと
