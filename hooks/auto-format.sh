#!/bin/bash
# コード自動フォーマット (PostToolUse)
# Edit/Write 後に対象ファイルを Prettier で自動整形する
FILE_PATH=$(jq -r '.tool_input.file_path')

# .ts, .tsx, .js, .jsx ファイルのみ対象
if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$'; then
  npx prettier --write "$FILE_PATH" 2>/dev/null
fi

exit 0
