---
allowed-tools: Write, Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*), Bash(git rev-parse:*)
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
   - 末尾に Anthropic 公式推奨の標準フッター 2 行セットを付与（AI 生成コミットの可視性 + ガバナンス透明性のため）。モデル名は固定せず公式の汎用形式（セッションごとに動作モデルが異なるため、固定すると帰属が誤情報になる）:
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```
3. `git rev-parse --absolute-git-dir` を実行し、出力された絶対パスを `<GITDIR>` とする
4. コミットメッセージを **Write ツール**で `<GITDIR>/CLAUDE_COMMIT_MSG.txt` に書き出し、`git commit -F "<GITDIR>/CLAUDE_COMMIT_MSG.txt"` でコミットする
5. リモートに push する

### 注意事項
- コミットメッセージは必ず日本語で書くこと
- 直近のコミットメッセージのスタイルに合わせること
- **コミットメッセージをシェル経由で直接渡さないこと**（`git commit -m` / heredoc / PowerShell ヒアストリング `@'...'@` はいずれも禁止）。主シェルが PowerShell の環境ではヒアストリングが壊れてメッセージに `@` が混入する事故が繰り返し起きている。必ず Write ツールでファイルに書き出し `git commit -F` を使うこと
- メッセージファイルの置き場所は **`git rev-parse --absolute-git-dir` の出力を使うこと**。`.git/` という固定文字列は使ってはいけない: worktree では `.git` はディレクトリではなくファイルなので `.git/CLAUDE_COMMIT_MSG.txt` は "Not a directory" で失敗する。`--absolute-git-dir` は通常リポジトリなら `.../.git`、worktree なら `.../.git/worktrees/<名前>` を返し、どちらも実在する書き込み可能なディレクトリで git の管理対象外（誤ってステージされず、毎回上書きでよい。削除は不要）
- 出力は絶対パスなので、**同じ絶対パスをそのまま `-F` に渡す**こと（相対パスはカレントディレクトリ次第で壊れる）。Write ツールは BOM なし UTF-8 で書き込むため文字化けしない
- 全ての操作を1回のレスポンスで完了すること。余計なテキストやメッセージは出力しないこと
