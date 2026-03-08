#!/bin/zsh

input=$(cat)

transcript=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript_path', ''))
except:
    pass
" 2>/dev/null)

[[ -z "$transcript" || ! -f "$transcript" ]] && exit 0

last=$(tail -1 "$transcript" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Handle both flat and nested message formats
    msg = d.get('message', d)
    if msg.get('role') != 'assistant':
        sys.exit(1)
    content = msg.get('content', '')
    if isinstance(content, list):
        text = ' '.join(
            c.get('text', '') for c in content
            if isinstance(c, dict) and c.get('type') == 'text'
        )
    else:
        text = str(content)
    print(text)
except:
    sys.exit(1)
" 2>/dev/null)

[[ -z "$last" ]] && exit 0

if echo "$last" | grep -q "<!-- review:plan -->"; then
    echo "Run the review-plan skill on the plan above."
elif echo "$last" | grep -q "<!-- review:code -->"; then
    echo "Run the review-code skill on the files above."
fi
