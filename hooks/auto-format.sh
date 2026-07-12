#!/bin/bash
# コード自動フォーマット (PostToolUse)
# Edit/Write 後、対象ファイルが属するプロジェクトに Prettier が
# 「ローカル導入」されている場合のみ整形する。
FILE_PATH=$(jq -r '.tool_input.file_path')

# 対象拡張子でなければ何もしない
case "$FILE_PATH" in
  *.ts | *.tsx | *.js | *.jsx) ;;
  *) exit 0 ;;
esac

# 対象ファイルのディレクトリから上方向へ node_modules/prettier を探す。
# 見つからなければ no-op（npx キャッシュ/グローバルの prettier は使わない）。
# 目的: フォーマッタ未導入の PJ で Edit 直後に再整形が走り、モデルのファイル像と
#       ディスクが乖離して以後の Edit が old_string 不一致で失敗→再 Read ループに
#       陥る事故を防ぐ。整形はフォーマッタを明示導入した PJ にのみ限定する。
dir=$(dirname "$FILE_PATH")
root=""
while [ -n "$dir" ] && [ "$dir" != "." ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/node_modules/prettier/package.json" ]; then
    root="$dir"
    break
  fi
  parent=$(dirname "$dir")
  [ "$parent" = "$dir" ] && break
  dir="$parent"
done

if [ -n "$root" ]; then
  (cd "$root" && npx --no-install prettier --write "$FILE_PATH" 2>/dev/null) || true
fi

exit 0
