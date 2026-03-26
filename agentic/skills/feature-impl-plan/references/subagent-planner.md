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

Lines must not exceed 140 characters (keeps files readable in editors and diff views).
