#!/usr/bin/env zsh
# Kills a tmux session unless a coding agent (opencode, Claude Code, Copilot CLI)
# is still running in one of its panes; then it shows a popup instead.
# Usage (from tmux): tmux-kill-session.sh <session-name> <client-name>

session="$1"
client="$2"
agents=(opencode claude copilot)

running=()
while IFS=$'\t' read -r window_index window_name pane_tty; do
    # Agents often run under node, so check the first two argv words, not just comm.
    found=$(ps -t "$pane_tty" -o args= | awk -v names="${(j: :)agents}" '
        BEGIN { split(names, list, " "); for (key in list) wanted[list[key]] = 1 }
        {
            for (field = 1; field <= 2 && field <= NF; field++) {
                word = $field; sub(/^-/, "", word); sub(/.*\//, "", word)
                if (word in wanted) { print word; next }
            }
        }' | sort -u | paste -sd ', ' -)
    [[ -n "$found" ]] && running+=("  ${window_index}: ${window_name} -> ${found}")
done < <(tmux list-panes -s -t "=$session" -F $'#{window_index}\t#{window_name}\t#{pane_tty}')

if (( ${#running} == 0 )); then
    tmux kill-session -t "=$session"
    exit 0
fi

message="Can't close '$session', agents are still running:"$'\n\n'"${(F)running}"$'\n\n'"Press any key to dismiss"
tmux display-popup -c "$client" -T " Session still in use " -w 60 -h $(( ${#running} + 7 )) \
    -e "KILL_SESSION_MESSAGE=$message" -E 'zsh -fc '\''print -r -- "$KILL_SESSION_MESSAGE"; read -sk1'\'
