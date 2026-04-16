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
any open questions. Also read any other `.md` files in the feature folder if
they exist (e.g. `review-fixes.md` from a prior review).

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
and project metadata. It selectively distributes context to each sub-agent — Agent
1 intentionally receives only the code and tech stack (no requirements, no repo
context, no feature docs).

Invoke the `/review-code` skill. It will launch 3 sub-agents in parallel:
1. **Cold Review** — reviews code with no context, catching issues visible to
   fresh eyes
2. **Contextual Review** — reviews with full feature context (story and
   repo context)
3. **Pattern Consistency** — verifies the code follows existing codebase patterns

Wait for `/review-code` to complete and present its findings.

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
