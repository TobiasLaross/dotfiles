---
name: bugfix
description: >-
  Investigate a bug, write a failing test, then implement and review a fix. Use when the user
  runs /bugfix with an optional ticket number and description.
argument-hint: "[ticket-number] <bug description>"
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Bugfix Workflow

The user has invoked `/bugfix`. Follow this workflow exactly.

## Step 1 — Parse arguments and create bug folder

Parse `$ARGUMENTS` to extract:

1. **Ticket number** — the first token if it is either:
   - A plain integer (e.g. `42`, `1234`)
   - A Jira-style ticket (one or more uppercase letters, a hyphen, then digits — e.g. `SER-1234`, `PROJ-42`)
   If the first token matches either form, store it as `<ticket>`. Otherwise `<ticket>` is empty and the
   entire argument string is the description.

2. **Description** — everything after the ticket number (or the full `$ARGUMENTS` if no ticket was found).

3. **Short name** — derive a kebab-case slug from the description: 2–4 lowercase words, no special characters
   (e.g. `nil-pointer-on-login`, `missing-auth-header`). This becomes the folder name.

4. **Branch name**:
   - With ticket: `bugfix/<ticket>_<short-name>` (e.g. `bugfix/42_nil-pointer-on-login`)
   - Without ticket: `bugfix/<short-name>` (e.g. `bugfix/nil-pointer-on-login`)

Create the folder (create `~/.claude/bugs/` if it does not exist yet):

```
~/.claude/bugs/<short-name>/
```

Write `~/.claude/bugs/<short-name>/bug.md`:

```md
# <Short descriptive title>

**Description:** <description>
**Ticket:** <ticket or "none">
**Branch:** <branch name>
**Reported:** <today's date>

## Repo detection notes

[Leave blank — investigation agent fills this in]
```

## Step 2 — Gather context

Before spawning subagents, collect the following in the current working directory:

- **Repo name:** Derive from the working directory path (basename or last component before `/src`).
- **Repo context:** Check `~/.claude/repo-context/<repo-name>.md`. If it exists, read the purpose,
  architecture, inter-repo dependencies, and design patterns sections. Store as `REPO_CONTEXT`.
  If not found, read `README.md` and the main entry points.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `go.mod`, `Podfile`, `build.gradle`,
  `Cargo.toml`, or equivalent. Fall back to file extensions. Store as `TECH_STACK`.
- **Project structure:** Run `git ls-files | head -100`. Store as `PROJECT_STRUCTURE`.
- **Work repos:** If the working directory contains `/work/`, list all directories in
  `~/Developer/work/` to understand what other repos might be involved.

Store all of this. You will inject it into the investigation subagent.

## Step 3 — Spawn investigation and test subagents in parallel

Spawn **2 subagents in the same response** (`subagent_type: general-purpose`) and
**wait for both to finish** before continuing.

---

**Subagent A — Root cause investigator:**

```
You are investigating a bug to identify its probable root causes.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file first to understand the bug description.

Repo context: [REPO_CONTEXT — paste the full content, or "Not available"]
Tech stack: [TECH_STACK]
Project structure: [PROJECT_STRUCTURE]

## Phase 1 — Map the observable failure

Before reading any code, write down precisely:
- What is the observable symptom? (error message, wrong value, crash, hang, missing behaviour)
- Under what conditions does it occur? (specific input, user action, system state, race condition)
- What is the expected behaviour vs the actual behaviour?
- Is this always reproducible, or intermittent?

## Phase 2 — Trace the execution path

Follow the code from the triggering entry point (API handler, UI event, cron job, etc.)
through to the failure site. Use Grep and Glob to locate the relevant files.

For each step in the chain, note:
- File path and line range
- What the code does at that step
- Whether the step looks correct

Continue until you reach the site where the behaviour diverges from expectation.
If the bug spans multiple repos, follow the call chain across repo boundaries using
the "External communication" and "Internal repo dependencies" sections of the repo-context.

## Phase 3 — Generate root cause hypotheses

Based on Phase 2, identify the **probable root causes** — not just symptoms.
For each candidate:
- **Title**: short descriptive name
- **Location**: `file:line-range`
- **Mechanism**: the specific sequence of events that produces the observed symptom —
  be precise (e.g. "when X is nil, Y dereferences it at line 42, causing a nil pointer panic"
  rather than "possible nil pointer issue")
- **Confidence**: HIGH / MEDIUM / LOW
- **Evidence**: the exact code or pattern you found that supports this hypothesis
  (quote the relevant lines if short enough, otherwise describe them precisely)
- **Trigger conditions**: what inputs or system state are needed to hit this path

List at least one candidate, at most five. Rank by confidence.

## Phase 4 — Validate top hypotheses

For the top 1–2 candidates, do an additional validation pass:
- Search for any existing guard clauses, nil checks, or error handling that might already
  prevent the bug — if found, lower the confidence or remove the candidate
- Look for test files that cover this path — if existing tests should catch this bug
  but don't, note why (e.g. test uses a mock that hides the issue)
- If the repo context describes canonical patterns for this area, check whether the
  buggy code deviates from them

## Output

Write your findings to ~/.claude/bugs/<short-name>/investigation.md:

```md
# Bug Investigation

> Investigated: <today's date>

## Repo scope
[Which repo(s) are involved and why]

## Observable failure
- **Symptom:** [exact error or wrong behaviour]
- **Trigger conditions:** [what inputs or state causes it]
- **Frequency:** [always / intermittent / under specific load]

## Execution path
[Brief trace from entry point to failure site — file:line for each key step]

## Probable root causes

### 1. <Title> — <HIGH/MEDIUM/LOW confidence>
**Location:** `path/to/file.ext:line-range`
**Mechanism:** [precise causal chain from trigger to symptom]
**Trigger conditions:** [specific inputs or state needed]
**Evidence:** [code lines or pattern found]

[Repeat for each candidate, ranked by confidence]

## Validation notes
[Results of Phase 4 — any guards or tests found that affect confidence]

## Recommended fix direction
[1–2 sentences pointing at the most likely fix, naming the specific location]
```
```

---

**Subagent B — Failing test writer:**

```
You are writing a failing test (or tests) that will verify when a bug has been fixed.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file to understand the bug.

## Context gathering

1. Identify the current repo and tech stack: read package.json, pyproject.toml, go.mod,
   Podfile, build.gradle, Cargo.toml, or equivalent.
2. Run `git ls-files | head -100` to understand the project structure.
3. Find existing test files to understand the project's testing conventions — location,
   naming patterns, frameworks used (e.g. XCTest, Jest, pytest, go test).
4. If the working directory contains /work/, check ~/.claude/repo-context/<repo-name>.md
   for testing patterns.

## Test writing

Write one primary failing test that directly verifies the bugfix. The test must:
- Fail now (before the fix)
- Pass once the bug is correctly fixed
- Be as isolated and focused as possible
- Follow the project's existing test conventions exactly

You may also add up to 3 additional tests if they cover clearly related missing test cases
(e.g. edge cases of the same code path). Mark the primary test clearly.

Add the tests to the appropriate test file(s) in the codebase. If no suitable test file
exists, create one following the project's conventions.

Do not implement any fix — only tests.

## Output

Write a summary to ~/.claude/bugs/<short-name>/failing-test.md:

```md
# Failing Tests

> Written: <today's date>

## Primary test
**File:** `path/to/test/file`
**Test name:** `<test name>`
**What it verifies:** [what condition proves the bug is fixed]

## Additional tests (if any)
[List file, name, and purpose for each additional test]

## How to run
[Exact command to run only these tests]
```
```

---

## Step 4 — Verify failing tests automatically

After both subagents have finished, run the exact command from the "How to run" section of
`~/.claude/bugs/<short-name>/failing-test.md` to confirm the tests fail before any fix is applied.

- If the tests **fail as expected** → report the root cause candidates and test locations
  to the user, then proceed automatically to Step 5.
- If the tests **unexpectedly pass** → stop and report:
  "The failing tests passed before any fix — the bug may already be fixed, or the tests may
  not be targeting the right code path. Review failing-test.md before proceeding."
  Do not continue to Step 5.

## Step 5 — Spawn fix subagent

Spawn a single **foreground** subagent (`subagent_type: general-purpose`) and **wait for it
to finish**.

```
You are implementing a bugfix.

Bug:           ~/.claude/bugs/<short-name>/bug.md
Investigation: ~/.claude/bugs/<short-name>/investigation.md
Failing tests: ~/.claude/bugs/<short-name>/failing-test.md

Read all three files. Then read the code at the locations identified in the investigation.

## Fix

Implement the minimal fix that:
1. Makes the primary failing test pass
2. Does not break any existing tests
3. Addresses the root cause identified in the investigation (prefer the HIGH-confidence
   candidate unless there is a clear reason not to)
4. Follows the existing code conventions in the file(s) you edit

Do not refactor beyond what is necessary to fix the bug. Do not add features. Do not change
unrelated code.

## Verification

After making changes, re-read the affected code and the test to confirm the fix is logically
correct. Then run tests automatically:

1. Run the exact command from the "How to run" section of failing-test.md (the focused
   command targeting only the written test files).
2. If you modified any other test files during the fix, run those too.
3. Do not run the full test suite — limit scope to the touched test files only.

Report pass/fail in fix.md.

## Output

Write a summary to ~/.claude/bugs/<short-name>/fix.md:

```md
# Fix Summary

> Implemented: <today's date>

## Root cause addressed
[Which candidate from investigation.md was fixed and why it was chosen]

## Changes made
| File | Lines | Change |
|------|-------|--------|
| `path/to/file.ext` | L42–L55 | [brief description] |

## Why this fixes it
[1–3 sentences explaining the mechanism of the fix]
```
```

## Step 6 — Spawn 3 review subagents in parallel

After the fix subagent has finished, spawn **3 subagents in the same response**
(`subagent_type: general-purpose`) and **wait for all 3 to finish** before continuing.

---

**Reviewer 1 — Correctness:**

```
You are reviewing a bugfix for correctness.

Bug:    ~/.claude/bugs/<short-name>/bug.md
Fix:    ~/.claude/bugs/<short-name>/fix.md
Tests:  ~/.claude/bugs/<short-name>/failing-test.md

Read all three files. Then read the changed files listed in fix.md.

Assess:
1. Does the fix actually address the root cause? Could the bug still occur under a different
   code path or input?
2. Are there edge cases the fix misses — boundary values, null/nil inputs, concurrent access,
   empty collections?
3. Does the fix introduce any regressions — could it break existing behaviour that tests
   don't cover?
4. Are the new tests actually sufficient to catch the bug? Could the tests pass even with
   a wrong fix (false confidence)?

Use severity flags CRITICAL / HIGH / LOW on each finding. Cite file and line numbers. If no
issues are found, state that explicitly.
```

---

**Reviewer 2 — Security:**

```
You are reviewing a bugfix for security regressions or newly introduced vulnerabilities.

Bug:  ~/.claude/bugs/<short-name>/bug.md
Fix:  ~/.claude/bugs/<short-name>/fix.md

Read both files. Then read the changed files listed in fix.md.

Assess:
1. Does the fix introduce any injection risks (SQL, command, XSS, path traversal)?
2. Does it expose sensitive data or weaken authentication / authorisation checks?
3. Does it bypass input validation that was there for a reason?
4. Does it introduce insecure defaults, hardcoded secrets, or unsafe deserialization?

Use severity flags CRITICAL / HIGH / LOW on each finding. If no issues are found, state that
explicitly.
```

---

**Reviewer 3 — Code quality and pattern consistency:**

```
You are reviewing a bugfix for code quality and consistency with existing patterns.

Bug:  ~/.claude/bugs/<short-name>/bug.md
Fix:  ~/.claude/bugs/<short-name>/fix.md

Read both files. Then read the changed files listed in fix.md.

1. Detect the repo name from the working directory.
2. Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the design
   patterns section.
3. Use Grep to find 1–2 other files in the same area of the codebase for style reference.

Assess:
- Does the fix follow the same patterns as surrounding code (naming, error handling,
  abstractions)?
- Is the fix unnecessarily complex — could it be simpler while still being correct?
- Does it introduce duplication that should use an existing utility or abstraction?
- Are there any naming, formatting, or structural issues that would fail a code review?

Use severity flags CRITICAL / HIGH / LOW on each finding. Reference specific existing files
as examples when flagging pattern deviations. If no issues are found, state that explicitly.
```

---

## Step 7 — Write review-findings.md and present summary

After all 3 reviewers return, collect their findings and write
`~/.claude/bugs/<short-name>/review-findings.md`:

```md
# Review Findings

> Generated: <today's date>
> Bug: <short-name>

## Findings

### F01 — <Short title>
- **Source:** Correctness / Security / Code Quality (<severity>)
- **Finding:** <1-2 sentence description>
- **Files:** `path/to/file.ext:line-range`
- **Suggested fix:** <brief description of what to change>

[Repeat for each finding worth acting on — skip informational observations]

## No Action Needed

| Finding | Reviewer | Severity | Rationale |
|---------|----------|----------|-----------|
| [brief description] | Correctness | LOW | [why no action needed] |
```

> **CRITICAL WARNING:** If any CRITICAL finding exists, highlight it prominently at the top of
> the file before the Findings section.

Then present the consolidated summary to the user:

```md
## Bugfix Review Complete

### Correctness
[Reviewer 1 findings, or "No issues found"]

### Security
[Reviewer 2 findings, or "No issues found"]

### Code Quality
[Reviewer 3 findings, or "No issues found"]

---

**Branch:** `<branch name>`
**Bug folder:** `~/.claude/bugs/<short-name>/`

Apply any CRITICAL or HIGH findings before opening a PR.
Review findings are saved to ~/.claude/bugs/<short-name>/review-findings.md
```

## Rules

- Do not implement the fix in Step 3 — Step 3 subagents investigate and write tests only
- The fix in Step 5 must be minimal — no refactoring beyond what is necessary
- All files are written under `~/.claude/bugs/<short-name>/`
- Completed bugs may be moved to `~/.claude/bugs/done/<short-name>/` once the PR is merged
