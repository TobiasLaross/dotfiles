#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

move_to_workspace() {
    window_id=$("$SCRIPT_DIR/get-window-id.sh" "$1")
    if [[ -n "$window_id" ]]; then
        aerospace move-node-to-workspace --window-id $window_id $2
        if [[ $3 == "float" ]]; then
            aerospace layout --window-id $window_id floating
        fi

        if [[ $3 == "focus" ]]; then
            aerospace focus --window-id $window_id
        fi
    fi
}

move_to_workspace "Google Chrome" 1 "focus"
move_to_workspace "iTerm2" 2
move_to_workspace "Slack" 3
move_to_workspace "Mail" 3
move_to_workspace "Postman" p "float"
move_to_workspace "Microsoft Teams" 6
