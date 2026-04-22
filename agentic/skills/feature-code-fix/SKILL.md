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

This skill delegates the entire execution phase — judging findings, applying
fixes, running tests, updating the `Action Required` checkbox in `story.md`,
and updating `review-fixes.md` — to a single foreground subagent. The
subagent decides which findings warrant a code change and which do not,
recording its rationale in `review-fixes.md` so every finding has an
auditable outcome.

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

## Step 3 — Delegate execution to a single subagent

Present a brief summary of findings grouped by severity:

```
CRITICAL: N findings
HIGH: N findings
LOW: N findings
```

Tell the user the fix subagent will now judge and apply findings
automatically, and that they can interrupt if they want to force a
specific finding to be skipped.

Do not pre-filter findings. The fix subagent reads every finding from
`review-fixes.md` itself, weighs each against the full feature context
(story.md, design.md, acceptance criteria), and decides which warrant a
code change, which are already satisfied, and which should be rejected as
incorrect or out-of-scope. If the user has proactively asked to force-skip
specific findings, pass those in the prompt as `forced-skip` so the
subagent leaves them alone and marks them Excluded.

Spawn one foreground subagent (`subagent_type: general`) and wait for it
to finish. The subagent owns the entire execution phase: judging each
finding, applying the fixes it accepts, running tests, updating story.md
(Action Required checkboxes), and updating review-fixes.md with
per-finding status. One agent sees the whole picture and applies the
fixes coherently, rather than splitting work across per-file sub-subagents.

Prompt:

```
You are triaging and applying code-review findings for a feature.

Feature folder: ~/.claude/features/<name>/

## Inputs

All findings (you decide which to apply) — read them from review-fixes.md.

Forced-skip findings (the user explicitly told the orchestrator not to
touch these — do not apply, mark as Excluded with the user's reason):
<for each forced-skip finding>
- F<id>: <finding description> — reason: <user's reason>
</for each>

Feature files you MUST read before judging findings:
- story.md — user story, discovery decisions, acceptance criteria with
  per-criterion Action Required boxes
- design.md — prior implementation decisions (append a new entry here if
  you make a non-obvious choice while applying or rejecting a fix)
- review-fixes.md — the finding list you are updating

## Execution

1. **Read all context first.** Read story.md, design.md, and
   review-fixes.md in full. Then read the source files referenced by the
   findings. Do not start editing until you understand the acceptance
   criteria and the reasoning behind prior design decisions.

2. **Judge each finding.** For every finding (except forced-skip ones),
   decide independently whether to apply it. A finding should be applied
   when it identifies a real defect, regression, missing acceptance
   criterion coverage, or meaningful quality issue. A finding should be
   Rejected when it is:
   - Incorrect (misreads the code, based on a faulty assumption, or
     contradicted by the story, design, or existing tests)
   - Already satisfied by the current code (the reviewer missed something)
   - Out of scope for this feature (unrelated refactor, speculative
     hardening, stylistic preference that fights existing conventions,
     work that belongs in a separate feature)
   - In direct conflict with a higher-severity finding you are applying
   - Demanding behavior the story and acceptance criteria explicitly do
     not call for, or that a recorded design.md decision rejected

   Use the feature context, not just the finding text, to make the call.
   Severity is a signal, not a mandate — a LOW finding with a real defect
   still gets applied; a CRITICAL finding based on a misread does not.

   CRITICAL: Every finding you do not apply MUST be marked Rejected (or
   Excluded if forced-skip) with a concrete rationale. Silently skipping
   a finding is not allowed — if it is not Fixed, explain why in
   review-fixes.md.

3. **Apply accepted fixes.** Work through the findings you chose to apply
   and change the code to address each one. Group related findings in the
   same file into a single coherent edit pass — do not make multiple
   passes over the same file if one pass will do. If two accepted
   findings conflict, prefer the higher-severity one and note the
   conflict in review-fixes.md.

4. **Respect scope.** Do not change anything beyond what the accepted
   findings require. If a fix requires writing a missing test, follow
   existing test conventions in the repo.

5. **Log non-obvious decisions.** If applying — or rejecting — a fix
   forces a design choice (e.g. choosing between two valid fixes,
   introducing a new abstraction, rejecting a HIGH/CRITICAL finding),
   append an entry to design.md using the entry format at the bottom of
   that file. Tag the entry's Source as "feature-code-fix F<id>".
   Rejections of HIGH or CRITICAL findings MUST be logged in design.md so
   a future session can see the reasoning.

6. **Run tests.** After all edits land, run only the test files touched
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

7. **Update story.md — uncheck Action Required.** For each acceptance
   criterion that had findings in this batch, if **all** of its findings
   are now Fixed (tests passed), uncheck its Action Required box: change
   `- [x] Action Required` to `- [ ] Action Required`. If any finding for
   a criterion is Rejected, Excluded, or still Failing, leave Action
   Required checked — /feature-done will block until the user reviews
   the rejection. Group findings by the `Criterion:` field from
   review-fixes.md — "General" findings do not map to a single criterion
   and do not affect any Action Required box.

   Do NOT touch the `Implemented` or `Reviewed` checkboxes. Do NOT touch
   the top-level checkbox on the criterion line.

8. **Update review-fixes.md.** For every finding, add a Status line with
   the decision you made. Use one of: Fixed, Rejected, Excluded, Failed.
   Rejected and Excluded MUST include a rationale. Failed MUST include
   what went wrong.

   ```md
   ### F01 — <Short title>
   - **Source:** <Agent name> (<severity>)
   - **Criterion:** <criterion title or "General">
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
- The list of acceptance criteria whose Action Required box was unchecked.
- The list of criteria that still have Action Required checked and why
  (Fixed-but-failing, Rejected, or Excluded).
- Test summary (pass/fail counts, any lingering failures).
- A note if any design.md entries were appended.

Do not re-describe the fixes in detail — the Edit history and
review-fixes.md already capture that.
```

Wait for the subagent to finish.

## Step 4 — Present changelog

Using the subagent's report, present:

```md
## Fix Changelog

| Fix | Finding | Severity | Status |
|-----|---------|----------|--------|
| F01 | [brief description] | CRITICAL/HIGH/LOW | Fixed |
| F02 | [brief description] | HIGH | Rejected — [subagent rationale] |
| F03 | [brief description] | LOW | Excluded — [user reason] |

**Criteria closed (Action Required unchecked):** <list, or "None">
**Criteria still open (Action Required still checked):** <list, or "None">
**Tests:** Passed / Failed (details)
**Design notes:** <any design.md entries appended, or "None">
```

> **CRITICAL WARNING:** If any CRITICAL or HIGH finding was **Rejected**
> or **Excluded**, highlight it here with the rationale. The user must
> consciously acknowledge they are accepting a known risk, or challenge
> the subagent's rejection if they disagree. If the user challenges a
> rejection, re-run `/feature-code-fix <name>` with that finding listed
> as forced-apply context in the follow-up prompt.

Then prompt: _"Next step: run `/feature-done <name>` to mark this feature as
complete and move it to done. If any criterion still has Action Required
checked, `/feature-done` will block until it is resolved."_ (replace `<name>`
with the actual feature folder name).

## Rules

- The fix subagent judges every finding itself — the orchestrator does not
  pre-filter. Silently skipping a finding is forbidden; every non-Fixed
  finding must be Rejected, Excluded, or Failed with a written rationale
- The subagent is responsible for applying fixes, running tests, updating
  story.md's Action Required checkboxes, and updating review-fixes.md
- Never touch the `Implemented` or `Reviewed` checkboxes — those are owned by
  the implementation and review flows respectively
- A criterion's Action Required box may only be unchecked when all its
  findings are Fixed; if any are Rejected, Excluded, or Failed, leave it
  checked so /feature-done can block on it
- Rejections of HIGH or CRITICAL findings must be logged in design.md
- Append to design.md whenever a fix (or rejection) forces a non-obvious
  design choice
- Lines in all markdown files must not exceed 140 characters
