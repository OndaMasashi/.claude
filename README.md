# .claude — Global Claude Code Settings

Claude Code のグローバル設定（`~/.claude/`）を複数マシン間で同期するための個人リポジトリ。

## 目的

- 複数マシンで同一の Claude Code 動作を再現する
- CLAUDE.md の運用ルールを version 管理する
- 設定変更の差分・履歴を可視化する

## 構成

| パス | 役割 |
| :--- | :--- |
| [CLAUDE.md](CLAUDE.md) | 全プロジェクト共通のユーザー指示 |
| [settings.json](settings.json) | 権限・フック・有効プラグイン・環境変数 |
| [skills-catalog.md](skills-catalog.md) | 利用可能なスキル一覧 |
| [tech-versions.md](tech-versions.md) | FW・ライブラリ・ランタイムの最新版リスト（週次自動更新） |
| [tech-versions-sources.tsv](tech-versions-sources.tsv) | 上記の取得ソース定義 |
| [hooks/](hooks/) | 各種イベントフック |
| [commands/](commands/) | カスタムスラッシュコマンド |
| [scripts/](scripts/) | メンテナンススクリプト |
| [plugins/](plugins/) | 有効プラグイン・ブロックリストのメタデータ |

詳細な運用ルール・各ファイルの内容は [CLAUDE.md](CLAUDE.md) および各ファイル冒頭のコメントを参照。

## 新規マシンでのセットアップ

```bash
# 既存の .claude をバックアップ（必要なら）
mv ~/.claude ~/.claude.bak

# リポジトリを clone
git clone https://github.com/OndaMasashi/.claude.git ~/.claude

# マシン固有ファイル（gitignore 対象）を自分で配置
#   - 機密トークン類（*.env）
#   - allowlist 等のマシン固有 JSON（*.example をコピーして編集）

# プラグインは Claude Code 起動時に自動再インストール
```

### 依存ツール

- git / bash / jq — フック実行に必須（Windows は Git Bash 推奨）
- npm / python — `tech-versions` 自動更新 / 一部フック用
- powershell — デスクトップ通知用（Windows のみ）

### 自動更新タスク（任意）

`tech-versions.md` の週次自動更新を有効化する場合、Windows タスクスケジューラから
`bash ~/.claude/scripts/update-tech-versions.sh` を毎週日曜 00:00 に実行するよう設定する。

## 機密情報の取り扱い

[.gitignore](.gitignore) で除外済みのものは**絶対にコミットしないこと**:

- `**/.env` — API キー・トークン類
- `sessions/` — ランタイムメタデータ（PID・cwd）
- `bash-command-log.txt` — Bash 実行履歴
- その他マシン固有ファイル（各 `.example` から生成）

誤ってコミットした場合は `git filter-branch` で履歴から完全削除し `--force-with-lease` で push する。

## リポジトリの性質

**private repo** 前提。理由:

- Windows ユーザー名・業務領域・内部プロジェクト名が各所に混入
- 絶対パス・マシン固有設定を含むため第三者が直接 clone しても動作しない

public 化する場合は上記をサニタイズする必要がある。
