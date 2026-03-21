---
name: feature-implement
description: Implement a feature from its plan. Reads all files in the feature folder (story, plan, impl-plan) and executes tasks in dependency order, following execution waves. Use when the user runs /feature-implement with an optional feature name.
argument-hint: [feature-name]
---

# Feature Implementation Workflow

The user has invoked `/feature-implement`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one

**If no argument is provided:**
- Infer from the current session conversation which feature is being discussed
- If unclear, scan `~/.claude/features/` for feature folders (exclude `done/`), list them (numbered), and ask the user to pick one (by number or name)

## Step 2 — Read all feature files

Read every `.md` file in `~/.claude/features/<name>/`. At minimum, expect:
- `story.md` — the user story and context
- `plan.md` — the high-level plan
- `impl-plan.md` — the detailed implementation plan with tasks and execution waves
- `test-plan.md` — the test plan (unit, integration, E2E)

If `impl-plan.md` is missing, tell the user and suggest running `/feature-impl-plan` first.

## Step 3 — Detect repos and branches

From the impl-plan, identify:
- Which repos need changes (check the **Branch Names** or **Repos involved** section)
- Which branches to work on

For each repo, check out the correct branch. If the branch already exists, use it. If not, create it from the main/master branch.

## Step 4 — Execute tasks

Follow the **Execution Plan** section in `impl-plan.md`. Execute tasks wave by wave:

1. For each wave, identify which tasks can run in parallel
2. For tasks in the same repo that don't touch the same files, execute them sequentially in a single pass (parallel subagents are only useful for cross-repo work)
3. For cross-repo waves, use parallel subagents if beneficial
4. After completing each task:
   a. Verify the done state described in the task scope
   b. Mark the task's checkbox in `impl-plan.md` from `- [ ] Implemented` to `- [x] Implemented` using the Edit tool
5. Run existing tests after each wave to catch regressions early unless a dependency from another repo that is are blocking us from running tests

**Important:**
- Follow the impl-plan — they have been reviewed and approved
- Check the **Acceptance Criteria** section if present — this is the source of truth for what the final result should look like
- Check the **Design Decisions** section before making judgment calls — decisions have already been made
- Do not skip tasks or reorder across waves — dependencies matter
- If a task is blocked by an external dependency (e.g., waiting for a merge in another repo), skip it, complete all unblocked tasks, and tell the user what remains blocked and why

## Step 5 — Run tests

After all tasks in a repo are complete:
1. Run the repo's test suite unless running tests are blocked by another repo
2. If tests fail, diagnose and fix by using subagent(s) — check `~/.claude/features/<name>/test-plan.md` for expected test behavior
3. If a fix requires changes beyond the task scope, ask the user before proceeding

## Step 6 — Report

When all tasks are complete (or all unblocked tasks are complete), report:
- Which tasks were completed
- Which tasks are blocked (if any) and what they're waiting on
- Test results
- Any deviations from the plan and why

Then prompt: _"Next step: run `/feature-code-review <name>` to review the implemented code."_ (replace `<name>` with the actual feature folder name resolved in Step 1).

## Rules

- Never deviate from the impl-plan without telling the user why
- If the impl-plan has open questions, ask the user before implementing the affected tasks
- If you discover something the plan got wrong (e.g., a file path changed, a function was renamed), fix it and note the deviation
- Do not create commits unless the user asks — just make the changes
- Do not push to remote unless the user asks
