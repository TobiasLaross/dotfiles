---
name: feature-implement
description: >-
  Execute the tasks from a feature's impl-plan, wave by wave, following dependency order. Use
  whenever the user is ready to start coding — even if they just say "start building", "let's go",
  or "implement it". Reads story, plan, and impl-plan to stay aligned, marks tasks complete as
  it goes, and runs tests after each wave to catch regressions early.
argument-hint: [feature-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Feature Implementation Workflow

The user has invoked `/feature-implement`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names
  in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one

**If no argument is provided:**
- Infer from the current session conversation which feature is being discussed
- If unclear, scan `~/.claude/features/` for feature folders (exclude `done/`),
  list them (numbered), and ask the user to pick one (by number or name)

## Step 2 — Read all feature files

Read every `.md` file in `~/.claude/features/<name>/`. At minimum, expect:
- `story.md` — the user story and context
- `plan.md` — the high-level plan
- `impl-plan.md` — the detailed implementation plan with tasks and execution waves
- `test-plan.md` — the test plan (unit, integration, E2E)

If `impl-plan.md` is missing, tell the user and suggest running `/feature-impl-plan` first.

## Step 3 — Detect repos, branches, and context

From the impl-plan, identify:
- Which repos need changes (check the **Branch Names** or **Repos involved** section)
- Which branches to work on

For each repo:
1. Check if `~/.claude/repo-context/<repo-name>.md` exists and read it — it contains
   architecture, design patterns, and inter-repo dependencies that inform how code
   should be written.
2. Check out the correct branch. If the branch already exists, use it. If not,
   create it from the main/master branch.

## Step 4 — Execute tasks

### Resume check

Before starting, scan `impl-plan.md` for tasks already marked `- [x] Implemented`.
Skip those and begin from the first unchecked task in the current wave. Report which
tasks were already complete (e.g., "Resuming: T01, T02 already implemented. Starting
from T03 in Wave 2.").

### Subagent dispatch

Check the **Subagent Assignments** section in `impl-plan.md`:
- If it recommends **multiple subagents**, dispatch each subagent's task group as a
  parallel Agent call. Each subagent prompt should include: the full story context,
  the specific task IDs and scopes it owns, the repo it operates in, the repo-context
  file (if available), relevant sections of `test-plan.md`, and any inputs it needs
  from other subagents.
- If it recommends a **single subagent** (or the section is absent), execute tasks
  sequentially in the main agent using the wave-by-wave approach below.

### Wave-by-wave execution

Follow the **Execution Plan** section in `impl-plan.md`. Execute tasks wave by wave:

1. For each wave, identify which tasks can run in parallel
2. For tasks in the same repo that don't touch the same files, execute them
   sequentially in a single pass (parallel subagents are only useful for cross-repo
   work)
3. For cross-repo waves, use parallel subagents
4. When implementing a task, cross-reference `test-plan.md` for any test cases that
   cover the task's scope. Use these to guide edge case handling and validation logic.
   If the task includes writing tests, follow the test plan's specifications exactly.
5. After completing each task:
   a. Verify the done state described in the task scope. If verification fails (e.g.,
      tests fail, expected file doesn't exist, API doesn't respond as described),
      attempt one fix pass. If the fix doesn't resolve it, mark the task as blocked,
      add a comment below the task in `impl-plan.md` explaining why, and continue to
      the next task. Report all blocked tasks in Step 6.
   b. Mark the task's checkbox in `impl-plan.md` from `- [ ] Implemented` to
      `- [x] Implemented` using the Edit tool
6. After completing all tasks in a wave, report: "Wave N complete: T01, T03, T05
   done. Moving to Wave N+1." If any tasks in the wave were blocked, list them.

**Important:**
- Follow the impl-plan — it has been reviewed and approved
- Check the **Acceptance Criteria** section if present — this is the source of truth
  for what the final result should look like
- If the impl-plan contains an **Open Questions** section with unresolved items that
  affect the current task, ask the user before proceeding
- If the impl-plan contains a **Design Decisions** section, follow those decisions
  when making judgment calls
- Do not skip tasks or reorder across waves — dependencies matter
- If a task is blocked by an external dependency (e.g., waiting for a merge in
  another repo), skip it, complete all unblocked tasks, and tell the user what
  remains blocked and why

## Step 5 — Tests

After all tasks in a repo are complete, prompt the user to run the test suite and report results back.
Some repos (e.g. Xcode/iOS projects) can get stuck or time out during automated test runs, and some
environments can't run the full suite locally — so it's more reliable to let the user run tests and
share the output. Once they do, diagnose any failures and fix them. If a fix requires changes beyond
the task scope, ask before proceeding.

## Step 6 — Report

When all tasks are complete (or all unblocked tasks are complete), report:
- Which tasks were completed
- Which tasks are blocked (if any) and what they're waiting on
- Test results (if the user has run them)
- Any deviations from the plan and why

Then prompt: _"Next step: run `/feature-code-review <name>` to review the
implemented code, then `/feature-code-fix <name>` to apply any fixes."_
(replace `<name>` with the actual feature folder name resolved in Step 1).

## Rules

- Never deviate from the impl-plan without telling the user why
- If the impl-plan has open questions, ask the user before implementing the affected
  tasks
- If you discover something the plan got wrong (e.g., a file path changed, a function
  was renamed), fix it and note the deviation
- Do not create commits unless the user asks — just make the changes
- Do not push to remote unless the user asks
