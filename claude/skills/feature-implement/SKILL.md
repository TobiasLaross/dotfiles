---
name: feature-implement
description: Implements a feature from its impl-plan.md using parallel subagents per execution wave. After each wave, runs a review-then-fix cycle. When everything is implemented, runs 5 final parallel reviewers from different perspectives. Use when the user runs /feature-implement with an optional feature name.
argument-hint: [feature-name]
---

# Feature Implement Workflow

The user has invoked `/feature-implement`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- Verify `~/.claude/features/<name>/impl-plan.md` exists — if not, tell the user to run `/feature-impl-plan` first and stop

**If no argument is provided:**
- Scan `~/.claude/features/` for feature folders (exclude `done/`)
- Identify the most recently modified folder or infer from the current conversation
- If you cannot determine the feature, list available features and ask the user to pick one

Store the resolved `<name>` and read **all files** in `~/.claude/features/<name>/`:
- `story.md`
- `plan.md`
- `impl-plan.md`
- Any other `.md` files present in the folder

Parse `impl-plan.md` to extract:
- All tasks (IDs T01, T02, … with title, scope, area, dependencies)
- Execution waves (Wave 1, Wave 2, … with task groupings)
- Subagent assignments (if the plan specifies a Large feature split — use those groupings. If Single subagent recommended, treat each wave's tasks as one group per wave)

## Step 2 — Initialize progress tracking

Check whether `impl-plan.md` already contains a `## Progress` section.

- If **not present**: append the following to `~/.claude/features/<name>/impl-plan.md`:

```md
---

## Progress

> Started: <today's date>

| Task | Title | Status | Wave | Notes |
|------|-------|--------|------|-------|
| T01  | …     | ⬜ Pending | 1 | |
[one row per task, filled in from the task list]
```

- If **already present**: read the existing statuses. Skip any tasks already marked ✅ Done. Continue from where implementation left off.

Status values used in the table:
- `⬜ Pending` — not started
- `🔄 In Progress` — currently being implemented
- `✅ Done` — implemented and post-wave review passed
- `❌ Failed` — subagent reported it could not complete the task

## Step 3 — Execute waves sequentially, tasks in parallel

Process each wave in order. For each wave:

### 3a — Mark wave tasks as In Progress

Update the Progress table in `impl-plan.md` — set all tasks in this wave to `🔄 In Progress`.

### 3b — Spawn parallel implementation subagents

Spawn **one subagent per task** in this wave (or one per subagent group if the plan defined groups for a Large feature). Launch all in the **same response** and **wait for all to finish** before continuing.

For each task, use this prompt — substitute all placeholders with actual values:

```
You are implementing a single task as part of a larger feature.

## Feature context — read all of these before writing any code

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before starting. The impl-plan contains the full task list, execution waves, test plan, and any subagent assignments — understanding the whole picture ensures your work fits the surrounding tasks.

## Your task

**ID:** <TASK_ID>
**Title:** <TASK_TITLE>
**Area:** <TASK_AREA>
**Scope:** <TASK_SCOPE>
**Depends on:** <DEPENDS_ON — list task IDs, or "none">

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml, go.mod, or equivalent.
2. Run `git ls-files | head -100` to understand the project structure.
3. If a repo-context file exists at ~/.claude/repo-context/<repo-name>.md, read it — especially the Architecture and Design patterns sections.
4. Read any existing files you will modify before changing them.

## Implementation rules

- Implement only what is described in the scope above. Do not expand scope or implement adjacent tasks.
- Follow the design patterns already established in the codebase.
- Write code that passes the relevant tests from the impl-plan's test plan.
- If you encounter an ambiguity that blocks implementation, make the most reasonable choice and document it in a code comment.
- After implementing, run any existing tests to verify nothing is broken (if a test runner is detectable).

## Output

When done, output a brief summary:
- Files created or modified
- What was implemented
- Any decisions made that differ from the scope (with justification)
- Any blockers encountered
```

### 3c — Update progress table

After all subagents in this wave finish:
- Mark successfully completed tasks as `✅ Done` in the Progress table
- Mark any failed tasks as `❌ Failed` and record the reason in the Notes column
- Update `impl-plan.md` with these changes

### 3d — Spawn wave review subagent

Spawn a **foreground** subagent and **wait for it to finish** before continuing.

```
You are reviewing the implementation of a completed wave of tasks.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing.

## What was just implemented

Wave <WAVE_NUMBER> tasks: <COMMA_SEPARATED_TASK_IDS_AND_TITLES>

## Your job

1. Run `git diff HEAD~<N_COMMITS_IN_WAVE> --stat` and `git diff HEAD~<N_COMMITS_IN_WAVE>` to see the changes from this wave. If that doesn't work cleanly, use `git status` and read the relevant changed files directly.
2. Read all changed files in full.
3. Review the implementation against:
   - The task scopes in impl-plan.md
   - The story goal in story.md
   - The test plan in impl-plan.md (are the relevant tests present?)
   - Correctness: logic errors, missing null checks, broken control flow
   - Security: injection risks, auth gaps, sensitive data exposure
   - Code quality: violations of the codebase's patterns, tight coupling, poor naming

For each finding use severity **CRITICAL** / **HIGH** / **LOW** and cite the specific file and line.

Output your findings as a structured list. End with a **Verdict**: Approved (no blocking issues) or Needs fixes (list the CRITICAL/HIGH items that must be addressed).
```

### 3e — Spawn wave fix subagent

Spawn a **foreground** subagent and **wait for it to finish** before continuing.

```
You are applying review fixes to a just-implemented wave of tasks.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before making any changes.

## Review findings to address

<INSERT_WAVE_REVIEW_OUTPUT_HERE>

## Instructions

1. Read each file mentioned in the review findings.
2. For each finding, decide whether it is clearly correct and improves the code. Apply changes that are valid. Skip anything speculative, stylistic, or that re-litigates design decisions already settled in the plan.
3. Apply fixes using the Edit tool. Do not rewrite files wholesale unless a file is genuinely broken.
4. After applying all fixes, output a changelog:

| Finding | Severity | Decision | Rationale |
|---------|----------|----------|-----------|
| [description] | CRITICAL/HIGH/LOW | Applied / Rejected | [why] |

If any CRITICAL finding was Rejected, add a warning:
> ⚠️ CRITICAL not applied: [description] — requires manual review before proceeding.
```

Replace `<INSERT_WAVE_REVIEW_OUTPUT_HERE>` with the full text returned by the review subagent in Step 3d.

### 3f — Proceed to next wave

Repeat Steps 3a–3e for each remaining wave.

---

## Step 4 — Final 5-perspective review

After all waves are complete and all tasks are marked ✅ Done (or ❌ Failed), spawn **5 subagents in the same response** and **wait for all 5 to finish** before continuing.

---

**Final Reviewer 1 — Correctness & story completeness:**

```
You are doing a final correctness and completeness review of an implemented feature.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing.

## Your job

1. Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null` to find all changed files.
2. Read all changed files in full.
3. Verify the implementation against the story and every task in impl-plan.md:
   - Does the implementation fully satisfy the user story?
   - Are there tasks marked Done that are actually incomplete or broken?
   - Are there logic errors, off-by-one bugs, incorrect assumptions, or broken control flow?
   - Is anything wired up end-to-end — or just partially implemented and left dangling?

Use severity flags **CRITICAL** / **HIGH** / **LOW**. Cite file names and line numbers. Be specific.
```

---

**Final Reviewer 2 — Security:**

```
You are doing a final security review of an implemented feature.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing.

## Your job

1. Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null)` to see all changes.
2. Review for:
   - Authentication and authorization gaps
   - Input validation and injection risks (SQL, XSS, command injection, path traversal)
   - Sensitive data in logs, responses, or client-side code
   - Hardcoded secrets or insecure defaults
   - Missing rate limiting or abuse vectors
   - Insecure direct object references

Use severity flags **CRITICAL** / **HIGH** / **LOW**. Cite file names and line numbers.
```

---

**Final Reviewer 3 — Performance & maintainability:**

```
You are doing a final performance and maintainability review of an implemented feature.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing.

## Your job

1. Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null)` to see all changes.
2. Review for:
   - N+1 query patterns or unnecessary database round-trips
   - Missing indexes or caching for frequent reads
   - Synchronous operations that should be async
   - Large payloads loaded entirely into memory
   - Duplicated logic that should be extracted
   - Functions or classes doing too much (violating single responsibility)
   - Magic numbers, misleading names, or non-obvious logic without comments
   - Tight coupling that will make this hard to change later

Use severity flags **CRITICAL** / **HIGH** / **LOW**. Cite file names and line numbers.
```

---

**Final Reviewer 4 — Architecture & design pattern consistency:**

```
You are doing a final architectural and design pattern review of an implemented feature.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing. You have full filesystem access.

## Your job

1. Detect the repo name from the working directory.
2. Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the Architecture and Design patterns sections — use them as the source of truth for what patterns new code must follow.
3. Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null` and read all changed files.
4. Use Glob and Grep to find 2–3 existing features similar to what was implemented.
5. Compare the new code against established patterns. Flag:
   - Deviations from the canonical pattern for each area (API layer, data layer, UI, etc.)
   - New abstractions that duplicate existing utilities
   - Layers violated (e.g. business logic in a controller, DB queries in a view)
   - Naming or structural conventions broken

Use severity flags **CRITICAL** / **HIGH** / **LOW**. Reference specific existing files as examples of the expected pattern.
```

---

**Final Reviewer 5 — Test quality & edge case coverage:**

```
You are doing a final test coverage and quality review of an implemented feature.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md

Read every file above in full before reviewing. Pay particular attention to the Test Plan section in impl-plan.md — this defines what tests were required.

## Your job

1. Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null` to find all changed files.
2. Read all test files in full. Also read the corresponding source files to understand what the tests should be covering.
3. Assess:

### Required tests from impl-plan
For each test in the impl-plan's Test Plan (unit, integration, E2E), check whether it was actually written. List each as: ✅ Present / ⚠️ Partial / ❌ Missing.

### Missing edge cases
Identify edge cases not covered that should be:
- Boundary values (empty inputs, maximum sizes, zero/negative values)
- Error states and failure modes (network failure, DB error, timeout, invalid auth)
- Concurrent access or race conditions
- Permission boundary violations (user A accessing user B's data)
- Large input handling or pagination edge cases
- Unexpected input types or malformed data

### Test quality issues
Flag tests that:
- Never actually fail (assertion always passes regardless of implementation)
- Test implementation details instead of observable behaviour
- Are brittle (depend on ordering, timing, or hardcoded IDs)
- Have missing assertions or test too many things at once
- Depend on each other or require a specific execution order

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Reference the specific test file and test name.
```

---

## Step 5 — Synthesize final review and write impl-review.md

After all 5 final reviewers finish, synthesize their findings and write to `~/.claude/features/<name>/impl-review.md`:

```md
# Implementation Review

> Reviewed: <today's date>

## Correctness & Story Completeness
[Reviewer 1 verdict and findings]

## Security
[Reviewer 2 verdict and findings]

## Performance & Maintainability
[Reviewer 3 verdict and findings]

## Architecture & Design Pattern Consistency
[Reviewer 4 verdict and findings]

## Test Quality & Edge Case Coverage
[Reviewer 5 verdict and findings]

---

## Consolidated Issues

### CRITICAL
[All CRITICAL findings across all reviewers, deduplicated]

### HIGH
[All HIGH findings across all reviewers, deduplicated]

### LOW
[All LOW findings, grouped by theme]
```

## Step 6 — Spawn final fix subagent

Spawn a **foreground** subagent and **wait for it to finish**.

```
You are applying final review fixes to a completed feature implementation.

## Feature context — read all of these first

- ~/.claude/features/<name>/story.md
- ~/.claude/features/<name>/plan.md
- ~/.claude/features/<name>/impl-plan.md
- ~/.claude/features/<name>/impl-review.md

Read every file above in full before making any changes.

## Instructions

1. Work through the Consolidated Issues in impl-review.md, starting with CRITICAL, then HIGH, then LOW.
2. For each issue, read the relevant source file(s), decide if the fix is clearly correct, and apply it using the Edit tool.
3. For missing tests identified by the test reviewer: write the actual test code now.
4. Skip anything speculative, contradictory, or that re-litigates high-level decisions already settled in the plan.
5. After all fixes are applied, output a final changelog:

## Final Fix Changelog

| Finding | Reviewer | Severity | Decision | Rationale |
|---------|----------|----------|----------|-----------|
| [description] | R1/R2/R3/R4/R5 | CRITICAL/HIGH/LOW | Applied / Rejected | [why] |

If any CRITICAL finding was Rejected:
> ⚠️ CRITICAL not applied: [description] — this risk must be consciously acknowledged before this feature is considered done.
```

## Step 7 — Update progress and report to user

1. Mark all ✅ Done tasks in the Progress table as confirmed complete.
2. Append a summary line to the Progress section of `impl-plan.md`:

```md
> Implementation completed: <today's date>
> Final review: <N> CRITICAL, <N> HIGH, <N> LOW findings — <N> applied, <N> rejected
```

3. Report to the user:
   - Total tasks completed vs failed
   - Number of execution waves run
   - Summary of final review findings (how many per severity, how many applied)
   - Any CRITICAL findings that were rejected (must be acknowledged)
   - Prompt: _"Run `/review-code` for a final pre-merge code review, or move the feature to done with `mv ~/.claude/features/<name>/ ~/.claude/features/done/<name>/`."_

---

## Rules

- Every subagent **must** read all files in the feature folder before doing any work
- Never skip the wave review-and-fix cycle — every wave gets reviewed before the next wave starts
- Never execute Wave N+1 until Wave N's review and fix cycle is complete
- Implementation subagents must not expand scope beyond their assigned task
- The Progress table in `impl-plan.md` must reflect reality at all times — update it after every wave
- If a task is marked ❌ Failed, report it to the user and ask whether to retry, skip, or stop before proceeding to the next wave
- Final reviewers run after **all** waves are done — never interleave final review with wave execution
- All files written or modified go in the project working directory — not in `~/.claude/features/<name>/` (that folder is for planning docs only, except impl-review.md which is also written there)
