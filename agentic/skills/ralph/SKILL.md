---
name: ralph
description: >-
  Create a PRD with user story, discovery Q&A, and task breakdown for Ralph Wiggum
  loop implementation. Drafts story, runs discovery to understand intent and edge
  cases, gets user sign-off at each stage, decomposes into tasks, then auto-starts
  the autonomous loop. Use whenever the user wants to build something with the ralph
  flow — even if they just say "use ralph" or "ralph loop".
argument-hint: <description or existing-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Ralph — PRD & Loop Setup

The user has invoked `/ralph`. Follow this workflow exactly.

This skill creates a thorough PRD (user story + discovery + tasks) and generates the
prompt file for an autonomous Ralph Wiggum loop. After user sign-off, the loop starts
automatically. Implementation happens via `claude -p` in a shell loop — one task per
context window, progress tracked in files, until done.

## Step 1 — Resume or start

**If `$ARGUMENTS` matches an existing folder in `~/.claude/ralph/`:**
- Read its `tasks.md` and `progress.md`
- Report status: how many tasks done, what's next
- If `RALPH.md` exists, ask the user: _"Resume the loop?"_
  - If yes, jump to **Step 10** to launch
  - If no, ask what they want to change
- If `RALPH.md` is missing, continue from Step 5

**If `$ARGUMENTS` matches a folder in `~/.claude/ralph/done/`:**
- Tell the user it's archived. Ask whether to reopen (move it back).

**If `$ARGUMENTS` is a description:**
- Continue to Step 2

**If no argument:**
- List folders in `~/.claude/ralph/` (exclude `done/`). If one exists, offer to
  resume. If several, ask the user to pick. If none, ask for a description.

## Step 2 — Draft user story

From the user's description, draft:
- A **short folder name** (kebab-case, 2-4 words)
- A **user story**: **As a** [type], **I want** [goal] **so that** [reason]

Check for name collisions in `~/.claude/ralph/`.

Present to the user. Ask: _"Does this capture what you want to build? Confirm or
suggest changes."_

Do **not** proceed until the user confirms.

## Step 3 — Discovery

Purpose: understand the full intent behind the feature before writing acceptance
criteria. The user's initial description is rarely complete — this phase surfaces
edge cases, constraints, and non-obvious requirements.

### 3a — Gather codebase context

Spawn a **foreground** subagent (`subagent_type: general-purpose`):

```
You are gathering context for a feature discovery session.

User story: <the confirmed user story>
Working directory: <current working directory>

## Repo detection

Identify the current repo from the working directory name.
If ~/.claude/repo-context/<repo-name>.md exists, read it.
If the directory is under /work/, also list ~/Developer/work/ and read context
files at ~/.claude/repo-context/ for related repos.

## What to gather

Explore the codebase enough to understand:
1. Where in the codebase this feature would live (modules, packages, layers)
2. Existing patterns that are relevant (how similar things are currently done)
3. Dependencies this feature would touch or need
4. Existing tests and test infrastructure
5. Any constraints (API contracts, shared types, config schemas)

Write a brief context summary (not full code) to stdout. Focus on what would
help someone ask smart questions about the feature. Be concise — bullet points,
not paragraphs.
```

### 3b — Generate discovery questions

Using the codebase context and user story, generate **5-10 probing questions**
across these categories:

**Behavior & edge cases:**
- What should happen when X? What if Y is empty/missing/invalid?
- Are there boundary conditions (limits, timeouts, max sizes)?

**Scope & constraints:**
- What is explicitly out of scope?
- Are there performance requirements (latency, throughput)?
- Must it be backwards compatible with anything?

**User experience:**
- What does the user see/get on success? On failure?
- Are there different user types or permission levels that matter?

**Integration:**
- How does this interact with existing features?
- Are there external services, APIs, or data sources involved?
- Does this need to work across repos or is it contained?

**Design intent:**
- Why this approach vs alternatives? (surfaces hidden assumptions)
- Is there prior art in the codebase to follow or deliberately diverge from?

Present questions in small groups (3-4 at a time) to avoid overwhelming the user.
Use concrete options where possible: _"Should X return an error or silently skip?"_
rather than _"How should errors be handled?"_

### 3c — Record and iterate

After each batch of answers:
- Note the answers (you will use them to write the PRD)
- Check if answers revealed new areas to probe — if so, ask follow-up questions
- Continue until you have a clear picture of intent, scope, and edge cases

Ask: _"Anything else I should know, or are we ready to lock down the acceptance
criteria?"_

Do **not** proceed until the user says they're ready.

## Step 4 — Draft acceptance criteria

Using everything from discovery, draft **3-7 acceptance criteria**. Each must be:
- **Specific**: unambiguous about what must happen
- **Testable**: pass/fail verifiable without interpretation
- **User-visible**: describes observable outcomes, not implementation details

Include criteria for edge cases and error scenarios surfaced during discovery —
not just the happy path.

Present in checkbox format. Ask: _"These criteria drive everything downstream —
tasks, implementation, and the final review. Does each one fully define a 'done'
state? Are any missing, too vague, or out of scope?"_

Iterate until the user explicitly approves. No cap on iterations — getting
criteria right is the most important step in the entire flow.

Do **not** proceed until the user confirms.

## Step 5 — Create story file

Create `~/.claude/ralph/` and `~/.claude/ralph/<name>/` if needed.

Write `~/.claude/ralph/<name>/story.md`:

```md
# <Title>

> Original request: <user's exact words>
> Created: <today's date>
> Working directory: <current working directory>

**As a** [type], **I want** [goal] **so that** [reason]

## Discovery

[Summarise key decisions and constraints from the Q&A. Use clear statements,
not a Q&A transcript. Group by topic. This section is read by the implementation
agent — it needs the "why" behind non-obvious decisions.]

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>
```

## Step 6 — Decompose into tasks

Spawn a **foreground** subagent (`subagent_type: general-purpose`):

```
You are decomposing a user story into implementation tasks for an autonomous agent.

Read: ~/.claude/ralph/<name>/story.md

Pay close attention to the Discovery section — it contains design decisions and
constraints that must be reflected in the tasks.

## Repo detection

Identify the current repo from the working directory: <working-directory>
If ~/.claude/repo-context/<repo-name>.md exists, read it for architecture context.
If the directory is under /work/, also check ~/Developer/work/ for related repos
and read their context files at ~/.claude/repo-context/.

## Task decomposition

Break the acceptance criteria into an ordered list of implementation tasks. Each
task must be:
- **Atomic**: completable in a single focused session (15-30 min of agent work)
- **Testable**: the agent can verify it worked before moving on
- **Independent enough**: minimal coupling to unfinished tasks (order handles deps)

Guidelines:
- First task should be the simplest possible change that proves the approach works
- Infrastructure/setup tasks before feature tasks
- Each task that adds behavior should include writing tests for that behavior
- Include tasks for edge cases and error scenarios from the Discovery section
- Final task before review: run full test suite, fix any failures
- Order tasks so each builds on the previous — the agent sees only one at a time

Write ~/.claude/ralph/<name>/tasks.md:

# Tasks

> Generated: <today's date>

- [ ] <task 1: description>
- [ ] <task 2: description>
- [ ] <task 3: description>
...

Keep descriptions concise but unambiguous (one line each). A fresh context window
with access to the codebase and story.md must be able to understand what to do.
Lines must not exceed 140 characters.
```

## Step 7 — Detect test command

Spawn a **foreground** subagent:

```
Detect the test command for the project at: <working-directory>

Look for:
- package.json → npm test / jest / vitest
- go.mod → go test ./...
- Cargo.toml → cargo test
- Makefile with test target → make test
- pytest.ini / setup.cfg / pyproject.toml → pytest
- .xcodeproj / Package.swift → swift test or xcodebuild test
- If unclear, check for a test/ or tests/ directory and infer

Report ONLY the test command (e.g. "npm test", "go test ./...", "pytest").
If you truly cannot determine it, report "UNKNOWN".
```

## Step 8 — Generate RALPH.md

Using the test command from Step 7 (or `UNKNOWN`), write
`~/.claude/ralph/<name>/RALPH.md`:

````md
# RALPH — Implementation Loop

You are one iteration of a Ralph loop. You have ONE job: complete the next
unchecked task, then stop. Do not combine tasks. Do not skip ahead.

## Files

- Story & criteria: ~/.claude/ralph/<name>/story.md
- Task list: ~/.claude/ralph/<name>/tasks.md
- Progress log: ~/.claude/ralph/<name>/progress.md
- Test output: ~/.claude/ralph/<name>/test-output.log

## On Start

1. Read `tasks.md` — find the first unchecked task (`- [ ]`)
2. Read `progress.md` (if it exists) — understand what previous iterations did
3. Read `story.md` — understand the goal, acceptance criteria, and discovery
   decisions
4. If a task is marked in-progress (`- [~]`), resume that task
5. If ALL tasks are checked off, go to **Final Review**

## Implement

1. Mark your task in-progress in `tasks.md`: change `- [ ]` to `- [~]`
2. Read the source files you need. Implement the task.
3. Write tests for the behavior you added (if applicable to this task).
4. Run tests and pipe output to file:
   ```
   <test-command> 2>&1 | tee ~/.claude/ralph/<name>/test-output.log
   ```
   Then read ONLY the last 30 lines of `test-output.log` for the summary.
5. If tests fail, fix and re-run (max 3 attempts). If still failing after 3
   attempts, note the failure in progress.md and move on.

## On Finishing

1. Mark task done in `tasks.md`: change `- [~]` to `- [x]`
2. Mark any acceptance criteria satisfied in `story.md`: `- [ ]` to `- [x]`
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

1. Run the full test suite (piped to `test-output.log`). Read last 50 lines.
2. Get the diff: `git diff $(git merge-base HEAD main)..HEAD`
3. Review the diff for: correctness bugs, security issues, performance problems,
   missing error handling, dead code, and whether acceptance criteria are met.
4. Write `~/.claude/ralph/<name>/review.md` with findings (if any).
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
- If the test command is UNKNOWN, look for test infrastructure in the repo and
  determine the correct command. Update this file with the correct command for
  future iterations.
````

Replace `<name>` with the actual folder name and `<test-command>` with the detected
command (or `UNKNOWN` if not detected).

## Step 9 — Initialize progress file

Create `~/.claude/ralph/<name>/progress.md`:

```md
# Progress

> Implementation: <name>
> Started: <today's date>
```

## Step 10 — Launch the loop

Tell the user:
1. Feature folder: `~/.claude/ralph/<name>/`
2. Number of tasks generated
3. Detected test command

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

- Never skip user sign-off on story (Step 2) or acceptance criteria (Step 4)
- Discovery (Step 3) must happen before criteria — it shapes what criteria exist
- Use kebab-case for folder names, lowercase only
- Active implementations live in `~/.claude/ralph/`
- Completed implementations move to `~/.claude/ralph/done/`
- Lines in all markdown files must not exceed 140 characters
