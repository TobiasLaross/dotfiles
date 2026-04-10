#!/bin/zsh

FEATURES_BASE="$HOME/.claude/features"
MAX_ITERATIONS="${2:-50}"

name="$1"
if [[ -z "$name" ]]; then
	echo "Available features with task loops:"
	for dir in "$FEATURES_BASE"/*/; do
		[[ "$(basename "$dir")" == "done" ]] && continue
		[[ -d "$dir" ]] || continue
		[[ -f "$dir/TASKER.md" ]] || continue
		tasks_done=$(grep -c '^- \[x\] ' "$dir/tasks.md" 2>/dev/null || echo 0)
		tasks_total=$(grep -c '^- \[.\] ' "$dir/tasks.md" 2>/dev/null || echo 0)
		echo "  $(basename "$dir")  ($tasks_done/$tasks_total tasks)"
	done
	echo ""
	echo "Usage: tasker <name> [max-iterations]"
	echo "Default max iterations: 50"
	exit 1
fi

FEATURE_DIR="$FEATURES_BASE/$name"

if [[ ! -d "$FEATURE_DIR" ]]; then
	echo "No feature found at $FEATURE_DIR"
	echo "Run /feature-plan then /tasker in Claude Code first."
	exit 1
fi

if [[ ! -f "$FEATURE_DIR/TASKER.md" ]]; then
	echo "No TASKER.md found. Run /tasker in Claude Code first."
	exit 1
fi

if grep -q "^TASKER_DONE$" "$FEATURE_DIR/progress.md" 2>/dev/null; then
	echo "This implementation is already done."
	[[ -f "$FEATURE_DIR/review.md" ]] && echo "Review: $FEATURE_DIR/review.md"
	exit 0
fi

# Read working directory from story.md
workdir=$(grep '^> Working directory:' "$FEATURE_DIR/story.md" | sed 's/> Working directory: //')
if [[ -n "$workdir" && -d "$workdir" ]]; then
	cd "$workdir"
else
	echo "Warning: Could not detect working directory from story.md, using $(pwd)"
fi

echo "Starting task loop: $name"
echo "Working directory: $(pwd)"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

iteration=0
while :; do
	iteration=$((iteration + 1))

	if [[ $iteration -gt $MAX_ITERATIONS ]]; then
		echo ""
		echo "Reached max iterations ($MAX_ITERATIONS). Stopping."
		echo "Run 'tasker $name [higher-limit]' to continue."
		break
	fi

	tasks_done=$(grep -c '^- \[x\] ' "$FEATURE_DIR/tasks.md" 2>/dev/null || echo 0)
	tasks_total=$(grep -c '^- \[.\] ' "$FEATURE_DIR/tasks.md" 2>/dev/null || echo 0)

	echo "=== Iteration $iteration/$MAX_ITERATIONS ($tasks_done/$tasks_total tasks done) ==="

	claude -p --dangerously-skip-permissions <"$FEATURE_DIR/TASKER.md"

	if grep -q "^TASKER_DONE$" "$FEATURE_DIR/progress.md" 2>/dev/null; then
		echo ""
		echo "Tasker is done!"
		[[ -f "$FEATURE_DIR/review.md" ]] && echo "Review: $FEATURE_DIR/review.md"

		# Move to done
		mkdir -p "$FEATURES_BASE/done"
		mv "$FEATURE_DIR" "$FEATURES_BASE/done/$name"
		echo "Archived to: $FEATURES_BASE/done/$name"
		break
	fi

	echo "--- Iteration $iteration complete. ---"
done
