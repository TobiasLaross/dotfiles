# Global Claude Instructions

## Feature Tracking

Features are tracked in `~/.claude/features/`. The folder and all files are created by `/feature-plan`
or `/feature-plan-lite` — do not create feature folders manually. When the user runs either skill,
it handles naming, folder creation, planning, and review.

### Two flows

- **Full flow** (`/feature-plan` → `/feature-impl-plan` → `/feature-implement` → review → fix → done):
  Detailed task breakdown with execution waves, test plan, and subagent assignments. Best for
  large or complex features.
- **Lite flow** (`/feature-plan-lite` → `/feature-implement-lite` → review-lite → fix-lite → done-lite):
  Skips the impl-plan step. The implementation agent reads the high-level plan directly and uses
  its own judgment. Tracks progress via acceptance criteria checkboxes in `story.md` instead of
  task checkboxes in `impl-plan.md`. Best for small to medium features.

If a feature folder already exists, you may read its files to resume context across sessions.

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder

### Work repos

When working inside a `/work/` directory, related repositories live in `~/Developer/work/`. Scan that directory to identify which repos are relevant to a given task or feature.

Pre-built context files for each repo live at `~/.claude/repo-context/<repo-name>.md`. When they exist, read them before reading source code — they contain purpose, architecture, inter-repo dependencies, external communication protocols, and canonical design patterns. Fall back to reading source only when context files are missing or insufficient.

### Markdown files

When writing markdown files, make sure that lines are not longer than 140 characters without trailing white-spaces.
