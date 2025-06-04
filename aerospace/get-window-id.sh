#!/bin/zsh

set -eu -o pipefail

get_window_id() {
    local app_name="$1"

    local windows=$(aerospace list-windows --all --json)
    local window_id=$(echo -e "$windows" | jq -r --arg app "$app_name" '.[] | select(.["app-name"] == $app) | .["window-id"]')

    if [ -z "$window_id" ]; then
        open -a "$app_name"
        if [ $? -ne 0 ]; then
            echo "Failed to open $app_name" >&2
            exit 1
        fi
        while [ -z "$window_id" ]; do
            windows=$(aerospace list-windows --all --json)
            window_id=$(echo -e "$windows" | jq -r --arg app "$app_name" '.[] | select(.["app-name"] == $app) | .["window-id"]')
            sleep 0.1
        done
    fi

    echo "$window_id"
}

get_window_id "$1"
