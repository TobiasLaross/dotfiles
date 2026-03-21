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

Features are tracked in `~/.claude/features/`. The folder and all files are created by `/feature-plan` — do not create feature folders manually. When the user runs `/feature-plan`, that skill handles naming, folder creation, planning, and review.

If a feature folder already exists, you may read its files to resume context across sessions.

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder

### Work repos

When working inside a `/work/` directory, related repositories live in `~/Developer/work/`. Scan that directory to identify which repos are relevant to a given task or feature.

Pre-built context files for each repo live at `~/.claude/repo-context/<repo-name>.md`. When they exist, read them before reading source code — they contain purpose, architecture, inter-repo dependencies, external communication protocols, and canonical design patterns. Fall back to reading source only when context files are missing or insufficient.
