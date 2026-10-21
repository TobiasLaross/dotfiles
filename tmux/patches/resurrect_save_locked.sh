#!/usr/bin/env bash

# tmux-continuum releases its lock as soon as it backgrounds the save, so a save that
# outlasts @continuum-save-interval overlaps the next one and they pile up. This wrapper
# holds a lock for the whole save, skips a run while one is in progress, and kills a save
# that hangs so it cannot hold the lock forever. Skips, timeouts and failures go to the log,
# because continuum discards the save's output.
#
# Modes:
#   --install  run from tmux.conf after tpm: remember resurrect's save script and point
#              continuum at this wrapper instead
#   --locked   internal: the save itself, run while lockf holds the lock
#   (default)  called by continuum in place of resurrect's save.sh

self="$HOME/dotfiles/tmux/patches/resurrect_save_locked.sh"
original_path_option="@resurrect-original-save-script-path"
timeout_option="@resurrect-save-timeout"
default_timeout_seconds=300
log_file="${TMPDIR:-/tmp}/tmux-resurrect-save.log"

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >>"$log_file"
}

install() {
	local current_path
	current_path="$(tmux show-option -gqv @resurrect-save-script-path)"
	# Empty means resurrect is not installed; leave everything alone.
	[ -n "$current_path" ] || return 0
	# Equal to self means resurrect did not reset the option on this reload; keep what we have.
	if [ "$current_path" != "$self" ]; then
		tmux set-option -g "$original_path_option" "$current_path"
	fi
	tmux set-option -g @resurrect-save-script-path "$self"
}

run_save_with_timeout() {
	local original_path timeout_seconds save_pid watchdog_pid status
	original_path="$(tmux show-option -gqv "$original_path_option")"
	if [ -z "$original_path" ] || [ "$original_path" = "$self" ] || [ ! -x "$original_path" ]; then
		log "no usable resurrect save script ('$original_path'); save skipped"
		return 1
	fi
	timeout_seconds="$(tmux show-option -gqv "$timeout_option")"
	timeout_seconds="${timeout_seconds:-$default_timeout_seconds}"

	# Job control gives each background job its own process group, so a timeout can kill
	# the save together with the ps pipelines it spawns.
	set -m
	"$original_path" "$@" &
	save_pid=$!
	(
		sleep "$timeout_seconds"
		log "save still running after ${timeout_seconds}s; killed"
		kill -TERM -- "-$save_pid" 2>/dev/null
	) &
	watchdog_pid=$!
	set +m

	wait "$save_pid"
	status=$?
	kill -TERM -- "-$watchdog_pid" 2>/dev/null
	if [ "$status" -ne 0 ]; then
		log "save exited with status $status"
	fi
	return "$status"
}

run_locked() {
	local server_pid lock_file status
	server_pid="$(tmux display-message -p '#{pid}')"
	lock_file="${TMPDIR:-/tmp}/tmux-resurrect-save-${server_pid}.lock"
	lockf -s -t 0 "$lock_file" "$self" --locked "$@"
	status=$?
	# 75 is lockf's EX_TEMPFAIL: the lock is held by a save that is still running.
	if [ "$status" -eq 75 ]; then
		log "previous save still running; skipped"
	fi
	return "$status"
}

case "$1" in
--install) install ;;
--locked)
	shift
	run_save_with_timeout "$@"
	;;
*) run_locked "$@" ;;
esac
