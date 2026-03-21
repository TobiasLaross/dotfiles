---
name: feature-impl-plan
description: Create a detailed implementation plan for a feature, breaking it into tasks with dependency analysis, parallel execution groups, subagent assignments (for large features), and per-task test details. Use when the user runs /feature-impl-plan with an optional feature name. If no argument is given, uses the feature currently discussed in the session.
argument-hint: [feature-name]
---

# Feature Implementation Plan Workflow

The user has invoked `/feature-impl-plan`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- Read `~/.claude/features/<name>/story.md` and `~/.claude/features/<name>/plan.md`
- If either file is missing, tell the user and stop

**If no argument is provided:**
- Scan `~/.claude/features/` for feature folders (exclude `done/`)
- Identify the most recently modified folder or infer from the current session conversation which feature is being discussed
- Read its `story.md` and `plan.md`
- If you cannot determine the feature, list available features under `~/.claude/features/` and ask the user to pick one

Store the resolved `<name>` and the contents of both files.

**Ticket detection:** Scan `$ARGUMENTS`, `story.md`, and `plan.md` (in that order, stop at first match) for a ticket number — one or more uppercase letters followed by a hyphen and digits (e.g. `SER-1234`, `PROJ-42`, `ABC-100`). Store it as `<ticket>` if found, otherwise `<ticket>` is empty.

**File existence check:** Check whether `~/.claude/features/<name>/impl-plan.md` already exists. Store this as `<is-revision>` (true/false).

## Step 2 — Spawn planning subagents in parallel

Spawn **2 subagents in the same response** (`subagent_type: general-purpose`) and **wait for both to finish** before continuing. Replace all placeholders with the actual feature name and file contents from Step 1.

Each subagent gathers its own context from the repository. Do not pre-gather context in the main agent.

---

**Subagent A — Implementation Planner:**

```
You are creating a detailed, low-level implementation task breakdown for a feature.

Feature folder: ~/.claude/features/<name>/

Read the following files to understand the goal and approach:
- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml, go.mod, or equivalent. Fall back to scanning file extensions.
2. Get the project structure: run `git ls-files | head -100`
3. Check ~/.claude/repo-context/<repo-name>.md for each relevant repo and read the architecture and design patterns sections.

## Task decomposition

Break the feature into the smallest atomic tasks that can each be independently implemented and verified. A task should be completable in one focused coding session (roughly 30–90 minutes of work). Tasks that are too large must be split further.

For each task write:
- **ID**: T01, T02, T03, … (sequential)
- **Title**: short imperative phrase (e.g. "Add user model migration")
- **Scope**: 2–4 sentences describing exactly what needs to be done, which files/modules will change, and what the done state looks like
- **Depends on**: list of task IDs that must be complete before this one can start (empty if none)
- **Area**: the technical area (e.g. database, API, frontend, auth, config, tests)

Cover all layers: setup, data layer, business logic, API layer, UI (if applicable), integration glue, and cleanup.

## Dependency and parallelism analysis

1. Build a dependency graph and identify execution waves — groups of tasks with no interdependencies that can run in parallel.
   - Wave 1: tasks with no dependencies
   - Wave N: tasks whose dependencies are all in previous waves
2. Identify the critical path — the longest sequential chain from start to finish.
3. Flag any dependency corrections you made (where a declared-independent task actually requires another task's output).

## Size and subagent assessment

Assess the overall size:
- **Small** (≤5 tasks, single area): single subagent, follow execution waves
- **Medium** (6–12 tasks, 2–3 areas): single subagent is fine; parallel subagents optional
- **Large** (13+ tasks, 4+ areas, or spans multiple repos): split across dedicated subagents

If Large (or Medium with clear parallel benefit), propose subagent assignments. Group tasks by cohesion. For each subagent:
- **Name**: short descriptive label
- **Tasks**: task IDs owned
- **Responsibility**: 1–2 sentences
- **Inputs needed from other subagents**
- **Outputs it produces**

If Small or Medium (single subagent), state this clearly.

## Output

Write the full task breakdown, execution waves, critical path, and subagent assessment to:
~/.claude/features/<name>/impl-tasks.md

Use clear markdown headers matching the sections above.
```

---

**Subagent B — Test Planner:**

```
You are writing a detailed, low-level test plan for a feature implementation.

Feature folder: ~/.claude/features/<name>/

Read the following files to understand the goal and approach:
- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml, go.mod, or equivalent. Fall back to scanning file extensions.
2. Get the project structure: run `git ls-files | head -100`
3. Look for existing test files to understand the project's testing conventions (location, naming, patterns).

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
- **Acceptance criterion it covers**: which part of the story this validates

Be specific. Include edge cases: empty states, validation errors, concurrent access, permission boundaries. Do not skip a layer unless the tech stack genuinely has no equivalent.

## Output

Write the full test plan to:
~/.claude/features/<name>/test-plan.md
```

---

## Step 3 — Synthesize into impl-plan.md

After both subagents have finished, read `impl-tasks.md` and synthesize the task breakdown into the implementation plan. The test plan remains in its own file (`test-plan.md`).

**Write behaviour:**
- If `<is-revision>` is **false**: write a new file at `~/.claude/features/<name>/impl-plan.md`
- If `<is-revision>` is **true**: **append** to the existing file — add a `---` horizontal rule followed by `# Revision: <today's date>` and the new content

**Synthesis notes:**
- If `<ticket>` was detected, include the `## Branch Names` section with a row for every repo in scope. Pattern: `feature/<ticket>_short-description` (repo-specific kebab-case slug). If no ticket, omit this section entirely.
- For `## Subagent Assignments`: include the full breakdown if Subagent A assessed Large or Medium with clear parallel benefit. Otherwise write: `Single subagent recommended — follow execution waves above.`

### Format for impl-plan.md:

```md
# Implementation Plan: <Feature Title>

> Generated: <today's date>

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

> Branch names follow the pattern `feature/<ticket>_short-description`. The short description is repo-specific — use a concise slug that reflects what changes in that repo (kebab-case, no spaces).

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
[Any ambiguities or decisions that need to be made before implementation starts. Leave blank if none.]
```

## Step 4 — Spawn review subagents in parallel

After `impl-plan.md` has been written, spawn **4 subagents in the same response** (`subagent_type: general-purpose`) and **wait for all 4 to finish** before continuing. These review the **plan and task design** — not implementation-level code quality (that is covered later by `/feature-code-review`).

---

**Reviewer 1 — Technical feasibility and task design:**

```
You are reviewing a low-level implementation plan for technical correctness, feasibility, and task design quality.

Plan: ~/.claude/features/<name>/impl-plan.md

Read the file. Focus on:
- Missing or incorrect task dependencies
- Wrong assumptions about APIs, libraries, or system capabilities
- Implementation gaps — steps that skip over non-trivial work
- Tasks that are technically unsound or will not work as described
- Task scopes that are too vague to execute without guessing
- Tasks that are too large and should be split further
- Dependency graph errors — tasks that claim independence but actually depend on each other
- Missing tasks — work implied by other tasks but not explicitly listed

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite the task ID.
```

---

**Reviewer 2 — Security design:**

```
You are reviewing a low-level implementation plan for security risks at the design level.

Plan: ~/.claude/features/<name>/impl-plan.md

Read the file. Focus on design-level security concerns:
- Authentication and authorisation gaps in the planned architecture
- Missing security-relevant tasks (e.g. no task for input validation, no task for access control)
- Data flow risks — sensitive data passing through layers without planned protection
- Missing threat considerations for the feature's attack surface
- Insecure design patterns chosen in the task scopes

Do NOT focus on implementation-level security (injection, XSS, etc.) — those are caught during code review.

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite the task ID.
```

---

**Reviewer 3 — Architectural fit and design patterns:**

```
You are reviewing whether a low-level implementation plan fits the existing architecture and follows established design patterns.

Plan: ~/.claude/features/<name>/impl-plan.md

Read the file. You have access to the filesystem.

Focus on plan-level architectural concerns:
- Does the planned task structure respect the existing architecture (layer boundaries, module responsibilities)?
- Detect the repo name from the working directory.
- Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the design patterns section — use it as the source of truth for what patterns new code must follow.
- Use Glob and Grep to find 2–3 existing features similar to what this plan describes.
- Compare the planned approach against those patterns. Flag tasks where the plan would introduce a different design pattern than the rest of the codebase uses.
- Are there planned abstractions or structures that conflict with how the codebase is organized?

Do NOT focus on implementation-level maintainability (naming, complexity, duplication) — those are caught during code review.

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite the task ID.
```

---

**Reviewer 4 — Test plan coverage:**

```
You are reviewing whether a test plan adequately covers the planned implementation tasks.

Plan: ~/.claude/features/<name>/impl-plan.md
Test plan: ~/.claude/features/<name>/test-plan.md

Read both files. You have access to the filesystem.

Focus on:
- Does every task with user-facing or logic-heavy scope have corresponding test coverage?
- Does the test plan cover all happy paths for the feature?
- Are edge cases, error states, and boundary conditions covered?
- Are there tasks that introduce new integrations or data flows with no integration test?
- Is the E2E/acceptance test coverage sufficient to validate the user story?

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Cite task IDs.
```

---

## Step 5 — Spawn fix subagent

After all 4 reviewers have finished, spawn a **foreground** subagent and **wait for it to finish**.

```
You are revising a low-level implementation plan based on review findings.

Plan:    ~/.claude/features/<name>/impl-plan.md
Story:   ~/.claude/features/<name>/story.md

Review findings (injected below — apply these directly, do not re-read a separate file):

[REVIEWER_1_OUTPUT]

[REVIEWER_2_OUTPUT]

[REVIEWER_3_OUTPUT]

[REVIEWER_4_OUTPUT]

## Instructions

1. For each finding across all reviewers, decide whether it is valid and improves the plan. Apply changes that are clearly correct. Skip anything speculative, contradictory, or that re-litigates high-level design decisions already settled in the story.
2. Rewrite ~/.claude/features/<name>/impl-plan.md with all accepted changes applied. Keep the same structure and format.
3. Append an ## Implementation Plan Review section at the bottom with a changelog table:

| Finding | Reviewer | Severity | Decision | Rationale |
|---------|----------|----------|----------|-----------|
| [brief description] | R1/R2/R3/R4 | CRITICAL/HIGH/LOW | Applied / Rejected | [why] |

4. If any CRITICAL finding was Rejected, add a prominent warning block immediately after the table:

> ⚠️ **CRITICAL finding not applied:** [finding description] — the user must consciously acknowledge this risk before starting implementation.
```

Replace `[REVIEWER_1_OUTPUT]` through `[REVIEWER_4_OUTPUT]` with the actual text returned by each reviewer in Step 4.

## Step 6 — Report to the user

Tell the user the implementation plan is finished. Give a brief summary:
- Number of tasks
- Number of execution waves and maximum parallelism
- Whether subagent split is recommended
- Any open questions that need answers before starting
- Any CRITICAL findings from the review that were not applied

Then prompt: _"Next step: run `/feature-implement` to execute the tasks from this plan."_

## Rules

- Never invent tasks not grounded in the story and plan
- Task IDs must be stable — T01, T02, … in order of logical appearance
- Every task must have a clear done state
- Subagent assignments are only recommended when they reduce total wall-clock time — do not recommend them just because a feature is moderately complex
- All files are written under `~/.claude/features/<name>/`
- If a ticket number is detected, the `## Branch Names` section is mandatory. Every repo touched by the feature gets its own row. Short descriptions must differ per repo to reflect that repo's specific changes.
