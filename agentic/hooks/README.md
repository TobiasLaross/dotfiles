# Claude Code hooks

Hook scripts wired into [`../settings.json`](../settings.json) under `hooks.PreToolUse`. They run at the Claude Code harness level (the harness executes them, not the
model), so they enforce behavior the model can't be relied on to remember.

## How they are installed

`settings.json` references each hook by **absolute path** (`/Users/tobias/.claude/hooks/<name>`).
`symlinks.sh` links every `*.py` and `*.sh` file in this folder into `~/.claude/hooks/` and removes
links whose target is gone, so this folder is the source of truth: edit the scripts here.

## Hooks

| Script | Event · matcher | What it does |
|---|---|---|
| `guard-piped-exit-code.py` | `PreToolUse` · `Bash` | Blocks a test/build runner piped into a pager (`pytest \| tail`, `\| head`, `\| grep`), which masks the runner's exit code behind the pager's so a failing suite looks green. Allows it only when the command guards the exit code (`$PIPESTATUS` / `set -o pipefail`) or avoids the pipe. **Blocking** (exit 2). |
| `remind-batch-images.sh` | `PreToolUse` · `Read\|SendUserFile` | When the tool targets image file(s) (png/jpg/jpeg/gif/webp/heic), injects a model-facing reminder to batch all related screenshots/images into **one** message — multiple `Read`s in a single turn, or one `SendUserFile` with every file in `files[]` — so they render as a swipeable gallery. **Non-blocking**: never prevents the call, exits 0 even on malformed input or missing `jq` (falls back to a grep over raw stdin). |
| `run-local-hooks.sh` | `PreToolUse` · `Bash` | Runs every executable in `~/.claude/hooks-local/pretooluse-bash/`, so hooks that only belong on one machine never appear in the shared `settings.json`. The first local hook that prints output or exits non-zero wins and its result is passed through. No directory means no-op. |

## Machine-local hooks

Hooks that only make sense on one machine live in `~/.claude/hooks-local/<group>/` and are neither referenced
from `settings.json` nor backed up here. `run-local-hooks.sh <group>` picks them up. To add one, drop an
executable script into the group directory (e.g. `~/.claude/hooks-local/pretooluse-bash/`).
