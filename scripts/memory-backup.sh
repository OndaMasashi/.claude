#!/usr/bin/env bash
# 各プロジェクトの memory の退避
# 実行: 毎日 12:00（Windows タスクスケジューラ「ClaudeMemoryBackup」から呼び出し。PC が切れていた日は次の起動時）
# 処理: ~/.claude/projects/*/memory/ だけを退避用の clone（~/claude-memory-backup）の projects/ に丸ごと写し、
#       変更があれば commit して push する。会話ログ（*.jsonl）は写さない。origin は非公開リポジトリ
# 出力: ~/.claude/cache/memory-backup/run.log。成功したら同じ場所の last-success に時刻（epoch 秒）を書き、
#       起動時フック（hooks/dependabot-alerts.sh）が 3 日以上更新されていなければ知らせる
#
# このファイルは公開リポジトリで追跡されるため、退避先の URL は書かず clone の origin に任せる。
set -uo pipefail   # パイプの途中の失敗も拾う（写す途中で失敗したまま commit しないため）

SRC="$HOME/.claude/projects"
REPO="$HOME/claude-memory-backup"
WORK="$HOME/.claude/cache/memory-backup"
LOG="$WORK/run.log"
# 無人のジョブなので、認証が切れていても入力待ちで止まらず、すぐ失敗させる
export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never

mkdir -p "$WORK"
exec >>"$LOG" 2>&1
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { log "ERROR: $1"; exit 1; }
log "start"

git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || fail "退避用の clone が無い: $REPO"

# 送り先が非公開の GitHub リポジトリのときだけ続ける（origin の張り替えや、公開への切り替えに備える）
github_re='^https://github\.com/([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)$'
[[ $(git -C "$REPO" remote get-url origin 2>/dev/null) =~ $github_re ]] || fail "origin が GitHub のリポジトリではない"
private=$(timeout 30 gh repo view "${BASH_REMATCH[1]%.git}" --json isPrivate --jq .isPrivate 2>/dev/null)
[ "$private" = true ] || fail "送り先が非公開だと確かめられない（isPrivate=${private:-取得失敗}）"

# 元が見つからないときに projects/ を消してしまわないよう、写す前に数を確かめる。
# ./ を付けるのは、- で始まるフォルダ名（WSL のパス由来など）を tar がオプションと読まないため
cd "$SRC" || fail "memory の置き場に移れない: $SRC"
shopt -s nullglob
dirs=(./*/memory)
[ ${#dirs[@]} -gt 0 ] || fail "memory フォルダが1つも見つからない"

# 消えたファイルも反映されるよう、projects/ を作り直してから写す（消したものは git の履歴に残る）
rm -rf "$REPO/projects" && mkdir -p "$REPO/projects" || fail "projects/ を作り直せない"
tar cf - "${dirs[@]}" | tar xf - -C "$REPO/projects" || fail "memory を写せない"

# 秘密情報の形をした文字列があれば commit しない（値は出さず、ファイル名だけ残す）。
# 決まった形のものしか拾えないので、パスワードなどの値は memory に書かない運用が前提
secret_re='sk-ant-[A-Za-z0-9_-]{20,}|sk-proj-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{40,}|[rs]k_live_[A-Za-z0-9]{20,}'
secret_re+='|gh[oprsu]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}'
secret_re+='|xox[abprs]-[A-Za-z0-9-]{10,}|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.|-----BEGIN [A-Z ]*PRIVATE KEY'
hits=$(grep -rlE "$secret_re" "$REPO/projects")
case $? in
  0) fail "秘密情報の形をした文字列があるため止めた: ${hits//$'\n'/ }" ;;
  1) ;;  # 見つからない
  *) fail "秘密情報の検査に失敗した（grep の異常終了）" ;;
esac

cd "$REPO" || fail "退避用の clone に移れない"
git add -A projects || fail "git add に失敗"
if git diff --cached --quiet; then
  log "変更なし（memory ${#dirs[@]} 件）"
else
  git commit -q -m "memory backup $(date '+%Y-%m-%d %H:%M')" || fail "git commit に失敗"
  log "commit: $(git show --shortstat --format= HEAD)"
fi
# 前回 push に失敗した commit も送るため、変更が無くても毎回 push する。
# 手で別のブランチに切り替えたままでも、今の commit を main に送る
timeout 120 git push -q origin HEAD:main || fail "git push に失敗"

date +%s > "$WORK/last-success"
log "done"
