# 週次 Dependabot メールの無人 Claude が Bash などを使える状態だった件

## 対象

- `scripts/dependabot-weekly.sh`（Phase 5 の claude 起動行とその説明コメント）

## 変更内容

- 無人で起動する `claude -p` に `--tools ""` を追加し、組み込みの道具（Bash・PowerShell・Read・Write・WebFetch など）を外した。Gmail の送信道具（MCP）はこの指定の対象外なので残る。
- 「ファイルを読む道具は渡さず」としていたコメントを、実際に効いている仕組みの説明に書き換えた。

## 理由

コミット後の自動セキュリティレビューが「第三者の文面による指示の注入と、道具の権限の与えすぎ」を指摘した。スクリプトは `--permission-mode dontAsk` と `--allowedTools` で送信だけに絞ったつもりだったが、無人起動でもユーザー設定（`settings.json`）の自動許可が読み込まれ、そこで `Bash`・`PowerShell`・`Write`・`WebFetch` が無条件に許可されている。そのため、アラートの説明文（第三者が書いた文面、プロンプトに直接入る）に指示が仕込まれていた場合、無人の Claude がコマンドを実行できた。説明文は GitHub が審査した脆弱性情報なので起こる見込みは低いが、スクリプトのコメントが前提にしていた守りが効いていなかった。

## 検証

- `claude --help`（2.1.220）で `--tools ""` が「組み込みの道具をすべて無効にする」指定だと確認。
- 同じオプションで `claude -p` を起動し、使える道具の一覧を出させて比べた（メールは送っていない）。
  - `--tools ""` なし: Bash・PowerShell・Read・Write・Edit・Glob・Grep が出る
  - `--tools ""` あり: `mcp__claude_ai_Gmail__send_message` だけが出る
- `bash -n` で構文エラーがないことを確認。

## 残作業

- メールが実際に届くかは、次の土曜 09:00 の定期実行で確認する。届かなければ、次に Claude Code を起動したときに起動時フックが失敗を知らせる。
