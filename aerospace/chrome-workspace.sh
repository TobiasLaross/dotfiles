#!/bin/zsh

set -eu -o pipefail

SCRIPT_DIR="$(dirname "$0")"
chrome_window_id="$("$SCRIPT_DIR/get-window-id.sh" "Google Chrome")"
aerospace move-node-to-workspace --window-id "$chrome_window_id" 2
