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

---

## Step 4 — Verify failing tests

After both subagents have finished, check `bug.md` for `> Tests: auto` or
`> Tests: manual`.

**If `auto` (or no preference is recorded):**

Run the exact command from the "How to run" section of
`~/.claude/bugs/<short-name>/failing-test.md` to confirm the tests fail
before any fix is applied.

**Then evaluate the result:**

- If the tests **fail as expected** → report the root cause candidates
and test locations to the user, then proceed automatically to Step 5.
- If the tests **unexpectedly pass** → stop and report:
_"The failing tests passed before any fix — the bug may already be
fixed, or the tests may not be targeting the right code path. Review
failing-test.md before proceeding."_
Do not continue to Step 5.

**If `manual`:**
Skip step 4


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
``` 

## Step 6 — Delegate to /review-code in a foreground subagent

After the fix is verified, spawn one foreground subagent
(`subagent_type: general`) and wait for it to finish. The subagent invokes
the `/review-code` skill, which in turn launches 3 sub-agents in parallel.
Running `/review-code` inside a subagent keeps the main session's context
small — only the synthesized findings come back, not the full review
transcripts.

Prompt:

```
You are running a code review for a bugfix.

Bug folder: ~/.claude/bugs/<short-name>/

## Context

Read the following before starting:
- bug.md — bug description, working directory, test preference
- investigation.md — root cause analysis
- fix.md — the fix that was applied
- failing-test.md — the tests written to verify the fix

Use the **Working directory** field in bug.md to determine where to run
git commands and read source files from.

## Task

Invoke the `/review-code` skill. It will launch 3 sub-agents in parallel:
1. **Behavior Verification** — confirms the fix exhibits the expected
   behavior described in fix.md and failing-test.md, and flags any
   behavior drift or unclaimed behavior introduced by the fix
2. **Contextual Review** — reviews with full bug context (bug.md,
   investigation.md, fix.md, failing-test.md)
3. **Pattern Consistency** — verifies the fix follows existing codebase
   patterns

Feed `/review-code` the bug context above as its spec source (the
acceptance criteria equivalent is: the fix described in fix.md should
make the tests in failing-test.md pass, without behavior drift).

Wait for `/review-code` to complete.

## Write review-fixes.md

Synthesize the 3 sub-agent outputs and write
`~/.claude/bugs/<short-name>/review-fixes.md` directly:

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

Rules:
- Assign stable F-ids (F01, F02, …) in the order you list findings.
- Deduplicate: if two agents raised the same issue, merge into one
  finding and list both sources.
- Drop informational observations from the Findings section — put them
  in the No Action Needed table with a one-line rationale.
- If any CRITICAL finding exists, add a prominent warning block at the
  top of the file before the Findings section.
- Keep all lines ≤ 140 characters.

## Output

Return a concise summary to the orchestrator:
- Counts by severity (CRITICAL / HIGH / LOW).
- A one-line note confirming review-fixes.md was written.
- A one-line headline per CRITICAL finding, if any.

Do not return the full findings — they are in review-fixes.md now and
the next subagent will read them from there.
```

Wait for the subagent to finish, then present the one-line summary it
returned (e.g. "Review complete: 2 CRITICAL, 3 HIGH, 1 LOW — see
review-fixes.md").

## Step 7 — Delegate fix execution to a single subagent

Present a brief summary of findings grouped by severity (from the review
subagent's report):

```
CRITICAL: N findings
HIGH: N findings
LOW: N findings
```

Tell the user the fix subagent will now judge and apply findings
automatically, and that they can still interrupt if they want to force a
specific finding to be skipped.

Do not pre-filter findings. The fix subagent reads every finding from
`review-fixes.md` itself, weighs it against the full bug context (bug.md,
investigation.md, fix.md, failing-test.md), and decides which ones warrant
a code change, which are already satisfied, and which should be rejected
as incorrect or out-of-scope. If the user has proactively asked to
force-skip specific findings, pass those in the prompt as `forced-skip`
so the subagent leaves them alone and marks them Excluded.

Spawn one foreground subagent (`subagent_type: general`) and wait for it
to finish. The subagent owns the entire execution phase: judging each
finding, applying the fixes it accepts, running tests, and updating
`review-fixes.md` with per-finding status. One agent sees the whole
picture and applies the fixes coherently, rather than splitting work
across per-file sub-subagents.

Prompt:

```
You are triaging and applying code-review findings for a bugfix.

Bug folder: ~/.claude/bugs/<short-name>/

## Inputs

All findings (you decide which to apply):
<for each finding in review-fixes.md>
- F<id>: <finding description>
  Source: <agent name>
  Severity: <severity>
  Files: <file paths>
  Suggested fix: <suggestion>
</for each>

Forced-skip findings (the user explicitly told the orchestrator not to
touch these — do not apply, mark as Excluded with the user's reason):
<for each forced-skip finding>
- F<id>: <finding description> — reason: <user's reason>
</for each>

Bug files you MUST read before judging findings:
- bug.md — bug description, working directory, and test preference (auto/manual)
- investigation.md — root cause analysis
- fix.md — the fix that was applied
- failing-test.md — the tests written to verify the fix
- review-fixes.md — the finding list you are updating

## Execution

1. **Read all context first.** Read bug.md, investigation.md, fix.md, and
   failing-test.md in full. Then read the source files referenced by the
   findings. Do not start editing until you understand what was fixed and
   why.

2. **Judge each finding.** For every finding (except forced-skip ones),
   decide independently whether to apply it. A finding should be applied
   when it identifies a real defect, regression, missing case, or
   meaningful quality issue in the fix. A finding should be rejected when
   it is:
   - Incorrect (misreads the code, based on a faulty assumption, or
     contradicted by the investigation or existing tests)
   - Already satisfied by the current code (the reviewer missed something)
   - Out of scope for this bugfix (unrelated refactor, speculative
     hardening, stylistic preference that fights existing conventions)
   - In direct conflict with a higher-severity finding you are applying
   - Demanding behavior the bug report and investigation explicitly do
     not call for

   Use the bug context, not just the finding text, to make the call.
   Severity is a signal, not a mandate — a LOW finding with a real defect
   still gets applied; a CRITICAL finding based on a misread does not.

3. **Apply accepted fixes.** Work through the accepted findings and change
   the code to address each one. Group related findings in the same file
   into a single coherent edit pass — do not make multiple passes over the
   same file if one pass will do. If two accepted findings conflict,
   prefer the higher-severity one and note the conflict in
   review-fixes.md.

4. **Respect scope.** Do not change anything beyond what the accepted
   findings require. If a fix requires writing a missing test, follow
   existing test conventions in the repo. Do not create commits — only
   make the changes.

5. **Run tests.** Check bug.md for `> Tests:`.

   If `auto` (or no preference): after all edits land, run only the test
   files touched during this step:
   - Collect all files modified.
   - Filter to test files (files in test directories, or matching *.test.*,
     *_test.*, *Spec.*, *Tests.* conventions).
   - If test files were directly modified, run those. If only source files
     were modified, identify and run the test files most closely associated
     with the changed source files (same module, adjacent test directory).
   - Do not run the full test suite — limit scope to touched test files.

   If tests pass, proceed. If tests fail and the failure is caused by a
   fix, correct it and re-run (max 3 attempts). If still failing, record
   the failure in review-fixes.md under the relevant finding's status and
   move on.

   If `manual`: skip running tests — the orchestrator will prompt the user
   to run them. List the test files you modified so the orchestrator can
   share that list.

6. **Update review-fixes.md.** For every finding, add a Status line with
   the decision you made. Use one of: Fixed, Rejected, Excluded, Failed.
   Always explain Rejected and Excluded so the user can audit the call.

   ```md
   ### F01 — <Short title>
   - **Source:** <Agent name> (<severity>)
   - **Finding:** <description>
   - **Files:** <file paths>
   - **Status:** Fixed
                 / Rejected — <why the finding does not apply>
                 / Excluded — <user's forced-skip reason>
                 / Failed — <what went wrong>
   ```

## Output

Return a concise report to the orchestrator containing:
- A changelog table (one row per finding) with columns: F-id, brief
  description, severity, status.
- For every Rejected finding, a one-line rationale so the user can
  challenge the call if they disagree.
- Test summary (pass/fail counts, any lingering failures), or the list of
  modified test files if tests are `manual`.

Do not re-describe the fixes in detail — the Edit history and
review-fixes.md already capture that.

Wait for the subagent to finish.

## Step 8 — Verify tests (manual only)

If `> Tests: manual` in `bug.md`, prompt the user to run the relevant tests
now. Use the list of modified test files reported by the subagent. Wait for
the user to share the output. Diagnose any failures and fix them.

If tests are `auto`, the subagent already ran them — proceed to Step 9.

## Step 9 — Present summary

Present the summary:

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
