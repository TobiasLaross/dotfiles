---
name: feature-code-review
description: >-
  Reviews implemented code for a feature from 4 perspectives in parallel — runtime safety,
  performance, code quality, and completeness. Outputs findings to review-fixes.md for
  optional follow-up with /feature-code-fix. Use when the user runs /feature-code-review
  with an optional feature name. Ideal to run after /feature-implement completes.
argument-hint: [feature-name]
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Feature Code Review Workflow

The user has invoked `/feature-code-review`. Follow this workflow exactly.

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
- `story.md` — the user story and context (used as **original requirements**)
- `plan.md` — the high-level plan
- `impl-plan.md` — the detailed implementation plan with tasks and execution waves
- `test-plan.md` — the test plan (unit, integration, E2E)

Store all of this. The story, impl-plan, and test-plan provide the acceptance
criteria and requirements context for the review.

## Step 3 — Gather code context

Collect the following before launching agents:

- **Base branch:** Run
  `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
  to identify main/master/develop. If that returns nothing (no remote), default to `main`.
  Store as `BASE_BRANCH`.
- **Merge base:** Run `git merge-base HEAD origin/$BASE_BRANCH 2>/dev/null`. If that
  fails (no remote or branch not found), fall back to `git merge-base HEAD HEAD~10
  2>/dev/null`. Store as `MERGE_BASE`. If still empty, use `HEAD~1`.
- **Changed files:** Run `git diff $MERGE_BASE --name-only` to get files changed
  relative to the base. If no changes are found, check the impl-plan for file paths
  mentioned in the tasks and use those instead.
- **Full diff:** Run `git diff $MERGE_BASE` to get the complete diff against the base.
- **File contents:** Read all changed source and test files in full using the
  Read tool.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`,
  `*.csproj`, `Cargo.toml`, `go.mod`, or equivalent. Fall back to file extensions.
- **Project structure:** Run `git ls-files | head -80`.

If the impl-plan references multiple repos, repeat this for each repo directory.

If no changed files can be identified from git or the impl-plan, ask the user to
specify which files to review and stop.

## Step 4 — Launch 4 sub-agents in parallel

Call the Agent tool exactly 4 times in the same response. Do NOT wait for one to
finish before launching the next. Replace placeholders with actual content from
Steps 2–3. Use the feature's `story.md` as the [REQUIREMENTS] source.

These agents review the **actual implementation** (code quality, runtime behavior,
concrete bugs). Design-level concerns (architecture fit, task structure, security
design) were already covered during `/feature-impl-plan` — do not duplicate that
work here.

Agent 1 — Runtime Safety (correctness + security):
"Review the following code for runtime correctness and security. Focus on:

Correctness: logic errors, off-by-one errors, incorrect assumptions, missing
null/undefined checks, wrong return values, broken control flow, misuse of APIs
or libraries, anything that will produce wrong results at runtime.

Security: injection risks (SQL, XSS, command injection), broken authentication or
authorization, sensitive data in logs or responses, hardcoded secrets, insecure
deserialization, missing input validation, OWASP Top 10 issues.

Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Base branch: [BASE_BRANCH]
Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 2 — Performance & Scalability:
"Review the following code for performance and scalability issues. Focus on: N+1
query patterns, missing database indexes, synchronous operations that should be
async, unnecessary loops or recomputation, memory leaks, large payloads loaded
into memory, missing pagination, and anything that will degrade under load.
Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 3 — Code Quality (maintainability + design patterns):
"Review the following code for maintainability and design pattern consistency.

Maintainability: functions or classes doing too much, duplicated logic, misleading
names, missing or misleading comments on non-obvious logic, magic numbers or
strings, deeply nested code, tight coupling between modules, anything that will
make this code hard to change or understand later.

Design pattern consistency: You have access to the filesystem.
1. Detect the current repo name from the working directory path.
2. Check whether a pre-built context file exists:
   `cat ~/.claude/repo-context/<repo-name>.md 2>/dev/null`. If it exists, read
   the '## Design patterns' section — use this as your primary source of truth
   for what patterns new code should follow.
3. Use Glob and Grep to find 2-4 existing features similar to what was
   implemented. Read those files to confirm patterns.
4. Compare the new implementation against those patterns and flag deviations.
   If the context file named a canonical pattern for an area touched by the new
   code, flag any deviation as HIGH or CRITICAL.

Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Tech stack: [TECH_STACK]
Project structure: [PROJECT_STRUCTURE]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 4 — Completeness (acceptance criteria + test quality):
"Review the following implementation for completeness against requirements and
test quality. You have access to the filesystem.

Part A — Acceptance Criteria:
Original requirements (from story.md):
[REQUIREMENTS]

Implementation plan tasks:
[IMPL_PLAN_TASKS]

For each requirement or acceptance criterion:
1. Determine whether the implementation covers it — fully, partially, or not
   at all.
2. If partially or not covered, describe specifically what is missing.
3. Check the changed files and, if needed, adjacent files to confirm the behavior
   is actually wired up end-to-end (not just partially implemented).

Part B — Test Quality:
Also read the test plan from: [TEST_PLAN]

1. Missing edge cases — inputs or states not covered: boundary values, empty/null
   inputs, error states, concurrent access, large inputs, invalid types, etc.
2. Poorly implemented tests — tests that give false confidence: tests that never
   fail, assertions too loose, tests that test implementation details instead of
   behavior, missing assertions, tests that depend on each other or execution
   order, brittle tests.
3. Missing main flow coverage — any critical happy path with no test.
4. Test plan coverage — for each test case in the test plan, determine whether a
   corresponding test exists: Covered, Missing, or Partial.

For each issue, reference specific files, line numbers, and test names. Use
severity flags CRITICAL / HIGH / LOW. CRITICAL means a core requirement is missing
or a critical happy path has no test.

Base branch: [BASE_BRANCH]
Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

## Step 5 — Synthesize findings

After all 4 agents return their results, present everything in this format:

---

## Feature Code Review: `<feature-name>`

Severity flags:
- **CRITICAL:** must fix before merging — correctness, security, or data
  integrity risk
- **HIGH:** significant concern — should be fixed before or shortly after merging
- **LOW:** worth addressing — code quality, minor improvements

### Runtime Safety
[Agent 1 findings — bullet points with file:line references and severity flags]

### Performance & Scalability
[Agent 2 findings — bullet points with file:line references and severity flags]

### Code Quality
[Agent 3 findings — bullet points with file:line references and severity flags]

### Completeness
#### Acceptance Criteria
[Agent 4 Part A — each requirement: Fully / Partially / Not covered,
with explanation]

#### Test Quality
[Agent 4 Part B — bullet points with severity flags, referencing test names
and files]

#### Test Plan Coverage
[Agent 4 Part B.4 — X of Y test cases covered, list any missing/partial]

### Summary
**Overall assessment:** [1-2 sentences on whether the code is ready to merge]

**Must fix before merging:**
1. [Most critical issue]
2. [Second most critical issue]
3. [Third — if applicable]

**Safe to merge as-is:** [aspects that are solid]

---

## Step 6 — Write review-fixes.md

Write findings to `~/.claude/features/<name>/review-fixes.md`:

```md
# Review Findings

> Generated: <today's date>
> Feature: <feature-name>

## Findings

### F01 — <Short title describing the finding>
- **Source:** <Agent name> (<severity>)
- **Finding:** <1-2 sentence description>
- **Files:** <file paths that need changes>
- **Suggested fix:** <brief description of what to change>

[Repeat for each finding worth acting on]

## No Action Needed

| Finding | Agent | Severity | Rationale |
|---------|-------|----------|-----------|
| [brief description] | Agent N | LOW | [why no action needed] |
```

> **CRITICAL WARNING:** If any CRITICAL finding exists, highlight it prominently
> at the top of the file.

Then prompt: _"Next step: run `/feature-code-fix <name>` to apply fixes, or
review the findings in `~/.claude/features/<name>/review-fixes.md` first."_
(replace `<name>` with the actual feature folder name).
