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
before continuing. Replace all placeholders with the actual feature name.

Each subagent gathers its own context from the repository. Do not pre-gather context in the main agent.

---

**Subagent A — Implementation Planner:**

```
You are creating a detailed, low-level implementation task breakdown for a feature.

Feature folder: ~/.claude/features/<name>/

Read the following files to understand the goal and approach:
- ~/.claude/features/<name>/story.md  (includes user story and acceptance criteria)
- ~/.claude/features/<name>/plan.md   (includes design decisions, phases, open questions)

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml, go.mod,
   or equivalent. Fall back to scanning file extensions.
2. Get the project structure: run `git ls-files | head -100`
3. Check ~/.claude/repo-context/<repo-name>.md for each relevant repo and read the architecture and
   design patterns sections.

## Acceptance criteria coverage

Read the "## Acceptance Criteria" section from story.md. For each criterion, identify which task(s) will
directly produce the observable outcome that criterion requires. No criterion may be left uncovered.

## Task decomposition

Break the feature into the smallest atomic tasks that can each be independently implemented and verified.
A task should be completable in one focused coding session (roughly 30–90 minutes of work). Tasks that are
too large must be split further.

For each task write:
- **ID**: T01, T02, T03, … (sequential)
- **Title**: short imperative phrase (e.g. "Add user model migration")
- **Scope**: 2–4 sentences describing exactly what needs to be done, which files/modules will change,
  and what the done state looks like
- **Depends on**: list of task IDs that must be complete before this one can start (empty if none)
- **Area**: the technical area (e.g. database, API, frontend, auth, config, tests)

Cover all layers: setup, data layer, business logic, API layer, UI (if applicable), integration glue,
and cleanup.

## Dependency and parallelism analysis

1. Build a dependency graph and identify execution waves — groups of tasks with no interdependencies
   that can run in parallel.
   - Wave 1: tasks with no dependencies
   - Wave N: tasks whose dependencies are all in previous waves
2. Identify the critical path — the longest sequential chain from start to finish.
3. Flag any dependency corrections you made (where a declared-independent task actually requires
   another task's output).

## Size and subagent assessment

Assess the overall size:
- **Small** (≤5 tasks, single area): single subagent, follow execution waves
- **Medium** (6–12 tasks, 2–3 areas): single subagent is fine; parallel subagents optional
- **Large** (13+ tasks, 4+ areas, or spans multiple repos): split across dedicated subagents

If Large (or Medium with clear parallel benefit), propose subagent assignments. Group tasks by cohesion.
For each subagent:
- **Name**: short descriptive label
- **Tasks**: task IDs owned
- **Responsibility**: 1–2 sentences
- **Inputs needed from other subagents**
- **Outputs it produces**

If Small or Medium (single subagent), state this clearly.

## Open questions

Read the "## Open Questions" section from plan.md. For each item, note whether the task breakdown
resolves it or whether it must still be answered before implementation starts. Carry unresolved items
forward.

## Output

Write to ~/.claude/features/<name>/impl-tasks.md using these sections:
- Task Breakdown (all tasks with ID, title, scope, depends on, area)
- Acceptance Criteria Coverage (table: criterion → task IDs)
- Dependency and Parallelism Analysis (waves, critical path)
- Size and Subagent Assessment
- Open Questions (unresolved items from plan.md, or "None")

Lines must not exceed 140 characters.
```

---

**Subagent B — Test Planner:**

```
You are writing a detailed, low-level test plan for a feature implementation.

Note: you are running in parallel with the task breakdown subagent, so impl-tasks.md does not exist
yet. Write tests at the feature/component level. The reviewer will cross-reference coverage against
the final task list.

Feature folder: ~/.claude/features/<name>/

Read the following files to understand the goal and approach:
- ~/.claude/features/<name>/story.md  (includes user story and acceptance criteria)
- ~/.claude/features/<name>/plan.md   (includes design decisions and phases)

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml,
   go.mod, or equivalent. Fall back to scanning file extensions.
2. Get the project structure: run `git ls-files | head -100`
3. Look for existing test files to understand the project's testing conventions (location, naming,
   patterns, mock style).
4. Check ~/.claude/repo-context/<repo-name>.md for each relevant repo and read the testing conventions
   section if present.

## Acceptance criteria coverage

Read the "## Acceptance Criteria" section from story.md. Every criterion must be covered by at least
one E2E/acceptance test. List each criterion as a row in the coverage table at the end of the output.

## Test plan

Produce a comprehensive test plan covering all layers. Structure your output in three sections:

### Unit Tests
For each unit test:
- **What it tests**: specific function, method, or component
- **Setup / input**: the initial state or inputs required
- **Expected outcome**: what must be true after the test runs
- **Why it matters**: what bug or regression it catches

### Integration Tests
For each integration test:
- **What it tests**: the interaction between two or more components or layers
- **Setup**: data seeding, stubs, or environment required
- **Steps**: the actions to perform
- **Expected outcome**: what the system state must be
- **Why it matters**: what failure mode it catches

### End-to-End / Acceptance Tests
For each E2E test:
- **Scenario**: the user action being tested
- **Steps**: exact sequence of actions
- **Expected outcome**: what the user sees or the system produces
- **Acceptance criterion covered**: the specific criterion from story.md this validates

Include edge cases: empty states, validation errors, concurrent access, permission boundaries.
Do not skip a layer unless the tech stack genuinely has no equivalent.

End with an **Acceptance Criteria Coverage** table:
| Criterion | Test(s) |
|-----------|---------|

## Output

Write the full test plan to ~/.claude/features/<name>/test-plan.md
Lines must not exceed 140 characters.
```

---

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

```
You are reviewing a low-level implementation plan. You have access to the filesystem.

Story:     ~/.claude/features/<name>/story.md
Impl plan: ~/.claude/features/<name>/impl-plan.md
Test plan: ~/.claude/features/<name>/test-plan.md

Read all three files.

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite task IDs.

## 1. Technical Feasibility and Task Design

- Missing or incorrect task dependencies
- Wrong assumptions about APIs, libraries, or system capabilities
- Implementation gaps — steps that skip over non-trivial work
- Tasks that are technically unsound or will not work as described
- Task scopes that are too vague to execute without guessing
- Tasks that are too large and should be split further
- Dependency graph errors — tasks that claim independence but actually depend on each other
- Missing tasks — work implied by other tasks but not explicitly listed

## 2. Security Design

Focus on design-level concerns only (implementation-level security is caught during code review):
- Authentication and authorisation gaps in the planned architecture
- Missing security-relevant tasks (e.g. no task for input validation, no task for access control)
- Data flow risks — sensitive data passing through layers without planned protection
- Missing threat considerations for the feature's attack surface
- Insecure design patterns chosen in the task scopes

## 3. Architectural Fit and Design Patterns

- Does the planned task structure respect the existing architecture (layer boundaries, module
  responsibilities)?
- Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the design patterns
  section — use it as the source of truth for what patterns new code must follow.
- Use Glob and Grep to find 2–3 existing features similar to what this plan describes.
- Flag tasks where the plan would introduce a different design pattern than the rest of the codebase.
- Are there planned abstractions or structures that conflict with how the codebase is organized?
Do NOT flag implementation-level maintainability concerns — those are caught during code review.

## 4. Test Plan Coverage

- Does every acceptance criterion in story.md have corresponding E2E test coverage?
- Does every task with user-facing or logic-heavy scope have corresponding test coverage?
- Does the test plan cover all happy paths?
- Are edge cases, error states, and boundary conditions covered?
- Are there tasks that introduce new integrations or data flows with no integration test?

## Output format

Structure your output under the four headings above. End with a **Suggested Changes** section:
a consolidated, deduplicated list of actionable changes with severity and the area they come from.
```

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

Then spawn a **foreground** fix subagent and **wait for it to finish**.

```
You are revising a low-level implementation plan based on a review.

Plan:    ~/.claude/features/<name>/impl-plan.md
Story:   ~/.claude/features/<name>/story.md
Review:  ~/.claude/features/<name>/impl-plan-review.md

Read all three files. Then:

1. For each item under "Suggested Changes" in the review, decide whether it is valid and improves the
   plan. Apply changes that are clearly correct. Skip anything speculative, contradictory, or that
   re-litigates high-level design decisions already settled in story.md.
2. Rewrite ~/.claude/features/<name>/impl-plan.md with all accepted changes applied. Keep the same
   structure and format. Add `> Last revised: <today's date>` below the Created line.
   Lines must not exceed 140 characters.
3. Append an `## Implementation Plan Review` section at the bottom with a changelog table:

| Finding | Area | Severity | Decision | Rationale |
|---------|------|----------|----------|-----------|
| [brief description] | Feasibility/Security/Architecture/Tests | CRITICAL/HIGH/LOW | Applied/Rejected | [why] |

4. If any CRITICAL finding was Rejected, add a warning block immediately after the table:

> ⚠️ **CRITICAL finding not applied:** [finding description] — the user must consciously acknowledge
> this risk before starting implementation.
```

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
