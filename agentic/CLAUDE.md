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

### Git worktrees

Features use **git worktrees** so the user can keep working on the main branch
while an agent (or another session) implements a feature in an isolated working
tree. Each worktree is a sibling directory of the original repo, visible to the
sessionizer as a separate tmux session.

#### Naming convention

Worktrees live as siblings of the original repo directory, named
`<repo>--<feature-name>`:

```
~/Developer/work/
  my-app/                       # main branch (original repo)
  my-app--user-avatar-upload/   # worktree for feature/user-avatar-upload
```

The `--` delimiter separates the repo name from the feature name. The
sessionizer picks up each worktree as a distinct fzf entry and tmux session.

#### story.md metadata

When worktrees are created, `story.md` records them:

```md
> Working directory: /Users/tobias/Developer/work/my-app--user-avatar-upload
> Worktree: true
> Worktree source: /Users/tobias/Developer/work/my-app
> Branch: feature/user-avatar-upload
```

- `> Worktree: true` signals downstream skills that the working directory is a
  worktree (skip branch creation — the worktree already has its branch).
- `> Worktree source:` is the path to the original repo (needed for cleanup).

If multiple repos have worktrees, `story.md` also contains a `## Worktrees`
table listing every worktree path, source repo, and branch. `/feature-done`
reads this table to clean up all worktrees.

#### Lifecycle

- `/feature-plan` **creates** worktrees after the plan is finalized
  (Step 8b). Worktrees are created by default for all repos involved in the
  feature. To skip worktree creation, the user must explicitly request no
  worktrees in the initial prompt.
- `/feature-implement`, `/tasker`, and `/ralph` detect `> Worktree: true` in
  `story.md` and **skip branch creation** — the worktree is already on the
  correct branch.
- `/feature-done` **cleans up** the worktree after archiving: removes the git
  worktree, deletes the directory, prunes stale worktree refs, and kills the
  associated tmux session if one exists.

#### Detection

To check if the current working directory is inside a worktree:

```sh
git rev-parse --is-inside-work-tree &>/dev/null \
  && [ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ]
```

If this returns true, the directory is a worktree (not the main repo).

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
