---
name: feature-impl-plan
description: >-
  Break a feature into concrete tasks with dependency analysis, execution waves, subagent
  assignments (for large features), and a full test plan. Run this after /feature-plan whenever
  the user is ready to start building — even if they just say "let's break this down" or "what
  do I need to implement". If no feature name is given, uses the one currently being discussed.
argument-hint: [feature-name]
---

# Feature Implementation Plan Workflow

The user has invoked `/feature-impl-plan`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one
- Read `~/.claude/features/<name>/story.md` and `~/.claude/features/<name>/plan.md`
- If either file is missing, tell the user and stop

**If no argument is provided:**
- Infer from the current session conversation which feature is being discussed
- If unclear, scan `~/.claude/features/` for feature folders (exclude `done/`), list them, and ask the user to pick one
- Read its `story.md` and `plan.md`

Store the resolved `<name>` and the contents of both files.

**Ticket detection:** Scan `$ARGUMENTS`, `story.md`, and `plan.md` (in that order, stop at first match) for a ticket
number — one or more uppercase letters followed by a hyphen and digits (e.g. `SER-1234`, `PROJ-42`, `ABC-100`).
Store it as `<ticket>` if found, otherwise `<ticket>` is empty.

**Revision check:** Check whether `~/.claude/features/<name>/impl-plan.md` already exists. Store this as
`<is-revision>` (true/false). If true, the file will be rewritten — not appended — with a `## Revisions`
changelog at the bottom tracking what changed.

## Step 2 — Spawn planning subagents in parallel

Spawn **2 subagents in the same response** (`subagent_type: general-purpose`) and **wait for both to finish**
before continuing. Replace all `<name>` placeholders with the actual feature name.

Each subagent gathers its own context from the repository. Do not pre-gather context in the main agent.

Read `references/subagent-planner.md` and use it as the full prompt for **Subagent A — Implementation Planner**.

Read `references/subagent-test-planner.md` and use it as the full prompt for **Subagent B — Test Planner**.

## Step 3 — Synthesize into impl-plan.md

After both subagents have finished, read `impl-tasks.md` and synthesize the task breakdown into the
implementation plan. The test plan remains in its own file (`test-plan.md`).

`impl-tasks.md` is a working artifact retained for human inspection — downstream skills use `impl-plan.md`.

**Synthesis notes:**
- If `<ticket>` was detected, include the `## Branch Names` section with a row for every repo in scope.
  Pattern: `feature/<ticket>_short-description` (repo-specific kebab-case slug). If no ticket, omit entirely.
- For `## Subagent Assignments`: include the full breakdown if Subagent A assessed Large or Medium with
  clear parallel benefit. Otherwise write: `Single subagent recommended — follow execution waves above.`
- Carry any unresolved open questions from `impl-tasks.md` into the `## Open Questions` section.
- If `<is-revision>` is **true**, append a `## Revisions` section below `## Open Questions` listing
  what changed from the previous plan. Otherwise omit it.

### Format for impl-plan.md:

```md
# Implementation Plan: <Feature Title>

> Created: <today's date>

## Summary
[2–3 sentences: what is being built, the core technical approach, and the expected scope]

## Size Assessment
[Small / Medium / Large — one sentence explanation]

---

## Branch Names

**Ticket:** `<ticket>`

| Repo | Branch |
|------|--------|
| `repo-name` | `feature/<ticket>_short-description-for-this-repo` |

> Branch names follow the pattern `feature/<ticket>_short-description`. The short description is
> repo-specific — use a concise slug that reflects what changes in that repo (kebab-case, no spaces).

---

## Tasks

### T01 — <Title>
- [ ] Implemented
- [ ] Reviewed

**Area:** <area>
**Depends on:** none (or T0X, T0Y)
**Scope:** <2–4 sentences>

[All tasks in order — each task must include both checkboxes]

---

## Acceptance Criteria Coverage

| Criterion | Tasks |
|-----------|-------|
| <criterion text> | T01, T03 |

---

## Execution Plan

### Wave 1 — Run in parallel
| Task | Title | Notes |
|------|-------|-------|
| T01  | …     | …     |

[All waves]

### Critical Path
`T01 → T04 → T07 → T09`

---

## Subagent Assignments

[Subagent breakdown or single-subagent recommendation]

---

## Open Questions
[Unresolved items carried from plan.md or raised by task breakdown. Leave blank if none.]

## Revisions
[Only present if <is-revision> is true — list of changes from the previous plan]
```

## Step 4 — Spawn review subagent

After `impl-plan.md` has been written, spawn **1 subagent** (`subagent_type: general-purpose`) and
**wait for it to finish** before continuing. This reviews the **plan and task design** — not
implementation-level code quality (that is covered later by `/feature-code-review`).

Read `references/review-subagent.md` and use it as the full prompt, replacing `<name>` with the actual
feature name.

## Step 5 — Collect review findings and spawn fix subagent

Write the reviewer's full output to `~/.claude/features/<name>/impl-plan-review.md`:

```md
# Implementation Plan Review

> Reviewed: <today's date>

## Technical Feasibility and Task Design
[Findings]

## Security Design
[Findings]

## Architectural Fit and Design Patterns
[Findings]

## Test Plan Coverage
[Findings]

## Suggested Changes
[Consolidated list]
```

Then spawn a **foreground** fix subagent and **wait for it to finish**. Read `references/fix-subagent.md`
and use it as the full prompt, replacing `<name>` with the actual feature name.

## Step 6 — Report to the user

Tell the user the implementation plan is finished. Show the feature folder path and the files written:
- `impl-plan.md` — the implementation plan
- `impl-plan-review.md` — the raw review findings
- `test-plan.md` — the test plan
- `impl-tasks.md` — the working task breakdown artifact

Give a brief summary:
- Number of tasks and execution waves (maximum parallelism per wave)
- Critical path
- Whether subagent split is recommended
- Acceptance criteria coverage (all covered / any gaps)
- Review findings: how many applied vs. rejected, any CRITICAL findings not applied
- Open questions that need answers before starting implementation

Then prompt: _"Next step: run `/feature-implement` to execute the tasks from this plan."_

## Rules

- Never invent tasks not grounded in the story and plan
- Task IDs must be stable — T01, T02, … in order of logical appearance — because
  `feature-implement` and `feature-done` reference tasks by ID; renumbering mid-flight breaks progress tracking
- Every task must have a clear done state
- Every acceptance criterion must map to at least one task and at least one E2E test
- Subagent assignments are only recommended when they reduce total wall-clock time — do not recommend
  them just because a feature is moderately complex
- All files are written under `~/.claude/features/<name>/`
- If a ticket number is detected, the `## Branch Names` section is mandatory. Every repo touched by
  the feature gets its own row. Short descriptions must differ per repo to reflect that repo's
  specific changes
