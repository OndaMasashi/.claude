#!/usr/bin/env bash
# 技術バージョンリスト自動更新スクリプト
# 実行: 毎週日曜 00:00 (Windowsタスクスケジューラから呼び出し)
# 入力: ~/.claude/tech-versions-sources.tsv  (ソース・オブ・トゥルース)
# 出力: ~/.claude/tech-versions.md           (生成物)
#
# 新規技術を追加するには tsv に1行 (category<TAB>name<TAB>command) を追加するだけ。
# このスクリプトの改修は不要。
set -u

SOURCES="$HOME/.claude/tech-versions-sources.tsv"
TARGET="$HOME/.claude/tech-versions.md"
LOG="$HOME/.claude/scripts/update-tech-versions.log"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$(dirname "$LOG")"
echo "[$TODAY $(date +%H:%M:%S)] start update" >> "$LOG"

if [ ! -f "$SOURCES" ]; then
  echo "[$TODAY $(date +%H:%M:%S)] ERROR: $SOURCES not found" >> "$LOG"
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Phase 1: 全エントリを並列で取得 ---
LINENO_COUNTER=0
while IFS=$'\t' read -r category name cmd; do
  # コメント行・空行をスキップ
  [[ "$category" =~ ^[[:space:]]*# ]] && continue
  [ -z "${category// }" ] && continue
  LINENO_COUNTER=$((LINENO_COUNTER + 1))
  printf '%s\t%s\n' "$category" "$name" > "$TMPDIR/meta_$LINENO_COUNTER"
  (eval "$cmd" 2>/dev/null | head -1 || echo "FAILED") > "$TMPDIR/result_$LINENO_COUNTER" &
done < "$SOURCES"

wait
TOTAL=$LINENO_COUNTER

# --- Phase 2: カテゴリ単位にグルーピング (tsv 内で分散していてもまとめる) ---
declare -A CATEGORY_ROWS
declare -a CATEGORY_ORDER
for i in $(seq 1 "$TOTAL"); do
  IFS=$'\t' read -r category name < "$TMPDIR/meta_$i"
  version=$(cat "$TMPDIR/result_$i")
  [ -z "$version" ] && version="FAILED"
  if [ -z "${CATEGORY_ROWS[$category]+x}" ]; then
    CATEGORY_ORDER+=("$category")
    CATEGORY_ROWS[$category]=""
  fi
  CATEGORY_ROWS[$category]+="| $name | $version |"$'\n'
done

# --- Phase 3: md 生成 ---
{
  echo "---"
  echo "last_updated: $TODAY"
  echo "update_schedule: 毎週日曜 00:00 (Windows タスクスケジューラによる自動更新)"
  echo "update_script: ~/.claude/scripts/update-tech-versions.sh"
  echo "sources: ~/.claude/tech-versions-sources.tsv"
  echo "---"
  echo
  echo "# 技術バージョン最新版リスト"
  echo
  echo "> このファイルはモデル訓練時の知識を上書きする「最新版の真実」です。"
  echo "> FW・ライブラリ・ランタイムのバージョンに言及／コード生成する際は必ず参照してください。"
  echo ">"
  echo "> **新規技術の追加**: \`~/.claude/tech-versions-sources.tsv\` に1行追加してスクリプト再実行。"

  for category in "${CATEGORY_ORDER[@]}"; do
    echo
    echo "## $category"
    echo
    echo "| 技術 | 最新版 |"
    echo "|---|---|"
    printf '%s' "${CATEGORY_ROWS[$category]}"
  done
} > "$TARGET.new"

mv "$TARGET.new" "$TARGET"

echo "[$TODAY $(date +%H:%M:%S)] done update -> $TARGET ($TOTAL entries)" >> "$LOG"
