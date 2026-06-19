# Claude Code hooks

Backup copies of the hook scripts wired into [`../settings.json`](../settings.json) under
`hooks.PreToolUse`. They run at the Claude Code harness level (the harness executes them, not the
model), so they enforce behavior the model can't be relied on to remember.

## Why these are copies, not symlinks

`settings.json` references each hook by **absolute path** (`/Users/tobias/.claude/hooks/<name>`), and
the live scripts live in `~/.claude/hooks/`, which is a plain directory — `symlinks.sh` does not link
it. These files are **backup copies for version control only**; nothing reads them from here at
runtime. Edit the live script in `~/.claude/hooks/`, then re-copy it here to refresh the backup
(there is no symlink keeping them in sync, so they can drift — see "Updating a backup" below).

## Hooks

| Script | Event · matcher | What it does |
|---|---|---|
| `guard-piped-exit-code.py` | `PreToolUse` · `Bash` | Blocks a test/build runner piped into a pager (`pytest \| tail`, `\| head`, `\| grep`), which masks the runner's exit code behind the pager's so a failing suite looks green. Allows it only when the command guards the exit code (`$PIPESTATUS` / `set -o pipefail`) or avoids the pipe. **Blocking** (exit 2). |
| `remind-batch-images.sh` | `PreToolUse` · `Read\|SendUserFile` | When the tool targets image file(s) (png/jpg/jpeg/gif/webp/heic), injects a model-facing reminder to batch all related screenshots/images into **one** message — multiple `Read`s in a single turn, or one `SendUserFile` with every file in `files[]` — so they render as a swipeable gallery. **Non-blocking**: never prevents the call, exits 0 even on malformed input or missing `jq` (falls back to a grep over raw stdin). |

## Restore on a new machine

The scripts are not auto-installed. After cloning dotfiles, copy them into place and mark executable:

```sh
mkdir -p ~/.claude/hooks
cp ~/dotfiles/agentic/hooks/*.py ~/dotfiles/agentic/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.py ~/.claude/hooks/*.sh
```

(The `README.md` is skipped by the glob.) `settings.json` is symlinked by `symlinks.sh`, so the hook
wiring is already in place once the scripts exist at those paths.

## Updating a backup

After editing a live hook in `~/.claude/hooks/`, refresh the copy here so the backup doesn't go stale:

```sh
cp -p ~/.claude/hooks/<name> ~/dotfiles/agentic/hooks/
```
