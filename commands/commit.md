---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*)
description: コミットして push する
---

## Context
- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task
上記の変更内容に基づいて、コミットと push を実行してください。

### 手順
1. 変更されたファイルをステージングする（.env, credentials 等の秘密情報ファイルは除外）
2. 変更内容を分析し、**日本語で**簡潔なコミットメッセージを作成する
   - 1行目: 変更の要約（例: 「ログイン画面のバリデーションを修正」）
   - 必要に応じて空行の後に詳細を記述
   - 末尾に `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>` を付与
3. コミットを作成する
4. リモートに push する

### 注意事項
- コミットメッセージは必ず日本語で書くこと
- 直近のコミットメッセージのスタイルに合わせること
- HEREDOC 形式でコミットメッセージを渡すこと
- 全ての操作を1回のレスポンスで完了すること。余計なテキストやメッセージは出力しないこと
