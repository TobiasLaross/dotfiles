#!/usr/bin/env bash
# Run machine-local hooks that must not be referenced from the shared settings.json.
#
# Usage: run-local-hooks.sh <group>
# Runs every executable in ~/.claude/hooks-local/<group>/ with the hook payload on stdin.
# The first hook that prints output or exits non-zero decides the outcome; its stdout,
# stderr and exit code are passed through. A missing directory is a no-op.

group="$1"
hooks_dir="$HOME/.claude/hooks-local/$group"
[ -n "$group" ] && [ -d "$hooks_dir" ] || exit 0

payload="$(cat)"

for hook in "$hooks_dir"/*; do
    [ -f "$hook" ] && [ -x "$hook" ] || continue
    output="$(printf '%s' "$payload" | "$hook")"
    status=$?
    if [ "$status" -ne 0 ] || [ -n "$output" ]; then
        printf '%s' "$output"
        exit "$status"
    fi
done

exit 0
