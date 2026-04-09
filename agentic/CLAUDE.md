# Global Claude Instructions

## Feature Tracking

Features are tracked in `~/.claude/features/`. The folder and all files are created by
`/feature-plan` — do not create feature folders manually. When the user runs the skill,
it handles naming, folder creation, planning, and review.

### Three flows

- **Ralph** (`/ralph` → `ralph <name>`): Shell-loop flow. `/ralph` creates the PRD
  (user story + tasks) interactively with user sign-off. Then `ralph <name>` runs
  `claude -p` in a loop — one task per context window, progress tracked in files.
  Final iteration reviews the entire PR and adds fix tasks if needed. Resumable at
  any point. Best for autonomous implementation with minimal token waste.
- **Orchestra** (`/orchestra`): Single orchestrator that runs the full lifecycle in one
  continuous session. Works for bugfixes, features, and entire tools. Delegates all heavy
  work to subagents. Scope-adaptive: light planning for bugfixes, iterative discovery Q&A
  for tools. Resumable from any state via `state.md`. Best for any scope.
- **Feature flow** (`/feature-plan` → `/feature-implement` → review → fix → done):
  Drafts a user story with acceptance criteria, generates a high-level plan, then implements
  directly from the plan. Tracks progress via acceptance criteria checkboxes in `story.md`.
  Best for small to medium features.

If a feature folder already exists, you may read its files to resume context across sessions.

### Ralph lifecycle

Ralph implementations are tracked in `~/.claude/ralph/`:
- Active implementations live in `~/.claude/ralph/<name>/`
- Completed implementations move to `~/.claude/ralph/done/<name>/`
- Each folder contains: `story.md`, `tasks.md`, `progress.md`, `RALPH.md`,
  and optionally `test-output.log` and `review.md`

### Implementation lifecycle

Orchestra implementations are tracked in `~/.agentic/implementations/`:
- Active implementations live in `~/.agentic/implementations/<name>/`
- Completed implementations move to `~/.agentic/implementations/done/<name>/`
- Each implementation folder contains: `state.md`, `story.md`, `plan.md`, and a `context/`
  directory with repo context and phase results

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder

### Work repos

When working inside a `/work/` directory, related repositories live in `~/Developer/work/`. Scan that directory to identify which repos are relevant to a given task or feature.

Pre-built context files for each repo live at `~/.claude/repo-context/<repo-name>.md`. When they exist, read them before reading source code — they contain purpose, architecture, inter-repo dependencies, external communication protocols, and canonical design patterns. Fall back to reading source only when context files are missing or insufficient.

### Markdown files

When writing markdown files, make sure that lines are not longer than 140 characters without trailing white-spaces.
