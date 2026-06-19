#!/usr/bin/env bash
# Non-blocking PreToolUse reminder for Read / SendUserFile.
# When the tool targets image file(s), inject a model-facing reminder to batch
# all related screenshots/images into ONE message so they stay swipeable.
# Never blocks, never errors: always exits 0.
set -u

input="$(cat 2>/dev/null)"
ext_re='\.(png|jpe?g|gif|webp|heic)'

is_image=0
if command -v jq >/dev/null 2>&1; then
  # Read -> .tool_input.file_path (string); SendUserFile -> .tool_input.files[] (array).
  paths="$(printf '%s' "$input" | jq -r '
    (([.tool_input.file_path] + (.tool_input.files // [])) | map(select(type == "string")) | .[])? // empty
  ' 2>/dev/null)"
  if printf '%s\n' "$paths" | grep -qiE "${ext_re}\$"; then
    is_image=1
  fi
else
  # No jq: best-effort grep over raw stdin for an image extension.
  if printf '%s' "$input" | grep -qiE "${ext_re}([\"/]|\$|[^a-zA-Z])"; then
    is_image=1
  fi
fi

if [ "$is_image" -eq 1 ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Reminder: to stay swipeable for the user, batch ALL related screenshots/images into ONE message — multiple Read calls in a single assistant turn (this is what makes them swipeable), or one SendUserFile call with every file in files[]. Never read or send related images one-per-message across separate turns."}}
JSON
fi

exit 0
