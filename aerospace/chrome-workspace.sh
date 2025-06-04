#!/bin/zsh

set -eu -o pipefail

SCRIPT_DIR="$(dirname "$0")"
chrome_window_id="$("$SCRIPT_DIR/get-window-id.sh" "Google Chrome" | tr -d '\n')"

in_workspace_1="$(aerospace list-windows --workspace 1 | awk '{print $1}' | grep -x "$chrome_window_id" || true)"

if [[ -n "$in_workspace_1" ]]; then
  target_workspace="2"
else
  target_workspace="1"
fi

aerospace move-node-to-workspace --window-id "$chrome_window_id" "$target_workspace"
