---
allowed-tools: Write, Bash(git checkout:*), Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git push:*), Bash(git rev-parse:*), Bash(gh pr create:*), Bash(gh pr list:*)
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
   - 末尾に Anthropic 公式推奨の標準フッター 2 行セットを付与。モデル名は固定しないこと（セッションごとに動作モデルが異なるうえ、モデル世代が変わると帰属が誤情報になる。実際 `Claude Opus 4.8` 固定のまま legacy 入りしていた）:
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```
4. `git rev-parse --absolute-git-dir` を実行し、出力された絶対パスを `<GITDIR>` とする
5. コミットメッセージを **Write ツール**で `<GITDIR>/CLAUDE_COMMIT_MSG.txt` に書き出し、`git commit -F "<GITDIR>/CLAUDE_COMMIT_MSG.txt"` でコミットする
6. ブランチをリモートに push する（`git push -u origin ブランチ名`）
7. PR 本文を **Write ツール**で `<GITDIR>/CLAUDE_PR_BODY.md` に書き出し、`gh pr create --title "<日本語タイトル>" --body-file "<GITDIR>/CLAUDE_PR_BODY.md"` で PR を作成する
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
- **コミットメッセージと PR 本文をシェル経由で直接渡さないこと**（`git commit -m` / `gh pr create --body` / heredoc / PowerShell ヒアストリング `@'...'@` はいずれも禁止）。主シェルが PowerShell の環境ではヒアストリングが壊れて本文に `@` が混入する事故が繰り返し起きている。必ず Write ツールでファイルに書き出し `git commit -F` / `gh pr create --body-file` を使うこと
- 本文ファイルの置き場所は **`git rev-parse --absolute-git-dir` の出力を使うこと**。`.git/` という固定文字列は使ってはいけない: worktree では `.git` はディレクトリではなくファイルなので `.git/CLAUDE_PR_BODY.md` は "Not a directory" で失敗する。`--absolute-git-dir` は通常リポジトリなら `.../.git`、worktree なら `.../.git/worktrees/<名前>` を返し、どちらも実在する書き込み可能なディレクトリで git の管理対象外（誤ってステージされず、毎回上書きでよい。削除は不要）
- 出力は絶対パスなので、**同じ絶対パスをそのまま `-F` / `--body-file` に渡す**こと（相対パスはカレントディレクトリ次第で壊れる）。Write ツールは BOM なし UTF-8 で書き込むため文字化けしない
- PR タイトルは1行なので `--title "..."` にインラインで渡してよい
- 全ての操作を1回のレスポンスで完了すること。余計なテキストやメッセージは出力しないこと
