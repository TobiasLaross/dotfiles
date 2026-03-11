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

## Step 2 — Gather context

Before spawning agents, collect:

- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`, `*.csproj`, `Cargo.toml`, `go.mod`, or equivalent to identify language, framework, and key dependencies. Fall back to scanning file extensions if no manifest found.
- **Base branch:** Run `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
- **Project structure:** Run `git ls-files | head -100`
- **Repo context (if in /work/):** Check `~/.claude/repo-context/<repo-name>.md` for architecture and design patterns
- **Repos in scope:** If working in `/work/`, identify all repos under `~/Developer/work/` that are touched by this feature (from the plan). Store as a list — each will get its own branch name if `<ticket>` is set.

## Step 3 — Spawn 4 analysis agents in parallel

Call the Agent tool exactly 4 times in the same response. Do NOT wait for one to finish before launching the next. Replace all placeholders with actual content from Steps 1–2.

---

**Agent 1 — Task Decomposition:**

```
You are breaking a feature into concrete, atomic implementation tasks.

Story:
[STORY_CONTENT]

High-level plan:
[PLAN_CONTENT]

Tech stack: [TECH_STACK]
Project structure:
[PROJECT_STRUCTURE]

Your job:
1. Break the feature into the smallest atomic tasks that can each be independently implemented and verified. A task should be completable in one focused coding session (roughly 30–90 minutes of work). Tasks that are too large should be split further.
2. For each task, write:
   - **ID**: T01, T02, T03, … (sequential)
   - **Title**: short imperative phrase (e.g. "Add user model migration")
   - **Scope**: 2–4 sentences describing exactly what needs to be done, which files/modules will change, and what the done state looks like
   - **Depends on**: list of task IDs that must be complete before this one can start (empty if none)
   - **Area**: the technical area this falls under (e.g. database, API, frontend, auth, config, tests)

Output as a structured list. Be thorough — cover setup, data layer, business logic, API layer, UI (if applicable), integration glue, and cleanup.
```

---

**Agent 2 — Test Plan:**

```
You are writing a detailed test plan for a feature.

Story:
[STORY_CONTENT]

High-level plan:
[PLAN_CONTENT]

Tech stack: [TECH_STACK]
Project structure:
[PROJECT_STRUCTURE]

Your job:
Produce a comprehensive test plan covering all layers of the feature. Structure your output into three sections:

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

Be specific. Tie each test back to a concrete behaviour from the story. Include edge cases: empty states, validation errors, concurrent access, permission boundaries.
```

---

**Agent 3 — Dependency & Parallelism Analysis:**

```
You are analysing task dependencies for a feature implementation to determine the optimal parallel execution strategy.

You will receive a task list produced by a decomposition agent. Your job is to reason about the dependency graph and produce execution waves.

Story:
[STORY_CONTENT]

High-level plan:
[PLAN_CONTENT]

Tech stack: [TECH_STACK]

Instructions:
1. Read the task list carefully — it includes declared dependencies for each task.
2. Verify the declared dependencies make sense. If a task is declared independent but actually requires another task's output (e.g. a schema migration before inserting data), add the missing dependency and note it.
3. Build a dependency graph and identify execution waves — groups of tasks with no interdependencies that can run in parallel.
   - Wave 1: tasks with no dependencies
   - Wave 2: tasks whose only dependencies are in Wave 1
   - Wave N: tasks whose dependencies are all in previous waves
4. For each wave, list the task IDs and titles that belong to it.
5. Flag any tasks that form a critical path — the longest sequential chain from start to finish.

Output format:
### Dependency Corrections
[List any corrections you made to declared dependencies, with reasoning. "None" if none.]

### Execution Waves
**Wave 1 (parallel):** T01, T03, T05 — [brief reason why these are independent]
**Wave 2 (parallel):** T02, T04 — [brief reason]
…

### Critical Path
[The sequence of tasks that determines the minimum time to complete the feature: T01 → T04 → T07 → T09]

### Parallelism Summary
[1–2 sentences: how many waves, maximum parallelism at each wave, overall shape of the work]
```

---

**Agent 4 — Complexity & Subagent Assignment:**

```
You are determining whether a feature is large enough to require multiple subagents working in parallel, and if so, how to assign work.

Story:
[STORY_CONTENT]

High-level plan:
[PLAN_CONTENT]

Tech stack: [TECH_STACK]
Project structure:
[PROJECT_STRUCTURE]

Instructions:
1. Assess the overall size of the feature:
   - **Small** (≤5 tasks, single area, one session): can be handled by a single subagent
   - **Medium** (6–12 tasks, 2–3 areas, fits in one long session): borderline — single subagent with clear task ordering is fine; parallel subagents optional
   - **Large** (13+ tasks, 4+ areas, or spans multiple repos): should be split across dedicated subagents

2. If the feature is **Large** (or Medium and you judge parallel subagents are clearly beneficial):
   - Propose subagent assignments. Group tasks by cohesion — a subagent should own a coherent slice of the feature (e.g. "Database + Models subagent", "API layer subagent", "Frontend subagent", "Auth + Permissions subagent").
   - For each subagent:
     - **Name**: short descriptive label
     - **Tasks**: the task IDs this subagent owns
     - **Responsibility**: 1–2 sentences on what this subagent builds end-to-end
     - **Inputs needed from other subagents**: what interfaces, types, or contracts it depends on being defined first
     - **Outputs it produces**: what it exposes for other subagents to consume
   - Identify a **coordinator order**: which subagents should start first and what shared contracts (types, API schemas, DB schema) must be agreed before parallel work begins.

3. If the feature is **Small** or **Medium (single subagent)**:
   - State this clearly and explain why parallel subagents would add overhead without benefit.
   - Recommend the single subagent follow the execution waves from the dependency analysis.

Output your size assessment, then the subagent plan (or single-subagent recommendation).
```

---

## Step 4 — Synthesize and write the implementation plan

After all 4 agents return, synthesize their outputs into a single implementation plan and write it to `~/.claude/features/<name>/impl-plan.md`.

### File format for `impl-plan.md`:

```md
# Implementation Plan: <Feature Title>

> Generated: <today's date>

## Summary
[2–3 sentences: what is being built, the core technical approach, and the expected scope]

## Size Assessment
[Small / Medium / Large — one sentence explanation]

---

## Branch Names
[Include this section only if a ticket number was detected. Otherwise omit entirely.]

**Ticket:** `<ticket>` (e.g. `SER-1234`)

| Repo | Branch |
|------|--------|
| `repo-name` | `feature/SER-1234_short-description-for-this-repo` |
| `other-repo` | `feature/SER-1234_short-description-for-other-repo` |

> Branch names follow the pattern `feature/<ticket>_short-description`. The short description is repo-specific — use a concise slug that reflects what changes in that repo (kebab-case, no spaces).

---

## Tasks

### T01 — <Title>
**Area:** <area>
**Depends on:** none (or T0X, T0Y)
**Scope:** <2–4 sentences from decomposition agent>

### T02 — <Title>
…

[All tasks in order]

---

## Execution Plan

### Wave 1 — Run in parallel
| Task | Title | Notes |
|------|-------|-------|
| T01  | …     | …     |
| T03  | …     | …     |

### Wave 2 — Run in parallel (after Wave 1)
…

[All waves]

### Critical Path
`T01 → T04 → T07 → T09`

---

## Subagent Assignments
[Include this section only if the feature is Large or Medium with clear parallel benefit. Otherwise replace with: "Single subagent recommended — follow execution waves above."]

### Coordinator Step (before parallel work)
[Shared contracts that must be agreed first: DB schema, API types, shared interfaces]

### Subagent A — <Name>
**Tasks:** T01, T02, T05
**Responsibility:** …
**Inputs needed:** …
**Outputs produced:** …

### Subagent B — <Name>
…

---

## Test Plan

### Unit Tests
[From Agent 2 — full list with setup, expected outcome, and why it matters]

### Integration Tests
[From Agent 2 — full list with setup, steps, and expected outcome]

### End-to-End / Acceptance Tests
[From Agent 2 — full list with scenario, steps, and acceptance criterion covered]

---

## Open Questions
[Any ambiguities, unknowns, or decisions that need to be made before implementation starts. Leave blank if none.]
```

After writing `impl-plan.md`, tell the user where the plan was saved and give a brief summary:
- Number of tasks
- Number of execution waves and maximum parallelism
- Whether subagent split is recommended
- Any open questions that need answers before starting

End your response with `<!-- review:plan -->` so the auto-review hook fires.

## Rules

- Never invent tasks not grounded in the story and plan
- Task IDs must be stable — T01, T02, … in order of logical appearance
- Every task must have a clear done state
- Test plan must cover all three layers (unit, integration, E2E) — do not skip a layer unless the tech stack genuinely has no equivalent
- Subagent assignments are only recommended when they reduce total wall-clock time — do not recommend them just because a feature is moderately complex
- All files are written under `~/.claude/features/<name>/`
- If a ticket number is detected, the `## Branch Names` section is mandatory. Every repo touched by the feature gets its own row. Short descriptions must differ per repo to reflect that repo's specific changes.
