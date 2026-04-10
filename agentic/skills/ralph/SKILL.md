---
name: ralph
description: >-
  Set up and launch a Ralph Wiggum autonomous loop for a planned feature. Decomposes
  the plan into tasks, generates the loop prompt, and launches the shell loop. Requires
  /feature-plan to have been run first. Use whenever the user wants autonomous
  implementation — even if they just say "use ralph" or "ralph loop".
argument-hint: <feature-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Ralph — Autonomous Loop Setup & Launch

The user has invoked `/ralph`. Follow this workflow exactly.

This skill takes an already-planned feature (created by `/feature-plan`) and sets it up
for autonomous implementation via a shell loop. It decomposes the plan into tasks,
generates the loop prompt file, and launches `ralph.sh`. If the feature hasn't been
planned yet, it directs the user to `/feature-plan` first.

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
- If `RALPH.md` already exists and `tasks.md` exists:
  - Read `tasks.md` and `progress.md` (if present)
  - Report status: how many tasks done, what's next
  - Ask: _"Resume the loop?"_
    - If yes, jump to **Step 7** to launch
    - If no, ask what they want to change

## Step 3 — Decompose into tasks

Spawn a **foreground** subagent (`subagent_type: general`):

```
You are decomposing a user story into implementation tasks for an autonomous
agent.

Read: ~/.claude/features/<name>/story.md
Read: ~/.claude/features/<name>/plan.md

Pay close attention to the Discovery section in story.md — it contains design
decisions and constraints that must be reflected in the tasks.

Pay close attention to the Implementation Phases in plan.md — they define the
logical order of work.

## Repo detection

Identify the current repo from the working directory: <working-directory>
If ~/.claude/repo-context/<repo-name>.md exists, read it for architecture
context. If the directory is under /work/, also check ~/Developer/work/ for
related repos and read their context files at ~/.claude/repo-context/.

## Task decomposition

Break the acceptance criteria and implementation phases into an ordered list of
**behavior-level** tasks. Each task describes an observable outcome — what the
system should do — not implementation steps like "create a file" or "add a
method". The agent decides *how* to implement each task.

Each task must be:
- **Behavior-scoped**: describes a user-visible or system-observable outcome
- **Testable**: the agent can verify it worked before moving on
- **Right-sized**: bigger than a single function, smaller than an entire feature
  (think: "a user can do X and sees Y" or "the system handles Z correctly")

Guidelines:
- First task should be the simplest end-to-end behavior that proves the approach
- Each task that adds behavior should include writing tests for that behavior
- Group related edge cases into the task they belong to rather than splitting
  each edge case into its own task
- Final task before review: run full test suite, fix any failures
- Order tasks so each builds on the previous — the agent sees only one at a time

Good task examples:
- "Users can create a new widget with a name and description; duplicates are
  rejected with a clear error message"
- "The sync job retries failed items up to 3 times with backoff, then reports
  them in the summary"

Bad task examples (too granular):
- "Create the Widget model with name and description fields"
- "Add validation for duplicate names"
- "Write unit tests for Widget creation"

Write ~/.claude/features/<name>/tasks.md:

# Tasks

> Generated: <today's date>

- [ ] <task 1: description>
- [ ] <task 2: description>
- [ ] <task 3: description>
...

Keep descriptions concise but unambiguous (one line each). A fresh context
window with access to the codebase and story.md must be able to understand
what to do. Lines must not exceed 140 characters.
```

## Step 4 — Detect test command

Spawn a **foreground** subagent:

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

## Step 5 — Detect base branch

Run:
```
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If that returns nothing, try:
```
git rev-parse --verify main 2>/dev/null && echo main || echo master
```

Store the result as `BASE_BRANCH`.

## Step 6 — Generate RALPH.md

Using the test command from Step 4 (or `UNKNOWN`) and base branch from Step 5,
write `~/.claude/features/<name>/RALPH.md`:

````md
# RALPH — Implementation Loop

You are one iteration of a Ralph loop. You have ONE job: complete the next
unchecked task, then stop. Do not combine tasks. Do not skip ahead.

## Files

- Story & criteria: ~/.claude/features/<name>/story.md
- Plan: ~/.claude/features/<name>/plan.md
- Task list: ~/.claude/features/<name>/tasks.md
- Progress log: ~/.claude/features/<name>/progress.md
- Test output: ~/.claude/features/<name>/test-output.log

## On Start

1. Read `tasks.md` — find the first unchecked task (`- [ ]`)
2. Read `progress.md` (if it exists) — understand what previous iterations did.
   Use a subagent for this to preserve your primary context window.
3. If a task is marked in-progress (`- [~]`), resume that task
4. If ALL tasks are checked off, go to **Final Review**

Read `story.md` and `plan.md` only when you need to understand intent or design
decisions for the current task. Do not read them upfront every iteration.

## Implement

1. Mark your task in-progress in `tasks.md`: change `- [ ]` to `- [~]`
2. Search the codebase before making changes — do not assume something is not
   implemented. Use subagents for file searches to preserve context.
3. Read the source files you need. Implement the task.
4. Write tests for the behavior you added (if applicable to this task).
5. Run tests using a subagent and pipe output to file:
   ```
   <test-command> 2>&1 | tee ~/.claude/features/<name>/test-output.log
   ```
   The subagent should read ONLY the last 30 lines of `test-output.log` and
   report the summary back to you.
6. If tests fail, fix and re-run (max 3 attempts). If still failing after 3
   attempts, note the failure in progress.md and move on.

## On Finishing

1. Mark task done in `tasks.md`: change `- [~]` to `- [x]`
2. Mark any acceptance criteria satisfied in `story.md`:
   Change `- [ ] Implemented` to `- [x] Implemented` for matched criteria
3. Append to `progress.md`:
   ```
   ## Iteration — <date-time>
   - **Task:** <task description>
   - **Files changed:** <list>
   - **Tests:** <pass/fail summary>
   - **Notes:** <any deviations or issues>
   ```
4. Create a git commit with a short message describing what you did.
   Use format: `<Capitalized past-tense verb> <what changed>`

## Final Review

When all tasks in `tasks.md` are checked off:

1. Run the full test suite (piped to `test-output.log`) via a subagent. Have the
   subagent read the last 50 lines and report back.
2. Get the diff: `git diff $(git merge-base HEAD <base-branch>)..HEAD`
3. Review the diff for: correctness bugs, security issues, performance problems,
   missing error handling, dead code, and whether acceptance criteria are met.
4. Write `~/.claude/features/<name>/review.md` with findings (if any).
5. If there are findings that need fixing:
   - Append new fix tasks to `tasks.md` (as unchecked items)
   - Append to `progress.md`: "Review complete. Added N fix tasks."
   - Stop (the loop will pick up the fix tasks)
6. If everything is clean (or only has minor style nits):
   - Append `RALPH_DONE` on its own line to `progress.md`
   - Append to `progress.md`: "Review complete. All clean."
   - Stop

## Rules

- ONE task per iteration. Do not start a second task.
- Always run tests before committing.
- Always update tasks.md, progress.md, and story.md before stopping.
- Keep commits small and focused on the single task.
- Do not refactor code unrelated to your task.
- Use subagents for expensive operations (test runs, large file searches,
  reading progress.md) to preserve your primary context window.
- If the test command is UNKNOWN, look for test infrastructure in the repo and
  determine the correct command. Update this file with the correct command for
  future iterations.
````

Replace `<name>` with the actual folder name, `<test-command>` with the detected
command (or `UNKNOWN`), and `<base-branch>` with the detected base branch.

## Step 6b — Initialize progress file

Create `~/.claude/features/<name>/progress.md`:

```md
# Progress

> Feature: <name>
> Started: <today's date>
```

## Step 6c — Ensure feature branch

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
   after the `> Working directory:` line

If multiple repos are involved (e.g. the working directory is under `/work/` and
related repos were identified), check each repo. For any repo that is on
`main`/`master`/`develop`, create `feature/<name>` there too, and note the
branches in `progress.md`.

## Step 7 — Launch the loop

Tell the user:
1. Feature folder: `~/.claude/features/<name>/`
2. Number of tasks generated
3. Detected test command
4. Branch name

Then say: _"Starting the Ralph loop now. You can Ctrl+C between iterations to
pause — run `ralph <name>` to resume anytime."_

Launch the loop:

```bash
exec "$DOTFILES/scripts/ralph.sh" "<name>"
```

If `$DOTFILES` is not set, use `~/dotfiles/scripts/ralph.sh`.

If the Bash tool times out (long implementations), this is expected — the loop is
resumable. Tell the user: _"Loop timed out in the tool runner. Run `ralph <name>`
from your terminal to continue."_

## Rules

- Require `/feature-plan` to have been run first — do not plan inline
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<name>/`
- Lines in all markdown files must not exceed 140 characters
