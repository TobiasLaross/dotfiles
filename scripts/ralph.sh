#!/bin/zsh

RALPH_BASE="$HOME/.claude/ralph"

name="$1"
if [[ -z "$name" ]]; then
	echo "Available implementations:"
	for dir in "$RALPH_BASE"/*/; do
		[[ "$(basename "$dir")" == "done" ]] && continue
		[[ -d "$dir" ]] || continue
		local tasks_done=$(grep -c '^\- \[x\]' "$dir/tasks.md" 2>/dev/null || echo 0)
		local tasks_total=$(grep -c '^\- \[' "$dir/tasks.md" 2>/dev/null || echo 0)
		echo "  $(basename "$dir")  ($tasks_done/$tasks_total tasks)"
	done
	echo ""
	echo "Usage: ralph <name>"
	exit 1
fi

RALPH_DIR="$RALPH_BASE/$name"

if [[ ! -d "$RALPH_DIR" ]]; then
	echo "No implementation found at $RALPH_DIR"
	echo "Run /ralph in Claude Code first to create the PRD."
	exit 1
fi

if [[ ! -f "$RALPH_DIR/RALPH.md" ]]; then
	echo "No RALPH.md found. Run /ralph in Claude Code first."
	exit 1
fi

if grep -q "^RALPH_DONE$" "$RALPH_DIR/progress.md" 2>/dev/null; then
	echo "This implementation is already done."
	[[ -f "$RALPH_DIR/review.md" ]] && echo "Review: $RALPH_DIR/review.md"
	exit 0
fi

# Read working directory from story.md
workdir=$(grep '^> Working directory:' "$RALPH_DIR/story.md" | sed 's/> Working directory: //')
if [[ -n "$workdir" && -d "$workdir" ]]; then
	cd "$workdir"
else
	echo "Warning: Could not detect working directory from story.md, using $(pwd)"
fi

echo "Starting Ralph loop: $name"
echo "Working directory: $(pwd)"

echo ""

iteration=0
while :; do
	iteration=$((iteration + 1))
	tasks_done=$(grep -c '^\- \[x\]' "$RALPH_DIR/tasks.md" 2>/dev/null || echo 0)
	tasks_total=$(grep -c '^\- \[' "$RALPH_DIR/tasks.md" 2>/dev/null || echo 0)

	echo "=== Iteration $iteration ($tasks_done/$tasks_total tasks done) ==="

	claude -p --dangerously-skip-permissions <"$RALPH_DIR/RALPH.md"

	if grep -q "^RALPH_DONE$" "$RALPH_DIR/progress.md" 2>/dev/null; then
		echo ""
		echo "Ralph is done!"
		[[ -f "$RALPH_DIR/review.md" ]] && echo "Review: $RALPH_DIR/review.md"

		# Move to done
		mkdir -p "$RALPH_BASE/done"
		mv "$RALPH_DIR" "$RALPH_BASE/done/$name"
		echo "Archived to: $RALPH_BASE/done/$name"
		break
	fi

	echo "--- Iteration $iteration complete. ---"
done
