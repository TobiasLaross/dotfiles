---
name: bugfix
description: Investigate a bug, write a failing test, then implement and review a fix. Use when the user runs /bugfix with an optional ticket number and description.
argument-hint: [ticket-number] <bug description>
---

# Bugfix Workflow

The user has invoked `/bugfix`. Follow this workflow exactly.

## Step 1 — Parse arguments and create bug folder

Parse `$ARGUMENTS` to extract:

1. **Ticket number** — the first token if it is either:
   - A plain integer (e.g. `42`, `1234`)
   - A Jira-style ticket (one or more uppercase letters, a hyphen, then digits — e.g. `SER-1234`, `PROJ-42`)
   If the first token matches either form, store it as `<ticket>`. Otherwise `<ticket>` is empty and the entire argument string is the description.

2. **Description** — everything after the ticket number (or the full `$ARGUMENTS` if no ticket was found).

3. **Short name** — derive a kebab-case slug from the description: 2–4 lowercase words, no special characters (e.g. `nil-pointer-on-login`, `missing-auth-header`). This becomes the folder name.

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

## Step 2 — Spawn investigation and test subagents in parallel

Spawn **2 subagents in the same response** (`subagent_type: general-purpose`) and **wait for both to finish** before continuing.

---

**Subagent A — Root cause investigator:**

```
You are investigating a bug to identify its potential root causes.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file to understand the bug.

## Repo detection

Identify the current repo from the working directory name.

If the working directory contains /work/, list all directories in ~/Developer/work/. For each relevant repo:
1. Check for a pre-built context file: `~/.claude/repo-context/<repo-name>.md`. If it exists, read the architecture and design patterns sections. Prefer this over reading source.
2. If no context file exists, read README.md and the main entry points to understand the codebase.

The bug might span multiple repos. Use the repo-context "External communication" and "Internal repo dependencies" sections to trace the call chain if needed.

## Investigation

Search the codebase for the code paths involved in this bug. Use Grep and Glob to locate relevant files. Read the suspicious areas of code.

Identify the **potential root causes** — not just symptoms. For each candidate:
- **Location**: file path and line range
- **Mechanism**: how this code path leads to the observed bug
- **Confidence**: HIGH / MEDIUM / LOW
- **Evidence**: what you found in the code that supports this

List at least one candidate, at most five. Rank by confidence.

## Output

Write your findings to ~/.claude/bugs/<short-name>/investigation.md:

```md
# Bug Investigation

> Investigated: <today's date>

## Repo scope
[Which repo(s) are involved and why]

## Potential root causes

### 1. <Title> — <HIGH/MEDIUM/LOW confidence>
**Location:** `path/to/file.ext:line-range`
**Mechanism:** [how this causes the bug]
**Evidence:** [what you found]

[Repeat for each candidate, ranked by confidence]

## Recommended fix direction
[1–2 sentences pointing at the most likely fix based on the above]
```
```

---

**Subagent B — Failing test writer:**

```
You are writing a failing test (or tests) that will verify when a bug has been fixed.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file to understand the bug.

## Context gathering

1. Identify the current repo and tech stack: read package.json, pyproject.toml, go.mod, Podfile, build.gradle, Cargo.toml, or equivalent.
2. Run `git ls-files | head -100` to understand the project structure.
3. Find existing test files to understand the project's testing conventions — location, naming patterns, frameworks used (e.g. XCTest, Jest, pytest, go test).
4. If the working directory contains /work/, check ~/.claude/repo-context/<repo-name>.md for testing patterns.

## Test writing

Write one primary failing test that directly verifies the bugfix. The test must:
- Fail now (before the fix)
- Pass once the bug is correctly fixed
- Be as isolated and focused as possible
- Follow the project's existing test conventions exactly

You may also add up to 3 additional tests if they cover clearly related missing test cases (e.g. edge cases of the same code path). Mark the primary test clearly.

Add the tests to the appropriate test file(s) in the codebase. If no suitable test file exists, create one following the project's conventions.

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

## Step 3 — Pause for manual test verification

After both subagents have finished, output the following to the user (fill in actual values):

```
Both subagents are done.

**Investigation summary:** Read ~/.claude/bugs/<short-name>/investigation.md for root cause candidates.
**Failing tests written:** Read ~/.claude/bugs/<short-name>/failing-test.md for the test locations and run command.

Please run the failing tests now to confirm they fail as expected.

Say **continue** (or **resume**) when you are ready to proceed with the fix.
```

Then **stop and wait**. Do not proceed until the user replies with "continue", "resume", "go", "proceed", or similar confirmation.

## Step 4 — Spawn fix subagent

Once the user confirms, spawn a single **foreground** subagent (`subagent_type: general-purpose`) and **wait for it to finish**.

```
You are implementing a bugfix.

Bug:          ~/.claude/bugs/<short-name>/bug.md
Investigation: ~/.claude/bugs/<short-name>/investigation.md
Failing tests: ~/.claude/bugs/<short-name>/failing-test.md

Read all three files. Then read the code identified in the investigation.

## Fix

Implement the minimal fix that:
1. Makes the primary failing test pass
2. Does not break any existing tests
3. Addresses the root cause identified in the investigation (prefer the HIGH-confidence candidate unless there is a clear reason not to)
4. Follows the existing code conventions in the file(s) you edit

Do not refactor beyond what is necessary to fix the bug. Do not add features. Do not change unrelated code.

## Verification

After making changes, re-read the affected code and the test to confirm the fix is logically correct. If the tech stack supports running tests without side effects, you may run the failing test command from failing-test.md to verify.

## Output

Write a summary to ~/.claude/bugs/<short-name>/fix.md:

```md
# Fix Summary

> Implemented: <today's date>

## Root cause addressed
[Which candidate from investigation.md was fixed and why it was chosen]

## Changes made
| File | Change |
|------|--------|
| `path/to/file.ext` | [brief description] |

## Why this fixes it
[1–3 sentences explaining the mechanism of the fix]
```
```

## Step 5 — Spawn 3 review subagents in parallel

After the fix subagent has finished, spawn **3 subagents in the same response** (`subagent_type: general-purpose`) and **wait for all 3 to finish** before continuing.

---

**Reviewer 1 — Correctness:**

```
You are reviewing a bugfix for correctness.

Bug:    ~/.claude/bugs/<short-name>/bug.md
Fix:    ~/.claude/bugs/<short-name>/fix.md
Tests:  ~/.claude/bugs/<short-name>/failing-test.md

Read all three files. Then read the changed files listed in fix.md.

Assess:
1. Does the fix actually address the described bug? Could the bug still occur under a different code path or input?
2. Are there edge cases the fix misses — boundary values, null/nil inputs, concurrent access, empty collections?
3. Does the fix introduce any regressions — could it break existing behaviour that tests don't cover?
4. Are the new tests actually sufficient to catch the bug? Could the tests pass even with a wrong fix?

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite file and line numbers where possible.
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

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. If no issues are found, state that explicitly.
```

---

**Reviewer 3 — Code quality and pattern consistency:**

```
You are reviewing a bugfix for code quality and consistency with existing patterns.

Bug:  ~/.claude/bugs/<short-name>/bug.md
Fix:  ~/.claude/bugs/<short-name>/fix.md

Read both files. Then read the changed files listed in fix.md.

1. Detect the repo name from the working directory.
2. Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the design patterns section.
3. Use Grep to find 1–2 other files in the same area of the codebase for style reference.

Assess:
- Does the fix follow the same patterns as surrounding code (naming, error handling, abstractions)?
- Is the fix unnecessarily complex — could it be simpler while still being correct?
- Does it introduce duplication that should use an existing utility or abstraction?
- Are there any naming, formatting, or structural issues that would fail a code review?

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Reference specific existing files as examples when flagging pattern deviations.
```

---

## Step 6 — Present review and finish

After all 3 reviewers return, collect their findings and present a consolidated summary to the user:

```md
## Bugfix Review Complete

### Correctness
[Reviewer 1 findings, or "No issues found"]

### Security
[Reviewer 2 findings, or "No issues found"]

### Code quality
[Reviewer 3 findings, or "No issues found"]

---

**Branch:** `<branch name>`
**Bug folder:** `~/.claude/bugs/<short-name>/`

Apply any CRITICAL or HIGH findings before opening a PR.
```

## Rules

- Never skip Step 3 — the user must manually confirm before the fix is implemented
- Do not implement the fix in Step 2 — Step 2 subagents write tests only
- The fix in Step 4 must be minimal — no refactoring beyond what is necessary
- All files are written under `~/.claude/bugs/<short-name>/`
- Completed bugs may be moved to `~/.claude/bugs/done/<short-name>/` once the PR is merged
