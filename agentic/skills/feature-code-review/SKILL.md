---
name: feature-code-review
description: >-
  Review implemented feature code by delegating to /review-code with feature context. Uses
  story.md acceptance criteria as the requirements source. Outputs structured findings to
  review-fixes.md for follow-up with /feature-code-fix.
argument-hint: [feature-name]
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Feature Code Review Workflow

The user has invoked `/feature-code-review`. Follow this workflow exactly.

This review flow uses `story.md` acceptance criteria as the requirements source and assesses
test quality against what was written ad-hoc during implementation.

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

## Step 2 — Read feature files

Read `~/.claude/features/<name>/story.md` — the user story, discovery decisions,
acceptance criteria (used as the **original requirements**), repos involved, and
any open questions. Also read `~/.claude/features/<name>/design.md` if it
exists — it contains the implementation-level decisions the review should
weigh against. Also read any other `.md` files in the feature folder if they
exist (e.g. `review-fixes.md` from a prior review).

## Step 3 — Gather code context

Collect the following before delegating to the review skill:

- **Base branch:** Run
  `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
  to identify main/master/develop. If that returns nothing (no remote), default to `main`.
  Store as `BASE_BRANCH`.
- **Merge base:** Run `git merge-base HEAD origin/$BASE_BRANCH 2>/dev/null`. If that
  fails (no remote or branch not found), fall back to `git merge-base HEAD HEAD~10
  2>/dev/null`. Store as `MERGE_BASE`. If still empty, use `HEAD~1`.
- **Changed files:** Run `git diff $MERGE_BASE --name-only` to get files changed
  relative to the base. If no changes are found, ask the user which files to
  review and stop.
- **Full diff:** Run `git diff $MERGE_BASE` to get the complete diff against the base.
- **File contents:** Read all changed source and test files in full using the Read tool.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`, `*.csproj`,
  `Cargo.toml`, `go.mod`, or equivalent. Fall back to file extensions.
- **Project structure:** Run `git ls-files | head -80`.
- **Repo context:** Detect the repo name from the working directory. Check whether
  `~/.claude/repo-context/<repo-name>.md` exists. If it does, read it in full.

If `story.md` lists multiple repos under **Repos Involved**, repeat this for each
repo directory.

If no changed files can be identified from git, ask the user to specify which files
to review and stop.

## Step 4 — Delegate to /review-code

All context has been gathered in the conversation. The `/review-code` skill will
use what is already available rather than re-collecting git diffs, file contents,
and project metadata. All three sub-agents receive the acceptance criteria from
`story.md` as their spec; Agent 1 uses them to walk criterion-by-criterion
coverage, Agent 2 uses them as the requirements frame for a contextual pass, and
Agent 3 uses them only as backdrop for its pattern-consistency check.

Invoke the `/review-code` skill. It will launch 3 sub-agents in parallel:
1. **Behavior Verification** — walks the acceptance criteria one by one and
   confirms each Given/When/Then scenario or rule + example is exhibited by
   the code, flagging MISSING / PARTIAL coverage, behavior drift, and
   unclaimed behavior. This agent **also updates `story.md`** for each
   criterion it covers: checks `Reviewed`, and checks `Action Required` when
   the criterion has findings that need code changes. See `/review-code` for
   the exact rules.
2. **Contextual Review** — reviews with full feature context (story, design,
   and repo context)
3. **Pattern Consistency** — verifies the code follows existing codebase patterns

Wait for `/review-code` to complete and present its findings. After it
completes, verify that every criterion now has `- [x] Reviewed` (Agent 1 is
responsible for this) and that criteria with findings also have
`- [x] Action Required`. If any criterion is missing `Reviewed`, fix it
yourself here before moving to Step 5.

## Step 5 — Write review-fixes.md

After the review completes, take the synthesized findings and write them to
`~/.claude/features/<name>/review-fixes.md`:

```md
# Review Findings

> Generated: <today's date>
> Feature: <feature-name>

## Findings

### F01 — <Short title describing the finding>
- **Source:** <Agent name> (<severity>)
- **Criterion:** <short criterion title this finding relates to, or "General">
- **Finding:** <1-2 sentence description>
- **Files:** <file paths that need changes>
- **Suggested fix:** <brief description of what to change>

[Repeat for each finding worth acting on]

## No Action Needed

| Finding | Agent | Severity | Rationale |
|---------|-------|----------|-----------|
| [brief description] | Agent N | LOW | [why no action needed] |
```

The `Criterion` line lets `/feature-code-fix` know which `Action Required`
checkbox to uncheck once the finding is resolved. Use `General` for findings
that are not tied to a specific criterion (e.g. cross-cutting style issues).

> **CRITICAL WARNING:** If any CRITICAL finding exists, highlight it prominently
> at the top of the file.

Then prompt: _"Next step: run `/feature-code-fix <name>` to apply fixes, or
review the findings in `~/.claude/features/<name>/review-fixes.md` first."_
(replace `<name>` with the actual feature folder name).
