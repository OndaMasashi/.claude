# tech-versions.md の Anthropic Models セクションが古いまま残っていた件

## 対象

- `tech-versions-sources.tsv`（モデル4行と説明コメント）
- `tech-versions.md`（スクリプト再実行による再生成）
- `commands/cp.md`（波及していた古いモデル名の除去）

## 変更内容

- `Claude Opus` を 4.8 → **5**、`Claude Sonnet` を 4.6 → **5** に修正。`Claude Haiku` 4.5 は正しかったので据え置き。
- 抜けていた **`Claude Fable` 5** を追加（現行ラインナップの最上位）。エントリ数 23 → 24。
- TSV のコメントに「ここは週次自動更新の対象外なので、ログが正常でも古いまま残る」旨と一次情報の URL、最終確認日を明記。
- `commands/cp.md` の `Co-Authored-By: Claude Opus 4.8 (1M context)` を、モデル名を固定しない公式の汎用形式に変更。`commands/commit.md` は既にこの方針を採っており、cp.md だけ追従できていなかった。

## 理由

週次の自動更新（毎週日曜 00:00）は正常に動作しており、当日 00:00:36 に成功ログを残し npm 由来の19項目はすべて最新化されていた。しかし **Anthropic Models の3行だけは公開レジストリが無いため TSV 内に `echo 4.8` のようにハードコードされており**、モデル世代が変わっても誰も書き換えないため放置されていた。

「自動更新が走っている」ことと「中身が正しい」ことが別だった典型例。`last_updated` の日付と更新ログはどちらもグリーンなので、この種の古さは日付チェックでは検出できない。

Opus 4.8 / Sonnet 4.6 は公式ドキュメント上いずれも legacy に降格済みで、`cp.md` の固定フッターは実在しない帰属を毎コミットに書き込む状態だった。

## 検証

- 一次情報として Anthropic 公式のモデル一覧（platform.claude.com/docs/en/about-claude/models/overview）を取得し、現行が Fable 5 / Opus 5 / Sonnet 5 / Haiku 4.5 の4本、Opus 4.8・4.7・4.6・4.5 と Sonnet 4.6・4.5 が legacy であることを確認。モデル訓練時の知識では判断していない。
- スクリプト再実行後、`FAILED` 0件・24エントリを確認。npm 由来の値が当日朝の自動更新分から退行していないことを差分で確認。

## 残作業

- **自動化は見送り**: モデル一覧は Models API（`/v1/models`）で取得できるが、この環境は claude.ai (Max) の OAuth 認証で `ANTHROPIC_API_KEY` を持たないため、更新スクリプトから呼べない。当面は手動更新のまま、TSV コメントの手順に従う。
- 新モデル発表時は TSV の4行を書き換えて `bash ~/.claude/scripts/update-tech-versions.sh` を実行する。
