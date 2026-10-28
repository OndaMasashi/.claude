#!/bin/bash
# SessionStart hook: 開いたリポジトリの本番の依存に未対応の Dependabot アラート（critical / high）があれば、
# 件数を Claude に伝え、ユーザーへの報告と対応の提案を促す。開発用の依存や medium / low だけなら黙る
# （それらは GitHub のアラート一覧で見る。週次メールにも公開していないリポジトリは件数だけ載る）。
# 週次メール（~/.claude/scripts/dependabot-weekly.sh）が前回失敗していれば、リポジトリに関係なくそれも伝える。
# memory の退避（~/.claude/scripts/memory-backup.sh）が 3 日以上成功していないときも同じく伝える。
# GitHub リポジトリでない・gh 未認証・アラート無効・通信失敗のときは何も出力しない。常に exit 0。
# 自動実行のジョブからは CLAUDE_DEPENDABOT_HOOK=off で止められる。
# Windows の Git Bash は外部コマンドの起動1回ごとにセッション開始が遅れるため、
# 文字列処理は sed / grep / cat を使わず bash の組み込み機能で済ませる。

[ "${CLAUDE_DEPENDABOT_HOOK:-}" = off ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

# フックの実行ディレクトリに頼らず、入力の cwd に移ってから origin を読む
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null

notice=""   # 画面に出す1行
context=""  # Claude に渡す指示

failed_flag="$HOME/.claude/cache/dependabot-weekly/FAILED"
if [ -f "$failed_flag" ]; then
  notice="週次の Dependabot メールが届いていません（$(<"$failed_flag")）。~/.claude/cache/dependabot-weekly/run.log を確認してください。"
  context="[Dependabot 週次ジョブ] $notice"
fi

# memory の退避は毎日 12:00。スクリプトの失敗だけでなく、PC が切れていた・タスクが消えた・push が通らない、
# のどれでも last-success が古くなる。記録が無い・壊れているときも知らせる
backup_stamp="$HOME/.claude/cache/memory-backup/last-success"
last=0
[ -f "$backup_stamp" ] && read -r last < "$backup_stamp"
[[ $last =~ ^[0-9]+$ ]] && last=$((10#$last)) || last=0
printf -v now '%(%s)T' -1
days=$(( (now - last) / 86400 ))
if (( days >= 3 )); then
  if (( last == 0 )); then line="memory の退避が成功した記録がありません。"; else line="memory の退避が ${days} 日成功していません。"; fi
  line+="~/.claude/cache/memory-backup/run.log とタスクスケジューラの「ClaudeMemoryBackup」を確認してください。"
  notice=${notice:+$notice }$line
  context="${context:+$context }[memory 退避] $line"
fi

# owner/repo を取り出す。GitHub の名前に使える文字だけを通し、\ や .. でキャッシュの置き場所の外を
# 指されたり、細工した文字列が Claude への指示に混ざったりしないようにする
github_re='^(https://github\.com/|git@github\.com:)([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)$'
url=$(git remote get-url origin 2>/dev/null)
if command -v gh >/dev/null 2>&1 && [[ $url =~ $github_re ]]; then
  owner=${BASH_REMATCH[2]}
  name=${BASH_REMATCH[3]%.git}
  if [[ $owner != .* && -n $name && $name != . && $name != .. ]]; then
    repo="$owner/$name"

    # 問い合わせに数秒かかり起動が待たされるため、結果を 6 時間キャッシュする。
    # 失敗（権限のない他人のリポジトリなど）も空の結果として残し、開くたびに待たないようにする
    cache_dir="$HOME/.claude/cache/dependabot"
    cache="$cache_dir/${owner}__${name}.txt"
    if [ -f "$cache" ] && [ -n "$(find "$cache" -mmin -360 2>/dev/null)" ]; then
      severities=$(<"$cache")
    else
      severities=$(timeout 10 gh api --paginate \
        "repos/$repo/dependabot/alerts?state=open&severity=critical,high&scope=runtime&per_page=100" \
        --jq '.[].security_advisory.severity' 2>/dev/null) || severities=""
      mkdir -p "$cache_dir" && printf '%s\n' "$severities" > "$cache"
    fi

    critical=0 high=0
    while IFS= read -r severity; do
      case $severity in
        critical) critical=$((critical + 1)) ;;
        high)     high=$((high + 1)) ;;
      esac
    done <<< "$severities"

    if [ $((critical + high)) -gt 0 ]; then
      summary="critical $critical / high $high"
      line="Dependabot: $repo の本番の依存に未対応の脆弱性アラート（$summary）"
      notice=${notice:+$notice }$line
      context="${context:+$context }[Dependabot] このリポジトリ（$repo）の本番の依存に、未対応の脆弱性アラートがあります: $summary。一覧: https://github.com/$repo/security/dependabot"
    fi
  fi
fi

[ -z "$notice" ] && exit 0

jq -n --arg notice "$notice" --arg context "$context" '{
  systemMessage: $notice,
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "\($context) ユーザーと対話しているセッションなら、最初の応答でこの件を伝え、対応（依存パッケージの更新や定期ジョブの確認）を提案すること。今の依頼と無関係なら、依頼に答えたあと1〜2行で添えればよい。スラッシュコマンドやスクリプトから自動で起動された作業なら、この件には触れない。"
  }
}'
exit 0
