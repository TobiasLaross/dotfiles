# Claude Workflow

This document describes the full Claude Code workflow defined in this dotfiles repo. It covers story tracking, the plan → review → implement → review cycle, hooks, and skills.

---

## Overview

The workflow enforces a structured loop:

```
/feature <description>
       ↓
Story drafted + approved
       ↓
Story file created in ~/.claude/stories/<name>/
       ↓
Plan drafted
       ↓
  <!-- review:plan --> appended
       ↓
Stop hook fires → auto-review.sh → triggers /review-plan
       ↓
Plan updated with findings
       ↓
Implementation begins
       ↓
  <!-- review:code --> appended
       ↓
Stop hook fires → auto-review.sh → triggers /review-code
       ↓
Fixes applied, changelog produced
       ↓
Committed → story moved to done/
```

---

## Feature Tracking

**Location:** `~/.claude/stories/<kebab-name>/story.md` (gitignored — local only)

A story is created before starting any significant work and updated as stages complete. It serves as resume context across sessions.

Use `/feature <description>` to start the flow — Claude drafts a user story for approval before writing any files.

### Story lifecycle

- Active stories live in `~/.claude/stories/<name>/`
- Completed stories move to `~/.claude/stories/done/<name>/`
- All related md files for a story go in its folder

### When to create a story

- Any change spanning multiple sessions
- Refactors or architectural changes
- New features or tools being added

### Format

```md
# Story: <Name>

**As a** [user type], **I want** [goal] **so that** [reason]

## Status: todo | in-progress | done

## Checkpoints
- [ ] Plan drafted
- [ ] Plan reviewed
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Code reviewed
- [ ] Committed

## Notes
```

---

## Auto-Review Markers

Two HTML comment markers trigger automatic reviews when appended to a response:

| Marker | When to use | Effect |
|--------|-------------|--------|
| `<!-- review:plan -->` | End of a complete implementation plan | Triggers `/review-plan` skill |
| `<!-- review:code -->` | End of a completed implementation | Triggers `/review-code` skill |

### How they work

1. Claude appends a marker at the end of a response
2. The Claude Code session ends (Stop event fires)
3. `auto-review.sh` runs as a Stop hook
4. The hook reads the session transcript, finds the last assistant message, and checks for markers
5. If a marker is found, the hook outputs a prompt instructing Claude to run the appropriate skill
6. Claude runs the skill automatically in the next turn

---

## Hooks

### Stop hook — `auto-review.sh`

**Location:** `claude/hooks/auto-review.sh` → symlinked to `~/.claude/hooks/auto-review.sh`

**Trigger:** Runs after every Claude Code session stop event.

**What it does:**

1. Reads the Stop hook input JSON from stdin
2. Extracts the `transcript_path` from the JSON
3. Reads the last 20 lines of the transcript file
4. Parses each line as JSON, finds the last `assistant` role message
5. Extracts the text content from the message
6. Checks for `<!-- review:plan -->` or `<!-- review:code -->` in the text
7. If found, outputs a prompt telling Claude to run the matching skill

**Output:**

- `"Run the review-plan skill on the plan above."` — when `<!-- review:plan -->` detected
- `"Run the review-code skill on the files above."` — when `<!-- review:code -->` detected
- Nothing (exit 0) — when no marker found or transcript unreadable

---

## Settings

**Location:** `claude/settings.json` → symlinked to `~/.claude/settings.json`

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/auto-review.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Skills

Skills live in `claude/skills/*/` and are symlinked individually into `~/.claude/skills/`.

### `/feature` — Feature

**File:** `claude/skills/feature/SKILL.md`

Creates a new feature story from a description.

**Step 1 — Draft**
From `$ARGUMENTS`, draft a kebab-case folder name and a user story (`As a… I want… so that…`). Present to user for approval.

**Step 2 — Create**
Once approved, write `~/.claude/stories/<name>/story.md` with the agreed story and today's date.

**Step 3 — Plan**
Spawns a background planning subagent that reads the story, scans repos in `~/Developer/work/` (if in `/work/` context) by reading their code, and writes `plan.md`.

**Step 4 — Review**
The planning subagent spawns a review subagent that reads `story.md` and `plan.md`, re-examines repo code, and writes `plan-review.md` with verdict and suggested changes.

---

### `/review-plan`

**File:** `claude/skills/review-plan/SKILL.md`

Reviews an implementation plan before any code is written. Runs 6 sub-agents in parallel.

**Step 1 — Gather context**
- Extract the plan from `$ARGUMENTS` or conversation
- Detect tech stack (package.json, pyproject.toml, Cargo.toml, etc.)
- Detect base branch via `git symbolic-ref`
- Get project structure via `git ls-files | head -80`

**Step 2 — 6 parallel agents**

| Agent | Focus |
|-------|-------|
| Technical Feasibility | Wrong dependencies, impossible steps, API misuse |
| Security | Auth gaps, injection risks, sensitive data exposure, missing validation |
| Performance & Scalability | N+1 queries, missing indexes, blocking ops, resource leaks |
| Maintainability & Architecture | Coupling, testability, over-engineering, naming |
| Test Coverage | Defines required main flow tests and edge case tests |
| Design Pattern Consistency | Finds similar existing features, flags deviations from established patterns |

**Step 3 — Synthesize**
Produces a `## Plan Review` section with severity-flagged findings per dimension and an overall assessment.

**Severity flags:**
- `CRITICAL` — blocks success or causes serious harm; must fix before implementation
- `HIGH` — significant concern; address before or early in implementation
- `LOW` — minor; can address later

**Step 4 — Update the plan**
Applies or rejects each finding with rationale, then presents the full updated plan and a changelog table. CRITICAL rejections are called out explicitly.

---

### `/review-code`

**File:** `claude/skills/review-code/SKILL.md`

Reviews implemented code after changes are complete. Runs 7 sub-agents in parallel.

**Step 1 — Gather context**
- Changed files: `git diff $(git merge-base HEAD <base>) --name-only`
- Full diff: `git diff $(git merge-base HEAD <base>)`
- Base branch: `git symbolic-ref refs/remotes/origin/HEAD`
- Read all changed source and test files in full
- Tech stack from manifest files
- Project structure: `git ls-files | head -80`
- Original requirements from conversation context

**Step 2 — 7 parallel agents**

| Agent | Focus |
|-------|-------|
| Correctness | Logic errors, off-by-one, null checks, wrong return values, broken control flow |
| Security | Injection, broken auth, hardcoded secrets, OWASP Top 10 |
| Performance & Scalability | N+1, missing indexes, unnecessary loops, memory leaks, missing pagination |
| Maintainability & Architecture | Functions doing too much, duplication, magic numbers, tight coupling |
| Test Quality | Missing edge cases, false-confidence tests, missing main flow coverage |
| Acceptance Criteria | Verifies each original requirement is fully, partially, or not covered |
| Design Pattern Consistency | Finds similar existing features, flags deviations from established patterns |

**Step 3 — Synthesize**
Produces a `## Code Review` section with severity-flagged findings per dimension and an overall assessment with explicit "must fix before merging" list.

**Severity flags:**
- `CRITICAL` — correctness, security, or data integrity risk; must fix before merging
- `HIGH` — significant concern; fix before or shortly after merging
- `LOW` — code quality or minor improvement

**Step 4 — Apply fixes**
Goes through every finding and either applies it (via Edit tool or writes the missing test) or rejects it with explicit rationale. After applying:
1. Spawns a follow-up agent to re-review each CRITICAL fix
2. Writes all accepted missing tests
3. Presents a changelog table

CRITICAL rejections are called out explicitly with a warning.

---

### `/explain-code`

**File:** `claude/skills/explain-code/SKILL.md`

Explains how code works using a consistent structure:

1. **Analogy** — compare to something from everyday life
2. **Diagram** — ASCII art showing flow, structure, or relationships
3. **Walkthrough** — step-by-step explanation of what happens
4. **Gotcha** — a common mistake or misconception

---

## Symlinks

`symlinks.sh` wires everything into `~/.claude/`:

```sh
~/.claude/skills/<skill>/   → dotfiles/claude/skills/<skill>/
~/.claude/hooks/            → dotfiles/claude/hooks/*
~/.claude/stories/          → local only, created on first /feature run
~/.claude/CLAUDE.md         → dotfiles/claude/CLAUDE.md
~/.claude/settings.json     → dotfiles/claude/settings.json
```

---

## File Map

```
claude/
├── CLAUDE.md              # Global instructions (story tracking + auto-review markers)
├── WORKFLOW.md            # This file
├── settings.json          # Hook registration
├── hooks/
│   └── auto-review.sh     # Stop hook — detects markers, triggers skill prompts
└── skills/
    ├── feature/
    │   └── SKILL.md       # /feature — draft + approve + create story file
    ├── review-plan/
    │   └── SKILL.md       # 6-agent parallel plan review
    ├── review-code/
    │   └── SKILL.md       # 7-agent parallel code review
    └── explain-code/
        └── SKILL.md       # Analogy + diagram + walkthrough + gotcha
```
