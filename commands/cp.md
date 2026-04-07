---
allowed-tools: Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*)
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
   - 末尾に `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>` を付与
4. コミットを作成する
5. ブランチをリモートに push する（`git push -u origin ブランチ名`）
6. `gh pr create` で PR を作成する
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
