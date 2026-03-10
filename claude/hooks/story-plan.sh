#!/bin/zsh

input=$(cat)

file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    pass
" 2>/dev/null)

# Expand ~ to home
file_path="${file_path/#\~/$HOME}"

# Only trigger for ~/.claude/stories/<name>/story.md
if [[ "$file_path" =~ "$HOME/.claude/stories/[^/]+/story\.md$" ]]; then
    story_dir=$(dirname "$file_path")

    cat <<EOF
story.md was just written to $file_path. Spawn a subagent (subagent_type=general-purpose) to create a high-level plan for this story. Give the subagent the following prompt:

---
Read the story at $file_path.

Then create a high-level design and implementation plan. Save it as $story_dir/plan.md.

The plan should cover:
- Summary of what needs to be built
- High-level architecture / design decisions
- Implementation phases with rough ordering

Repo detection (only if the current working directory contains /work/):
- List all directories inside ~/Developer/work/
- For each, briefly assess whether it is likely relevant to this story based on its name and the story goal
- Include a "Repos involved" section listing relevant repos and the reason each is needed

Keep the plan concise and actionable. Do not implement anything — planning only.
---

Do not do the planning yourself. Delegate entirely to the subagent.
EOF
fi
