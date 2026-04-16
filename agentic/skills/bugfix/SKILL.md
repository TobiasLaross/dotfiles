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
   - A Jira-style ticket (one or more uppercase letters, a hyphen, then
     digits — e.g. `SER-1234`, `PROJ-42`)
   If the first token matches either form, store it as `<ticket>`. Otherwise
   `<ticket>` is empty and the entire argument string is the description.

2. **Description** — everything after the ticket number (or the full
   `$ARGUMENTS` if no ticket was found).

3. **Short name** — derive a kebab-case slug from the description: 2–4
   lowercase words, no special characters (e.g. `nil-pointer-on-login`,
   `missing-auth-header`). This becomes the folder name.

4. **Branch name**:
   - With ticket: `bugfix/<ticket>_<short-name>`
     (e.g. `bugfix/42_nil-pointer-on-login`)
   - Without ticket: `bugfix/<short-name>`
     (e.g. `bugfix/nil-pointer-on-login`)

Create the folder (create `~/.claude/bugs/` if it does not exist yet):

```
~/.claude/bugs/<short-name>/
```

Touch the folder to trigger filesystem access approval early:
```sh
mkdir -p ~/.claude/bugs/<short-name>
touch ~/.claude/bugs/<short-name>/.gitkeep
```

## Step 1b — Create worktree

If the current working directory is a git repository and the user's initial
prompt did not explicitly request **no worktree**, create a worktree:

1. Determine the repo root and its parent directory:
   ```sh
   repo_root=$(git rev-parse --show-toplevel)
   repo_name=$(basename "$repo_root")
   parent_dir=$(dirname "$repo_root")
   ```
2. Derive the worktree path:
   - Worktree path: `$parent_dir/$repo_name--<short-name>`
3. Create the worktree:
   ```sh
   git worktree add \
     -b "<branch-name>" "$parent_dir/$repo_name--<short-name>"
   ```
   If the branch already exists, use:
   ```sh
   git worktree add \
     "$parent_dir/$repo_name--<short-name>" "<branch-name>"
   ```
4. Touch a file in the worktree to trigger access approval:
   ```sh
   touch "$parent_dir/$repo_name--<short-name>/.feature-touch"
   rm "$parent_dir/$repo_name--<short-name>/.feature-touch"
   ```

If the directory is not a git repo, skip worktree creation.

## Step 1c — Test preference

Ask the user:

_"Should tests be run automatically by the agent, or do you want to run
them manually and share the output?"_

Store the answer as `auto` or `manual`.

## Step 1d — Write bug.md

Write `~/.claude/bugs/<short-name>/bug.md`:

```md
# <Short descriptive title>

> Description: <description>
> Ticket: <ticket or "none">
> Branch: <branch name>
> Reported: <today's date>
> Working directory: <worktree path, or original repo if no worktree>
> Tests: <auto or manual>
> Worktree: <true or false>
> Worktree source: <original repo path, or omit if no worktree>

## Repo detection notes

[Leave blank — investigation agent fills this in]
```

## Step 2 — Gather context

Before spawning subagents, collect the following from the working
directory (the worktree path if one was created, otherwise the original
repo):

- **Repo name:** Derive from the working directory path (basename or
  last component before `/src`).
- **Repo context:** Check `~/.claude/repo-context/<repo-name>.md`.
  - **If it exists:** read it. This is **authoritative** for general
    repo structure, architecture, tech stack, test infrastructure,
    error handling conventions, and inter-repo dependencies. Store
    as `REPO_CONTEXT`. Skip the Tech stack step below.
  - **If not found:** create one by spawning a subagent
    (`subagent_type: explore`, thoroughness: `very thorough`) to
    explore the codebase and write
    `~/.claude/repo-context/<repo-name>.md`. Wait for it, then read
    the result. Store as `REPO_CONTEXT`. Skip the Tech stack step
    below.
- **Tech stack (only if no repo-context):** Read `package.json`,
  `pyproject.toml`, `go.mod`, `Podfile`, `build.gradle`,
  `Cargo.toml`, or equivalent. Fall back to file extensions. Store
  as `TECH_STACK`. This is a fallback — the repo-context file
  already contains language, stack, and test setup information.
- **Keyword pre-filtering:** Extract 3-6 key terms from the bug
  description (error messages, function names, module names, symptoms).
  Run targeted greps for each keyword in the working directory using
  the Grep tool directly (not a subagent). Collect the matched file
  paths and deduplicate. Store as `STARTING_POINTS`.
- **Work repos:** If the working directory contains `/work/`, list all
  directories in `~/Developer/work/` to understand what other repos
  might be involved.

Store all of this. You will inject it into the investigation subagent.

> **Note:** Do NOT run `git ls-files | head -100` for project
> structure — the repo-context file already covers this. Only fall
> back to `git ls-files` if no repo-context file exists and you could
> not create one.

## Step 3 — Spawn investigation and test subagents in parallel

Spawn **2 subagents in the same response** (`subagent_type: general`) and
**wait for both to finish** before continuing.

---

**Subagent A — Root cause investigator:**

```
You are investigating a bug to identify its probable root causes.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file first to understand the bug description. Use the
**Working directory** field to determine which directory to work in.

Repo context: [REPO_CONTEXT — paste the full content, or "Not
available"]
Tech stack: [TECH_STACK — only if no repo-context file existed.
Otherwise omit — tech stack is already in the repo context above.]

## Starting points (from keyword search)

These files matched keywords from the bug description. Start here:
[STARTING_POINTS — list each file with its matched keyword]

Read these files first. Only explore beyond them if you cannot trace
the execution path from these files alone.

## Repo-context trust

The repo context above is authoritative for general repo structure,
architecture, test infrastructure, and error handling conventions.
Do NOT re-explore these general topics. Focus exclusively on tracing
the bug-specific execution path.

## Phase 1 — Map the observable failure

Before reading any code, write down precisely:
- What is the observable symptom? (error message, wrong value, crash,
  hang, missing behaviour)
- Under what conditions does it occur? (specific input, user action,
  system state, race condition)
- What is the expected behaviour vs the actual behaviour?
- Is this always reproducible, or intermittent?

## Phase 2 — Trace the execution path

Follow the code from the triggering entry point (API handler, UI event,
cron job, etc.) through to the failure site. Use Grep and Glob to locate
the relevant files.

For each step in the chain, note:
- File path and line range
- What the code does at that step
- Whether the step looks correct

Continue until you reach the site where the behaviour diverges from
expectation. If the bug spans multiple repos, follow the call chain
across repo boundaries using the "External communication" and "Internal
repo dependencies" sections of the repo-context.

## Phase 3 — Generate root cause hypotheses

Based on Phase 2, identify the **probable root causes** — not just
symptoms. For each candidate:
- **Title**: short descriptive name
- **Location**: `file:line-range`
- **Mechanism**: the specific sequence of events that produces the
  observed symptom — be precise (e.g. "when X is nil, Y dereferences
  it at line 42, causing a nil pointer panic" rather than "possible
  nil pointer issue")
- **Confidence**: HIGH / MEDIUM / LOW
- **Evidence**: the exact code or pattern you found that supports this
  hypothesis (quote the relevant lines if short enough, otherwise
  describe them precisely)
- **Trigger conditions**: what inputs or system state are needed to
  hit this path

List at least one candidate, at most five. Rank by confidence.

## Phase 4 — Validate top hypotheses

For the top 1–2 candidates, do an additional validation pass:
- Search for any existing guard clauses, nil checks, or error handling
  that might already prevent the bug — if found, lower the confidence
  or remove the candidate
- Look for test files that cover this path — if existing tests should
  catch this bug but don't, note why (e.g. test uses a mock that hides
  the issue)
- If the repo context describes canonical patterns for this area, check
  whether the buggy code deviates from them

## Constraints

- Complete your investigation in **15 tool calls or fewer**.
  Prioritize reading files from the starting points list.
- When you need to read multiple independent files, read them in a
  single **parallel batch** rather than sequentially.
- If you search for a pattern or concept and find zero matches after
  2 attempts (e.g. a broader grep and a glob), **stop**. Report it
  as "not found in codebase" and move on.

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
[Brief trace from entry point to failure site — file:line for each
key step]

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
[1–2 sentences pointing at the most likely fix, naming the specific
location]
```
```

---

**Subagent B — Failing test writer:**

```
You are writing a failing test (or tests) that will verify when a bug
has been fixed.

Bug file: ~/.claude/bugs/<short-name>/bug.md

Read that file to understand the bug. Use the **Working directory**
field to determine which directory to work in.

## Context gathering

1. Check ~/.claude/repo-context/<repo-name>.md (derive repo name from
   the working directory). If it exists, treat it as **authoritative**
   for tech stack, test infrastructure, testing conventions, and
   framework choices. Skip steps 2 and 3 — go straight to Test
   writing.
2. (Only if no repo-context file exists) Identify the current repo
   and tech stack: read package.json, pyproject.toml, go.mod,
   Podfile, build.gradle, Cargo.toml, or equivalent.
3. (Only if no repo-context file exists) Find existing test files to
   understand the project's testing conventions — location, naming
   patterns, frameworks used (e.g. XCTest, Jest, pytest, go test).

## Test writing

Write one primary failing test that directly verifies the bugfix. The
test must:
- Fail now (before the fix)
- Pass once the bug is correctly fixed
- Be as isolated and focused as possible
- Follow the project's existing test conventions exactly

You may also add up to 3 additional tests if they cover clearly related
missing test cases (e.g. edge cases of the same code path). Mark the
primary test clearly.

Add the tests to the appropriate test file(s) in the codebase. If no
suitable test file exists, create one following the project's
conventions.

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

## Step 4 — Verify failing tests

After both subagents have finished, check `bug.md` for `> Tests: auto` or
`> Tests: manual`.

**If `auto` (or no preference is recorded):**

Run the exact command from the "How to run" section of
`~/.claude/bugs/<short-name>/failing-test.md` to confirm the tests fail
before any fix is applied.

**If `manual`:**

Prompt the user to run the tests. Show the exact command from the
"How to run" section of `failing-test.md`. Wait for the user to share
the output.

**Then evaluate the result:**

- If the tests **fail as expected** → report the root cause candidates
  and test locations to the user, then proceed automatically to Step 5.
- If the tests **unexpectedly pass** → stop and report:
  _"The failing tests passed before any fix — the bug may already be
  fixed, or the tests may not be targeting the right code path. Review
  failing-test.md before proceeding."_
  Do not continue to Step 5.

## Step 5 — Spawn fix subagent

Spawn a single **foreground** subagent (`subagent_type: general`) and
**wait for it to finish**.

```
You are implementing a bugfix.

Bug:           ~/.claude/bugs/<short-name>/bug.md
Investigation: ~/.claude/bugs/<short-name>/investigation.md
Failing tests: ~/.claude/bugs/<short-name>/failing-test.md

Read all three files. Use the **Working directory** field in bug.md to
determine which directory to work in. Then read the code at the
locations identified in the investigation.

## Fix

Implement the minimal fix that:
1. Makes the primary failing test pass
2. Does not break any existing tests
3. Addresses the root cause identified in the investigation (prefer the
   HIGH-confidence candidate unless there is a clear reason not to)
4. Follows the existing code conventions in the file(s) you edit

Do not refactor beyond what is necessary to fix the bug. Do not add
features. Do not change unrelated code.
Do not create commits — only make the changes.

## Verification

After making changes, re-read the affected code and the test to confirm
the fix is logically correct.

Check bug.md for `> Tests:`. If `auto` (or not specified):

1. Run the exact command from the "How to run" section of
   failing-test.md (the focused command targeting only the written
   test files).
2. If you modified any other test files during the fix, run those too.
3. Do not run the full test suite — limit scope to the touched test
   files only.

If `manual`: skip running tests — the user will run them.

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

## Step 5b — Verify fix (manual tests only)

If `> Tests: manual` in `bug.md`, prompt the user to run the tests now.
Show the exact command from `failing-test.md`. Wait for the user to share
the output.

- If tests **pass** → proceed to Step 6.
- If tests **fail** → diagnose and fix. If the failure is caused by the
  fix, correct it and ask the user to re-run. If unrelated, note it and
  proceed.

If tests are `auto`, the fix subagent already ran them — proceed to
Step 6.

## Step 6 — Delegate to /review-code

After the fix is verified, invoke the `/review-code` skill. All bug
context (bug.md, investigation.md, fix.md, failing-test.md) and the
changed files are already in the conversation — `/review-code` will use
them without re-collecting.

The review launches 3 sub-agents in parallel:
1. **Behavior Verification** — confirms the fix exhibits the expected
   behavior described in fix.md and failing-test.md, and flags any
   behavior drift or unclaimed behavior introduced by the fix
2. **Contextual Review** — reviews with full bug context (bug.md,
   investigation.md, fix.md, failing-test.md)
3. **Pattern Consistency** — verifies the fix follows existing codebase
   patterns

Wait for `/review-code` to complete and present its findings.

## Step 7 — Write review-fixes.md

After the review completes, collect the findings and write
`~/.claude/bugs/<short-name>/review-fixes.md`:

```md
# Review Findings

> Generated: <today's date>
> Bug: <short-name>

## Findings

### F01 — <Short title>
- **Source:** Behavior Verification / Contextual Review / Pattern Consistency
  (<severity>)
- **Finding:** <1-2 sentence description>
- **Files:** `path/to/file.ext:line-range`
- **Suggested fix:** <brief description of what to change>

[Repeat for each finding worth acting on — skip informational
observations]

## No Action Needed

| Finding | Agent | Severity | Rationale |
|---------|-------|----------|-----------|
| [brief description] | Behavior Verification | LOW | [why no action needed] |
```

> **CRITICAL WARNING:** If any CRITICAL finding exists, highlight it
> prominently at the top of the file before the Findings section.

Then present a summary grouped by severity and prompt:

_"Next step: run `/bugfix-fix <short-name>` to apply review fixes, or
review the findings in
`~/.claude/bugs/<short-name>/review-fixes.md` first."_

## Step 8 — Triage findings with the user

Present a summary of all findings grouped by severity:

```
CRITICAL: N findings
HIGH: N findings
LOW: N findings
```

Ask the user: _"Apply all findings, or would you like to exclude any?"_

If the user wants to exclude some, note which ones. For excluded CRITICAL
findings, warn explicitly that a known critical risk will remain.

## Step 9 — Batch and apply review fixes

Group accepted findings by file. For each file (or small group of related
files), spawn a subagent (`subagent_type: general`) to apply all fixes
for that file in a single pass.

Launch independent file groups in parallel. Files that depend on each
other (e.g., a function definition and its callers) should be handled by
the same subagent.

Each subagent receives:
```
You are applying code review fixes to specific files.

Bug folder: ~/.claude/bugs/<short-name>/
Fixes to apply:
<for each fix assigned to this subagent>
- F<id>: <finding description>
  Severity: <severity>
  Suggested fix: <suggestion>
</for each>

Files to change: <file paths>

## Instructions

1. Read the relevant files.
2. Apply all listed fixes in a single coherent pass.
3. If a fix involves writing a missing test, follow existing test
   conventions.
4. Do not change anything beyond what the findings require.
5. Do not create commits — only make the changes.
6. Verify your fixes are logically correct before finishing.
```

## Step 10 — Run tests after review fixes

After all fix subagents complete, check `bug.md` for `> Tests:`.

**If `auto` (or no preference):**

Run only the test files touched during this step:

1. Collect all files modified by the fix subagents.
2. Filter to test files (files in test directories, or files matching
   `*.test.*`, `*_test.*`, `*Spec.*`, `*Tests.*` conventions).
3. If test files were directly modified, run those. If only source files
   were modified, identify and run the test files most closely associated
   with the changed source files (same module, adjacent test directory,
   etc.).
4. Do not run the full test suite — limit scope to touched test files
   only.

- If tests pass: proceed to Step 11.
- If tests fail: diagnose and fix. If the failure is unrelated to the
  review fixes, note it and proceed. If it's caused by a fix, correct it.

**If `manual`:**

Prompt the user to run the relevant tests. List the test files written or
modified so they know what to run. Wait for the user to share the output.
Diagnose any failures and fix them.

## Step 11 — Update review-fixes.md and present summary

Update `~/.claude/bugs/<short-name>/review-fixes.md` to reflect what was
done. Change the findings section to include status:

```md
### F01 — <Short title>
- **Source:** <Agent name> (<severity>)
- **Finding:** <description>
- **Files:** <file paths>
- **Status:** Fixed / Excluded
```

Then present a changelog:

```md
## Fix Changelog

| Fix | Finding | Severity | Status |
|-----|---------|----------|--------|
| F01 | [brief description] | CRITICAL/HIGH/LOW | Fixed |
| F02 | [brief description] | LOW | Excluded — [reason] |

**Tests:** Passed / Failed (details)
```

> **CRITICAL WARNING:** If any CRITICAL finding was **Excluded**,
> highlight it here. The user must consciously acknowledge they are
> accepting a known critical risk.

Then present the final summary:

```md
## Bugfix Complete

**Branch:** `<branch name>`
**Bug folder:** `~/.claude/bugs/<short-name>/`
**Working directory:** `<worktree or repo path>`

All changes are local — no commits have been created.
Review the changes, then commit and open a PR when ready.
```

## Rules

- Do not implement the fix in Step 3 — Step 3 subagents investigate and
  write tests only
- The fix in Step 5 must be minimal — no refactoring beyond what is
  necessary
- Do not create commits — only make changes to files
- Do not push to remote
- Do not open pull requests
- All metadata files are written under
  `~/.claude/bugs/<short-name>/`
- Completed bugs may be moved to
  `~/.claude/bugs/done/<short-name>/` by the user
- Worktree naming convention: `<repo>--<short-name>` as a sibling of
  the original repo directory
- Worktree cleanup is the user's responsibility — run
  `git worktree remove <path>` from the source repo and kill the
  tmux session
- Lines in all markdown files must not exceed 140 characters
