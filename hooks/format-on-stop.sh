#!/bin/bash
# ターン終了時の一括フォーマット (Stop フック)
#
# auto-format.sh (PostToolUse) がこのセッションで編集された .ts/.tsx/.js/.jsx を
# キューへ記録しておくので、ターン終了のここでまとめて整形する。
# Prettier がローカル導入された PJ のファイルだけを対象にする (未導入 PJ は no-op)。
#
# なぜ Stop か: セッション中 (1ターン内の Edit 連鎖) は一切整形しないため、
# ディスクとモデルのファイル像が乖離せず、old_string 不一致ループが起きない。
#
# 既知の制約:
#  - 同一ターン内で「編集 → そのまま git commit」まで行うと、コミット時点では
#    まだ未整形 (整形は Stop=このフックが走る後) になる。整形前コミットを厳密に
#    避けたい場合は編集とコミットをターンで分けるか、別途コミット直前整形を置く。
#  - node_modules/prettier の実在で導入判定するため、Yarn PnP など node_modules を
#    物理的に持たない構成は非対応 (サイレント no-op)。

# 与えられたファイルの祖先ディレクトリを上へたどり、node_modules/prettier/package.json
# を最初に持つディレクトリ (= Prettier 導入済みの PJ ルート) を出力する。
# 見つからなければ何も出力しない (未導入 PJ は整形しない)。
find_prettier_root() {
  dir=$(dirname "$1")
  while [ -n "$dir" ] && [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/node_modules/prettier/package.json" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && break
    dir="$parent"
  done
}

INPUT=$(cat)

# 無限ループ安全弁: このフックは block を返さないので通常 true にならないが、
# 万一 Stop が連続ブロック状態 (stop_hook_active) なら何もせず抜ける。
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
[ -z "$SESSION_ID" ] && exit 0

. "$(dirname "$0")/format-queue-common.sh" 2>/dev/null
[ -n "$FORMAT_QUEUE_DIR" ] || exit 0   # 共通定義が読めなければ何もしない (壊すより no-op)
QUEUE_DIR="$FORMAT_QUEUE_DIR"
QUEUE_FILE="$QUEUE_DIR/$SESSION_ID.txt"

# 孤児キューの掃除: 7日以上更新のないキュー(.txt)と退避ファイル(.processing)を削除する
# (クラッシュ等で残った場合の対策)。ただし自セッションのアクティブなキュー/退避は
# 除外し、誤って消さない。生存中でも編集が止まっただけのキューを守るため閾値は +7
# (find の -mtime +N は約 N+1 日以上) にしている。
[ -d "$QUEUE_DIR" ] && find "$QUEUE_DIR" -type f \
  \( -name '*.txt' -o -name '*.processing' \) -mtime +7 \
  ! -name "$SESSION_ID.txt" ! -name "$SESSION_ID.txt.*" -delete 2>/dev/null

[ -f "$QUEUE_FILE" ] || exit 0

# 自セッション分をアトミックな rename で退避してから読む。rename 後に届いた追記は
# 新しい $SESSION_ID.txt に落ち、次の Stop で拾われる (cat→rm の非アトミックな窓で
# 並行追記を取りこぼす問題を回避。同一 session_id を複数プロセスで共有した場合の保険)。
PROCESSING="$QUEUE_FILE.$$.processing"
mv "$QUEUE_FILE" "$PROCESSING" 2>/dev/null || exit 0
QUEUE_CONTENT=$(cat "$PROCESSING" 2>/dev/null)
rm -f "$PROCESSING"

# 重複排除して1ファイルずつ整形
printf '%s\n' "$QUEUE_CONTENT" | sort -u | while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue
  [ -f "$FILE_PATH" ] || continue   # 削除・改名済みは飛ばす

  # 祖先に Prettier 導入済み PJ ルートがあれば、そこを基準に整形 (未導入 PJ はスキップ)
  root=$(find_prettier_root "$FILE_PATH")
  if [ -n "$root" ]; then
    (cd "$root" && npx --no-install prettier --write "$FILE_PATH" >/dev/null 2>&1) || true
  fi
done

exit 0
