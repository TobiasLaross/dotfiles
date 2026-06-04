#!/usr/bin/env bash
# Start a detached tmux server at login so launchd jobs that shell out to
# `tmux` (e.g. the claude-sessions dashboard) don't fail with
# "error connecting to /private/tmp/tmux-501/default" before the user has
# manually attached. Mirrors what `sess dotfiles` does for the Dotfiles
# session, minus the attach.
set -euo pipefail

SESSION="Dotfiles"
DIR="${DOTFILES:-$HOME/dotfiles}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exit 0
fi

tmux new-session -d -s "$SESSION" -n "Code" -c "$DIR"
tmux new-window -t "$SESSION" -n "Test" -c "$DIR"
tmux select-window -t "$SESSION:1"
