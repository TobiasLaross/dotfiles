---
name: feature-code-fix
description: >-
  Apply fixes from a feature code review, batched by file, with test verification. Use after
  /feature-code-review — or any time review-fixes.md exists and the user wants the findings
  addressed, even if they just say "fix it" or "apply the review". Unchecks Action Required
  in story.md for every criterion whose findings were resolved, closing the review cycle
  before /feature-done.
argument-hint: [feature-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Feature Code Fix Workflow

The user has invoked `/feature-code-fix`. Follow this workflow exactly.

This skill triages review findings **with the user** in the main session, then
delegates the actual execution — applying fixes, running tests, updating the
`Action Required` checkbox in `story.md`, and updating `review-fixes.md` — to a
single subagent. Triage is interactive (questions for the user), execution is
autonomous (no user input needed). Splitting them lets the main session stay
clean and the subagent run to completion without interruption.

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

## Step 2 — Read review findings

Read `~/.claude/features/<name>/review-fixes.md`. If it does not exist, tell
the user to run `/feature-code-review <name>` first and stop.

Also read `~/.claude/features/<name>/story.md` and `design.md` for context
(user story, discovery decisions, acceptance criteria, and any prior
implementation decisions).

## Step 3 — Triage findings with the user

Present a summary of all findings grouped by severity:

```
CRITICAL: N findings
HIGH: N findings
LOW: N findings
```

Ask the user: _"Apply all findings, or would you like to exclude any?"_

If the user wants to exclude some, note which ones. For excluded CRITICAL
findings, warn explicitly that a known critical risk will remain. Record the
final accept/exclude decision for each finding — you will pass this to the
execution subagent.

Triage is the **only** interactive step in this flow. Once the user confirms
the triage outcome, everything else runs inside the subagent.

## Step 4 — Delegate execution to a single subagent

Spawn one foreground subagent (`subagent_type: general`) and wait for it to
finish. The subagent owns the entire execution phase: applying fixes,
running tests, updating `story.md` (Action Required checkboxes), and
updating `review-fixes.md` with per-finding status. The main session does
not split work across per-file sub-subagents — one agent sees the whole
picture and applies the fixes coherently.

Prompt:

```
You are executing a batch of approved code-review fixes for a feature.

Feature folder: ~/.claude/features/<name>/

## Inputs

Accepted findings (apply these):
<for each accepted finding>
- F<id>: <finding description>
  Severity: <severity>
  Criterion: <short criterion title this finding relates to, or "General">
  Files: <file paths>
  Suggested fix: <suggestion>
</for each>

Excluded findings (do NOT apply, but still update status):
<for each excluded finding>
- F<id>: <finding description> — reason: <user's reason, or "user declined">
</for each>

Feature files you should read as needed:
- story.md — acceptance criteria with per-criterion Action Required boxes
- design.md — prior implementation decisions (append a new entry here if
  you make a non-obvious choice while applying a fix)
- review-fixes.md — the finding list you are updating

## Execution

1. **Read the files you need.** Start with the source files mentioned by
   the accepted findings. Read enough surrounding context to apply each fix
   correctly.

2. **Apply fixes.** Work through the accepted findings and change the code
   to address each one. Group related findings in the same file into a
   single coherent edit pass — do not make multiple passes over the same
   file if one pass will do. If two findings conflict, prefer the higher
   severity one and note the conflict in review-fixes.md.

3. **Respect scope.** Do not change anything beyond what the findings
   require. If a fix requires writing a missing test, follow existing test
   conventions in the repo.

4. **Log non-obvious decisions.** If applying a fix forces a design
   choice (e.g. choosing between two valid fixes, introducing a new
   abstraction, rejecting the suggested fix for a concrete reason), append
   an entry to design.md using the entry format at the bottom of that file.
   Tag the entry's Source as "feature-code-fix F<id>".

5. **Run tests.** After all edits land, run only the test files touched
   during this step:
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

6. **Update story.md — uncheck Action Required.** For each acceptance
   criterion that had findings in this batch, if **all** of its accepted
   findings are now Fixed (tests passed), uncheck its Action Required box:
   change `- [x] Action Required` to `- [ ] Action Required`. If any
   accepted finding for a criterion is Excluded or still Failing, leave
   Action Required checked. Group findings by the `Criterion:` field from
   review-fixes.md — "General" findings do not map to a single criterion
   and do not affect any Action Required box.

   Do NOT touch the `Implemented` or `Reviewed` checkboxes. Do NOT touch
   the top-level checkbox on the criterion line.

7. **Update review-fixes.md.** For every finding (accepted AND excluded),
   add a Status line. Use one of: Fixed, Excluded, Failed.

   ```md
   ### F01 — <Short title>
   - **Source:** <Agent name> (<severity>)
   - **Criterion:** <criterion title or "General">
   - **Finding:** <description>
   - **Files:** <file paths>
   - **Status:** Fixed / Excluded — <reason if excluded> / Failed — <why>
   ```

## Output

Return a concise report to the orchestrator containing:
- A changelog table (one row per finding) with columns: F-id, brief
  description, severity, status.
- The list of acceptance criteria whose Action Required box was unchecked.
- The list of criteria that still have Action Required checked and why.
- Test summary (pass/fail counts, any lingering failures).
- A note if any design.md entries were appended.

Do not re-describe the fixes in detail — the Edit history and
review-fixes.md already capture that.
```

Wait for the subagent to finish.

## Step 5 — Present changelog

Using the subagent's report, present:

```md
## Fix Changelog

| Fix | Finding | Severity | Status |
|-----|---------|----------|--------|
| F01 | [brief description] | CRITICAL/HIGH/LOW | Fixed |
| F02 | [brief description] | LOW | Excluded — [reason] |

**Criteria closed (Action Required unchecked):** <list, or "None">
**Criteria still open (Action Required still checked):** <list, or "None">
**Tests:** Passed / Failed (details)
**Design notes:** <any design.md entries appended, or "None">
```

> **CRITICAL WARNING:** If any CRITICAL finding was **Excluded**, highlight it
> here. The user must consciously acknowledge they are accepting a known critical
> risk.

Then prompt: _"Next step: run `/feature-done <name>` to mark this feature as
complete and move it to done. If any criterion still has Action Required
checked, `/feature-done` will block until it is resolved."_ (replace `<name>`
with the actual feature folder name).

## Rules

- Triage (accept/exclude) is the only step that takes user input — after that,
  execution runs autonomously in a single subagent
- The subagent is responsible for applying fixes, running tests, updating
  story.md's Action Required checkboxes, and updating review-fixes.md
- Never touch the `Implemented` or `Reviewed` checkboxes — those are owned by
  the implementation and review flows respectively
- A criterion's Action Required box may only be unchecked when all its
  accepted findings are Fixed; if any are Excluded or Failed, leave it
  checked so /feature-done can block on it
- Append to design.md whenever a fix forces a non-obvious design choice
- Lines in all markdown files must not exceed 140 characters
