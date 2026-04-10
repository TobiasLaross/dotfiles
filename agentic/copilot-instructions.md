---
tools:
  allow:
    - Bash(find:*)
    - Bash(grep:*)
    - Bash(ls:*)
    - Bash(cat:*)
    - Bash(head:*)
    - Bash(tail:*)
    - Bash(wc:*)
    - Bash(sed:*)
    - Bash(awk:*)
    - Bash(sort:*)
    - Bash(uniq:*)
    - Bash(diff:*)
    - Bash(git:*)
    - Bash(brew:*)
    - Bash(npm:*)
    - Bash(node:*)
    - Bash(python:*)
    - Bash(pip:*)
    - Bash(go:*)
    - Bash(cargo:*)
    - Bash(swift:*)
    - Bash(xcodebuild:*)
    - Bash(make:*)
    - Bash(mkdir:*)
    - Bash(cp:*)
    - Bash(mv:*)
    - Bash(rm:*)
    - Bash(ln:*)
    - Bash(chmod:*)
    - Bash(curl:*)
    - Bash(tar:*)
    - Bash(unzip:*)
---

# Global Claude Instructions

## Feature Tracking

Features are tracked in `~/.claude/features/`. The folder and all files are created by
`/feature-plan` — do not create feature folders manually. When the user runs the skill,
it handles naming, folder creation, discovery, planning, and review.

### Three implementation flows

All flows start with `/feature-plan`, which creates the story, runs discovery Q&A,
drafts acceptance criteria with user sign-off, and generates a reviewed plan. After
planning, the user chooses an implementation path:

- **Tasker** (`/feature-plan` → `/tasker`): Autonomous task loop. `/tasker` decomposes
  the plan into behavior-level tasks and launches `tasker.sh`, which runs `claude -p`
  in a loop — one task per context window, progress tracked in files. Final iteration
  reviews the entire diff and adds fix tasks if needed. Resumable at any point. Best
  for structured autonomous implementation.
- **Ralph** (`/feature-plan` → `/ralph`): True Ralph Wiggum loop. Same prompt piped to
  the agent every iteration. The agent sees its previous work through the filesystem
  and decides what to do next. No pre-decomposed tasks. Best for greenfield work where
  the agent should have full autonomy.
- **Feature flow** (`/feature-plan` → `/feature-implement` → review → fix → done):
  Interactive implementation in a single session. The agent reads the plan and implements
  using its own judgment for task ordering. Tracks progress via acceptance criteria
  checkboxes in `story.md`. Best for hands-on implementation where the user wants to
  guide decisions.

### Shared planning

`/feature-plan` is the single entry point for all flows. It produces:
- `story.md` — user story, discovery decisions, acceptance criteria
  (with `Implemented`/`Reviewed` tracking)
- `plan.md` — reviewed high-level plan with design decisions and implementation phases
- `plan-review.md` — review findings (for human inspection only)

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder
- Tasker loop files (`tasks.md`, `TASKER.md`, `progress.md`) also live in the
  feature folder
- Ralph loop files (`PROMPT.md`) also live in the feature folder

If a feature folder already exists, you may read its files to resume context across
sessions.

### Work repos

When working inside a `/work/` directory, related repositories live in
`~/Developer/work/`. Scan that directory to identify which repos are relevant to a
given task or feature.

Pre-built context files for each repo live at
`~/.claude/repo-context/<repo-name>.md`. When they exist, read them before reading
source code — they contain purpose, architecture, inter-repo dependencies, external
communication protocols, and canonical design patterns. Fall back to reading source
only when context files are missing or insufficient.

### Markdown files

When writing markdown files, make sure that lines are not longer than 140 characters
without trailing white-spaces.
