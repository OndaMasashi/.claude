# ROADMAP

このプロジェクトの恒久的な「今後のタスク一覧」。控えているタスクが**埋もれないこと**を最優先に運用する。運用ルールは [CLAUDE.md](CLAUDE.md) の「ROADMAP の運用」を参照。

- 未対応/予定タスクは「未対応タスク」に常に保ち、深刻度・概要・該当箇所・（あれば）根拠リンクを簡潔に記す（本文の詳細は書かない）。
- 完了したら詳細は `improvement_list/` に記録し、ここからは**リンクのみ**を張って「完了タスク」へ移す。

深刻度: 🔴 高 / 🟡 中 / 🔵 低

## 未対応タスク

> 新たな TODO・監査指摘・将来機能が出たらここへ追記して埋もれを防ぐ。

| 深刻度 | 概要 | 該当箇所 | 根拠ドキュメント |
| :--- | :--- | :--- | :--- |
| 🟡 中 | 各プロジェクトの memory（62件・約9MB）が PC にしか無い。公開中の本リポジトリには入れず、退避先（別の非公開リポジトリ等）を決めて定期コピーする。メールアドレス・password 等の記述があるファイルは push 前に中身を確認 | `projects/*/memory/`（`.gitignore` の `projects/` で除外中） | - |
<!-- 例: | 🔴 高 | API キーがログに出力される | src/api/client.ts | improvement_list/2026-06-11_security-audit.md -->

## 完了タスク

> 完了タスクをここへ移し、`improvement_list/` の記録へリンクする。

| 完了日 | 概要 | 記録 |
| :--- | :--- | :--- |
| 2026-10-27 | 週次 Dependabot メールの無人 Claude から Bash 等の道具を外した | [improvement_list/2026-10-27_dependabot-weekly-restrict-tools.md](improvement_list/2026-10-27_dependabot-weekly-restrict-tools.md) |
<!-- 例: | 2026-06-11 | セキュリティ監査の指摘対応 | improvement_list/2026-06-11_security-audit.md -->
