#!/usr/bin/env bash

# tmux-resurrect post-save-layout hook. Resurrect saves an opencode pane as a bare
# `opencode`, which restores to the home screen instead of the session that was open.
# The tmux-pane-session opencode plugin keeps the open session's ID in the pane's
# @opencode_session option; this rewrites those panes' saved command to
# `opencode --session <id>` so the restore reopens the same session.
#
# Save file pane fields: 1 type, 2 session, 3 window, 6 pane index, 10 pane command,
# 11 ":<full command>".

state_file="$1"
[ -f "$state_file" ] || exit 0

tmp_file="$state_file.opencode"
awk -F'\t' -v OFS='\t' '
	FNR == NR {
		if ($4 != "") session_ids[$1 SUBSEP $2 SUBSEP $3] = $4
		next
	}
	# A pane whose own process is opencode (no shell in between) is saved with an empty
	# command, because the pgrep strategy only reads the pane process'"'"'s children.
	$1 == "pane" && ($11 ~ /^:opencode( |$)/ || ($10 == "opencode" && $11 == ":")) \
		&& (($2 SUBSEP $3 SUBSEP $6) in session_ids) {
		$11 = ":opencode --session " session_ids[$2 SUBSEP $3 SUBSEP $6]
	}
	{ print }
' <(tmux list-panes -a -F "#{session_name}	#{window_index}	#{pane_index}	#{@opencode_session}") \
	"$state_file" >"$tmp_file" && mv "$tmp_file" "$state_file"
