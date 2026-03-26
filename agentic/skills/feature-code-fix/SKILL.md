---
name: feature-code-fix
description: >-
  Apply fixes from a feature code review, batched by file, with test verification. Use after
  /feature-code-review — or any time review-fixes.md exists and the user wants the findings
  addressed, even if they just say "fix it" or "apply the review". Marks all tasks as reviewed
  in impl-plan.md when done, closing the review cycle before /feature-done.
argument-hint: [feature-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Feature Code Fix Workflow

The user has invoked `/feature-code-fix`. Follow this workflow exactly.

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

Also read `~/.claude/features/<name>/impl-plan.md` and
`~/.claude/features/<name>/story.md` for context.

## Step 3 — Triage findings with the user

Present a summary of all findings grouped by severity:

```
CRITICAL: N findings
HIGH: N findings
LOW: N findings
```

Ask the user: _"Apply all findings, or would you like to exclude any?"_

If the user wants to exclude some, note which ones. For excluded CRITICAL
findings, warn explicitly that a known critical risk will remain.

## Step 4 — Batch and apply fixes

Group accepted findings by file. For each file (or small group of related files),
spawn a subagent (`subagent_type: general-purpose`) to apply all fixes for that
file in a single pass.

Launch independent file groups in parallel. Files that depend on each other
(e.g., a function definition and its callers) should be handled by the same
subagent.

Each subagent receives:
```
You are applying code review fixes to specific files.

Feature folder: ~/.claude/features/<name>/
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
3. If a fix involves writing a missing test, follow existing test conventions.
4. Do not change anything beyond what the findings require.
5. Verify your fixes are logically correct before finishing.
```

## Step 5 — Run tests

After all fix subagents complete, run the repo's test suite. If the test command
is expected to take longer than 2 minutes, ask the user before running.

- If tests pass: proceed to Step 6.
- If tests fail: diagnose and fix. If the failure is unrelated to the review
  fixes, note it and proceed. If it's caused by a fix, correct it.

## Step 6 — Update review-fixes.md and mark tasks reviewed

Update `~/.claude/features/<name>/review-fixes.md` to reflect what was done.
Change the findings section to include status:

```md
### F01 — <Short title>
- **Source:** <Agent name> (<severity>)
- **Finding:** <description>
- **Files:** <file paths>
- **Status:** Fixed / Excluded
```

Also mark all implemented tasks as reviewed in `impl-plan.md`: for every task with
`- [x] Implemented`, change `- [ ] Reviewed` to `- [x] Reviewed`. This closes the
review cycle for those tasks and allows `/feature-done` to confirm the feature is
fully complete.

## Step 7 — Present changelog

```md
## Fix Changelog

| Fix | Finding | Severity | Status |
|-----|---------|----------|--------|
| F01 | [brief description] | CRITICAL/HIGH/LOW | Fixed |
| F02 | [brief description] | LOW | Excluded — [reason] |

**Tests:** Passed / Failed (details)
```

> **CRITICAL WARNING:** If any CRITICAL finding was **Excluded**, highlight it
> here. The user must consciously acknowledge they are accepting a known critical
> risk.

Then prompt: _"Next step: run `/feature-done <name>` to mark this feature as
complete and move it to done."_ (replace `<name>` with the actual feature folder
name).
