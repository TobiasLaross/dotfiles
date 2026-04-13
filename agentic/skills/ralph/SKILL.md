---
name: ralph
description: >-
  Set up and launch a true Ralph Wiggum loop for a planned feature. Generates a
  PROMPT.md that is piped to the agent every iteration — the agent sees its own
  previous work through the filesystem and decides what to do next. No pre-decomposed
  tasks. Requires /feature-plan to have been run first. Use whenever the user wants
  to build something with the ralph flow — even if they just say "use ralph" or
  "ralph loop".
argument-hint: <feature-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Ralph — True Ralph Wiggum Loop Setup & Launch

The user has invoked `/ralph`. Follow this workflow exactly.

This skill takes an already-planned feature (created by `/feature-plan`) and launches
a true Ralph Wiggum loop: the same prompt is piped to the agent on every iteration.
There are no pre-decomposed tasks — the agent reads the specs, sees its own previous
work, and decides what to do next. If the feature hasn't been planned yet, it directs
the user to `/feature-plan` first.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names
  in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one

**If `$ARGUMENTS` matches a folder in `~/.claude/features/done/`:**
- Tell the user it's archived. Ask whether to reopen (move it back).

**If no argument is provided:**
- Scan `~/.claude/features/` for feature folders (exclude `done/`). If one exists,
  offer to use it. If several, ask the user to pick. If none, tell the user to run
  `/feature-plan` first and stop.

## Step 2 — Verify prerequisites

Read `~/.claude/features/<name>/story.md` and `~/.claude/features/<name>/plan.md`.

- If `story.md` is missing, tell the user to run `/feature-plan` first and stop.
- If `plan.md` is missing, tell the user to run `/feature-plan` first and stop.
- If `PROMPT.md` already exists and `progress.md` exists:
  - Read `progress.md`
  - Report status: how many iterations completed, what was last done
  - Ask: _"Resume the loop?"_
    - If yes, jump to **Step 6** to launch
    - If no, ask what they want to change

## Step 2b — Trigger filesystem access

To surface permission prompts early (before the loop starts), touch a file in
every directory the autonomous agent will write to:

1. The feature folder:
   `touch ~/.claude/features/<name>/.gitkeep`
2. Each repo that will be modified (from **Repos Involved** in `plan.md`).
   If worktrees exist (check `> Worktree: true` and the `## Worktrees`
   table in `story.md`), use the worktree paths:
   ```sh
   touch "<repo-or-worktree-path>/.feature-touch"
   rm "<repo-or-worktree-path>/.feature-touch"
   ```

## Step 3 — Detect test command and base branch

### 3a — Test command

Spawn a **foreground** subagent (`subagent_type: general`):

```
Detect the test command for the project at: <working-directory>

Look for:
- package.json -> npm test / jest / vitest
- go.mod -> go test ./...
- Cargo.toml -> cargo test
- Makefile with test target -> make test
- pytest.ini / setup.cfg / pyproject.toml -> pytest
- .xcodeproj / Package.swift -> swift test or xcodebuild test
- If unclear, check for a test/ or tests/ directory and infer

Report ONLY the test command (e.g. "npm test", "go test ./...", "pytest").
If you truly cannot determine it, report "UNKNOWN".
```

### 3b — Base branch

Run:
```
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
  | sed 's|refs/remotes/origin/||'
```

If that returns nothing, try:
```
git rev-parse --verify main 2>/dev/null && echo main || echo master
```

Store the result as `BASE_BRANCH`.

## Step 4 — Generate PROMPT.md

This is the core of the Ralph Wiggum technique: one prompt, piped every iteration.
The agent sees its own previous work through the filesystem (progress.md, git log,
the codebase itself) and decides what to work on.

Read `story.md` and `plan.md` in full. Using their content plus the detected test
command and base branch, write `~/.claude/features/<name>/PROMPT.md`:

````md
# Feature: <title from story.md>

You are one iteration of an implementation loop. You will be invoked repeatedly
with this same prompt. You see your own previous work through the filesystem.

## Specs

<Inline the FULL content of story.md here — including discovery, acceptance
criteria, and notes. The agent needs the complete specs every iteration.>

## Plan

<Inline the FULL content of plan.md here — including design decisions and
implementation phases.>

## Progress

Read `~/.claude/features/<name>/progress.md` to understand what previous
iterations accomplished. Use a subagent for this to preserve your primary
context window.

## Your Job

1. Read `progress.md` (via subagent) to see what's been done
2. Look at the acceptance criteria — find what's not yet implemented
3. Look at the codebase — verify what actually exists (don't assume anything
   is or isn't implemented; always check)
4. Pick the ONE most important thing to work on next
5. Implement it, write tests, verify they pass
6. Commit your work
7. Update progress and stop

### How to pick what to work on

- If `progress.md` doesn't exist or is empty, start with the first
  implementation phase from the plan
- If previous work exists, continue where it left off
- If tests are failing from a previous iteration, fix them first
- If all acceptance criteria are implemented, go to **Final Review**
- Use your judgment — you know the specs and can see the codebase

## Implement

1. Search the codebase before making changes — do not assume something is or
   is not implemented. Use subagents for broad file searches to preserve
   context.
2. Read the source files you need. Implement the change.
3. Write tests for the behavior you added (if applicable).
4. Check `story.md` for `> Tests: manual`. If set to `manual`, skip
   automated test runs — note in progress.md that tests need manual
   verification. Otherwise, run tests using a subagent and pipe output
   to file:
   ```
   <test-command> 2>&1 | tee ~/.claude/features/<name>/test-output.log
   ```
   The subagent should read ONLY the last 30 lines of `test-output.log`
   and report the summary back to you.
5. If tests fail, fix and re-run (max 3 attempts). If still failing after 3
   attempts, note the failure in progress.md and move on.

## On Finishing

1. Mark any acceptance criteria you satisfied in the story section above by
   updating `~/.claude/features/<name>/story.md`:
   Change `- [ ] Implemented` to `- [x] Implemented` for matched criteria
2. Append to `~/.claude/features/<name>/progress.md`:
   ```
   ## Iteration — <date-time>
   - **What I did:** <brief description of the work>
   - **Files changed:** <list>
   - **Tests:** <pass/fail summary>
   - **Remaining:** <what's still unimplemented, or "Final review needed">
   ```
3. Create a git commit with a short message describing what you did.
   Use format: `<Capitalized past-tense verb> <what changed>`
4. **Stop.** Do not start a second piece of work. One thing per iteration.

## Final Review

When all acceptance criteria have `- [x] Implemented`:

1. Run the full test suite (piped to `test-output.log`) via a subagent. Have
   the subagent read the last 50 lines and report back.
2. Get the diff: `git diff $(git merge-base HEAD <base-branch>)..HEAD`
3. Review the diff for: correctness bugs, security issues, performance
   problems, missing error handling, dead code, and whether acceptance
   criteria are truly met.
4. If there are issues:
   - Append to `progress.md`:
     ```
     ## Iteration — <date-time> (Review)
     - **What I did:** Reviewed full diff. Found issues.
     - **Issues:** <list of issues>
     - **Remaining:** Fix issues listed above
     ```
   - Stop (the next iteration will pick up the fixes)
5. If everything is clean:
   - Append `RALPH_DONE` on its own line to `progress.md`
   - Append to `progress.md`:
     ```
     ## Iteration — <date-time> (Review)
     - **What I did:** Final review. All clean.
     ```
   - Stop

## Rules

- ONE piece of work per iteration. Do not start a second item.
- Always run tests before committing.
- Always update progress.md before stopping.
- Keep commits small and focused.
- Do not refactor code unrelated to the feature.
- Use subagents for expensive operations (test runs, large file searches,
  reading progress.md) to preserve your primary context window.
- If the test command is UNKNOWN, look for test infrastructure in the repo
  and determine the correct command. Note it in progress.md for future
  iterations.
````

Replace `<name>` with the actual folder name, `<test-command>` with the
detected command (or `UNKNOWN`), and `<base-branch>` with the detected base
branch. Inline story.md and plan.md content directly — do not use file
references for specs (the agent gets a fresh context each iteration and the
prompt is piped via stdin, so it cannot read files referenced in the prompt
before execution begins).

## Step 5 — Initialize progress file and ensure branch

### 5a — Initialize progress

Create `~/.claude/features/<name>/progress.md`:

```md
# Progress

> Feature: <name>
> Started: <today's date>
```

### 5b — Ensure feature branch

Check `story.md` for `> Worktree: true`. If present, the worktree was already
created by `/feature-plan` with the correct branch checked out. In that case:
- Read `> Branch:` to confirm the branch name
- **Skip branch creation entirely**
- Tell the user: _"Worktree already on branch `<branch>` — the loop will
  commit here."_
- Jump to Step 6

If `> Worktree: true` is **not** present, handle branches normally:

Check if the working directory is a git repository. If it is:

1. Get the current branch: `git rev-parse --abbrev-ref HEAD`
2. If the branch is `main`, `master`, or `develop`:
   - Create and checkout a new branch: `git checkout -b feature/<name>`
   - Tell the user: _"Created branch `feature/<name>` — the loop will commit
     here."_
3. If the branch is anything else (already on a feature branch):
   - Tell the user: _"Already on branch `<branch>` — the loop will commit
     here."_
4. Store the branch name in `story.md` by adding a `> Branch: <branch>` line
   after the `> Working directory:` line (if not already present)

If multiple repos are involved (e.g. the working directory is under `/work/`
and related repos were identified), check each repo. For any repo that is on
`main`/`master`/`develop`, create `feature/<name>` there too, and note the
branches in `progress.md`.

## Step 6 — Launch the loop

Tell the user:
1. Feature folder: `~/.claude/features/<name>/`
2. Detected test command
3. Branch name
4. Note: _"This is a true Ralph Wiggum loop — no pre-decomposed tasks. The
   agent sees the specs and its own previous work each iteration and decides
   what to do."_

Then say: _"Starting the ralph loop now. You can Ctrl+C between iterations to
pause — run `ralph <name>` to resume anytime."_

Launch the loop:

```bash
exec "$DOTFILES/scripts/ralph.sh" "<name>"
```

If `$DOTFILES` is not set, use `~/dotfiles/scripts/ralph.sh`.

If the Bash tool times out (long implementations), this is expected — the loop
is resumable. Tell the user: _"Loop timed out in the tool runner. Run
`ralph <name>` from your terminal to continue."_

## Rules

- Require `/feature-plan` to have been run first — do not plan inline
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<name>/`
- All related md files for a feature go in that feature's folder
- PROMPT.md must inline the full specs — do not use file references for the
  story or plan content within the prompt template
- Lines in all markdown files must not exceed 140 characters
