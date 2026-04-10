---
name: feature-plan
description: >-
  Create a new feature plan. Use this whenever the user wants to start building something
  new — even if they haven't said /feature-plan explicitly. Drafts a user story with
  acceptance criteria (with Implemented/Reviewed tracking), runs discovery Q&A, generates
  a high-level plan with automated review, and saves everything under ~/.claude/features/.
  Both /feature-implement and /ralph read the output directly.
argument-hint: <feature description or existing-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Feature Plan Workflow

The user has invoked `/feature-plan`. Follow this workflow exactly.

This skill creates a thorough feature plan: user story, discovery Q&A, acceptance criteria,
and a reviewed high-level plan. The output is read directly by both `/feature-implement`
(interactive implementation) and `/ralph` (autonomous loop). Getting this right matters —
keep review rigor high.

## Step 1 — Resume or start

**If `$ARGUMENTS` matches an existing folder in `~/.claude/features/`:**
- Read its `story.md` and `plan.md`
- Report status: what exists, what's missing
- If both `story.md` and `plan.md` exist, ask the user:
  _"Feature already planned. Continue to implementation with `/feature-implement`
  or `/ralph`, or replan from scratch?"_
- If `story.md` exists but `plan.md` is missing, continue from Step 5
- If only the folder exists (empty or partial), continue from Step 2

**If `$ARGUMENTS` matches a folder in `~/.claude/features/done/`:**
- Tell the user it's archived. Ask whether to reopen (move it back).

**If `$ARGUMENTS` is a description:**
- Continue to Step 2

**If no argument:**
- List folders in `~/.claude/features/` (exclude `done/`). If one exists, offer to
  resume. If several, ask the user to pick. If none, ask for a description.

## Step 2 — Draft user story

From the user's description, draft:
- A **short folder name** (kebab-case, 2-4 words, e.g. `user-avatar-upload`)
- A **user story**: **As a** [type], **I want** [goal] **so that** [reason]

Check for name collisions in `~/.claude/features/` (excluding `done/`). If a folder
with that name already exists, warn the user:
_"A feature folder named `<name>` already exists. Proceeding will overwrite its
files. Continue?"_
Do not proceed until they confirm.

Present the folder name and user story. Ask: _"Does this capture what you want to
build? Confirm or suggest changes."_

Do **not** proceed until the user confirms.

## Step 3 — Discovery

Purpose: understand the full intent behind the feature before writing acceptance
criteria. The user's initial description is rarely complete — this phase surfaces
edge cases, constraints, and non-obvious requirements.

### 3a — Gather codebase context

Spawn a **foreground** subagent (`subagent_type: general`):

```
You are gathering context for a feature discovery session.

User story: <the confirmed user story>
Working directory: <current working directory>

## Repo detection

Identify the current repo from the working directory name.
If ~/.claude/repo-context/<repo-name>.md exists, read it.
If the directory is under /work/, also list ~/Developer/work/ and read context
files at ~/.claude/repo-context/ for related repos.

If NO repo-context file exists for this repo, create one at
~/.claude/repo-context/<repo-name>.md by exploring the codebase. Include:
purpose, architecture overview, key directories, error handling conventions,
test infrastructure, and notable patterns. This file will be used by future
features too, so make it generally useful — not feature-specific.

## What to gather

Explore the codebase enough to understand:
1. Where in the codebase this feature would live (modules, packages, layers)
2. Existing patterns that are relevant (how similar things are currently done)
3. Dependencies this feature would touch or need
4. Existing tests and test infrastructure
5. Any constraints (API contracts, shared types, config schemas)
6. Error handling conventions (how errors are surfaced, logged, and propagated)

Write a brief context summary (not full code) to stdout. Focus on what would
help someone ask smart questions about the feature. Be concise — bullet points,
not paragraphs.
```

### 3b — Generate discovery questions

Using the codebase context and user story, generate **only the questions needed**
to fully understand the user's intent. There is no fixed count — ask as few or as
many as the feature requires. Show up to 10 at a time.

**Only ask product-owner questions** — things the user needs to decide as the person
who knows *what* the feature should do and *why*. Do NOT ask technical questions.
The implementation agent will figure out technical details (error handling, patterns,
architecture, test strategy) from the codebase context and repo conventions.

Good questions (product-owner scope):
- What should the user see when X happens?
- Should this work for all users or only admins?
- Is Y in scope or explicitly out of scope?
- When you say "notifications", do you mean in-app, email, or both?
- Should there be a limit on how many items can be added?

Bad questions (technical — do NOT ask these):
- How should errors be handled?
- Should we use middleware or a service layer?
- What test framework should we use?
- Should this be backwards compatible with the old API?
- What existing patterns should we follow?

Use concrete options where possible: _"Should inactive users see a disabled button
or no button at all?"_ rather than _"What should happen for inactive users?"_

### 3c — Record and iterate

After each batch of answers:
- Note the answers (you will use them to write the story)
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
plan, implementation, and the final review. Does each one fully define a 'done'
state? Are any missing, too vague, or out of scope?"_

Iterate until the user explicitly approves. No cap on iterations — getting
criteria right is the most important step in the entire flow.

Do **not** proceed until the user confirms.

## Step 5 — Create the story file

Create `~/.claude/features/` and `~/.claude/features/<name>/` if needed.

Write `~/.claude/features/<name>/story.md`:

```md
# <Short descriptive title>

> Original request: <user's exact words, verbatim>
> Created: <today's date>
> Working directory: <current working directory>

**As a** [type], **I want** [goal] **so that** [reason]

## Discovery

[Summarise key decisions and constraints from the Q&A. Use clear statements,
not a Q&A transcript. Group by topic. This section is read by the implementation
agent — it needs the "why" behind non-obvious decisions.]

## Acceptance Criteria

- [ ] <criterion 1>
  - [ ] Implemented
  - [ ] Reviewed
- [ ] <criterion 2>
  - [ ] Implemented
  - [ ] Reviewed
- [ ] <criterion 3>
  - [ ] Implemented
  - [ ] Reviewed
[add more as needed]

## Notes

-
```

The nested `Implemented` and `Reviewed` checkboxes under each criterion are the
tracking mechanism for both flows. `/feature-implement` and `/ralph` mark
`Implemented`, `/feature-code-fix` marks `Reviewed`, and `/feature-done` checks
both.

## Step 5b — Offer worktree

If the current working directory is a git repository, ask the user:

_"Do you want to use a git worktree for this feature? This creates an isolated
working directory so you can keep working on the main branch while the agent
(or another session) implements the feature."_

**If the user declines** (or the directory is not a git repo): skip to Step 6.
The feature will work in the current directory with a feature branch (existing
behaviour).

**If the user accepts:**

1. Determine the repo root and its parent directory:
   ```sh
   repo_root=$(git rev-parse --show-toplevel)
   repo_name=$(basename "$repo_root")
   parent_dir=$(dirname "$repo_root")
   ```
2. Derive the worktree path and branch name:
   - Worktree path: `$parent_dir/$repo_name--<name>`
     (where `<name>` is the feature folder name from Step 2)
   - Branch: `feature/<name>`
3. Check the worktree path does not already exist. If it does, warn the user
   and ask whether to reuse it or abort.
4. Create the worktree:
   ```sh
   git worktree add -b "feature/<name>" "$parent_dir/$repo_name--<name>"
   ```
   If the branch already exists (e.g. from a previous attempt), use:
   ```sh
   git worktree add "$parent_dir/$repo_name--<name>" "feature/<name>"
   ```
5. Update `story.md` to record the worktree. Replace the
   `> Working directory:` line and add metadata lines immediately after it:
   ```md
   > Working directory: <worktree-path>
   > Worktree: true
   > Worktree source: <repo_root>
   > Branch: feature/<name>
   ```
6. Tell the user: _"Created worktree at `<worktree-path>` on branch
   `feature/<name>`. The sessionizer will show it as a separate tmux
   session."_

## Step 6 — Generate high-level plan

Spawn a **foreground** subagent (`subagent_type: general`) and **wait for it to
finish** before continuing. Replace `<name>` with the actual folder name.

```
You are creating a high-level plan for a user story.

Story file: ~/.claude/features/<name>/story.md

Read that file to understand the goal, discovery decisions, and acceptance criteria.

The acceptance criteria are the ground truth for what this feature must achieve.
Treat them as primary design constraints — every section of your plan must be
traceable to at least one criterion, and no criterion should be left unaddressed.

The Discovery section contains product-owner decisions and constraints that must
be reflected in the plan.

The implementation agent will read this plan directly and use its own judgment to
build the feature. Therefore:
- Implementation Phases should be clear enough that an agent can follow them
  without further breakdown
- Design Decisions should be explicit about non-obvious choices so the
  implementation agent doesn't have to guess
- Keep it concise but not ambiguous

## Repo detection

Always start by identifying the current repo from the working directory name.

Check whether a context file exists at ~/.claude/repo-context/<repo-name>.md and
read it if so — this contains purpose, architecture, dependencies, design patterns,
and inter-repo relationships. Do not re-read the source for this repo if the
context file covers what you need.

If the current working directory contains /work/, also list all directories in
~/Developer/work/. Then:
1. Check which repos have a pre-built context file:
   `ls ~/.claude/repo-context/ 2>/dev/null`
2. For repos **with** a context file, read
   `~/.claude/repo-context/<repo-name>.md`. Do not re-read source for these repos
   unless the context file says "Unknown" for something critical to the story.
3. For repos **without** a context file, read enough code to understand what it
   does — start with README.md, package.json, go.mod, Podfile, or equivalent
   manifest files.

Based on the story goal and acceptance criteria, identify which repos will need
changes. Prefer repos listed under "Internal repo dependencies" in context files
of the current repo when tracing the call chain.

## Plan

Write a plan.md file to ~/.claude/features/<name>/plan.md using exactly this
template:

---
# Plan: <Feature Title>

> Created: <today's date>

## Summary
[What needs to be built — 2-4 sentences]

## Design Decisions
[Key architectural choices and why. Be explicit — the implementation agent reads
this directly.]

## Implementation Phases
[Ordered steps — numbered list. Each phase should be clear enough to implement
without further breakdown. Include which files or modules are affected where it's
not obvious.]

## Repos Involved
[Every repo that will need changes, each with a short reason why. Always includes
at least the current repo.]

## Open Questions
[Ambiguities or decisions that need resolution before implementation starts.
Leave blank if none.]
---

Keep it concise. Do not implement anything. Lines must not exceed 140 characters.
```

## Step 7 — Review the plan

After the planning subagent has finished and `plan.md` exists, spawn **1 subagent**
(`subagent_type: general`) and **wait for it to finish** before continuing.

```
You are reviewing a high-level feature plan. You have access to the filesystem.

Story: ~/.claude/features/<name>/story.md
Plan:  ~/.claude/features/<name>/plan.md

Read both files.

The implementation agent reads this plan directly, so gaps here become
implementation gaps. Review with that in mind.

## 1. Story & Acceptance Criteria Coverage

- Does the plan fully address the user's goal and each acceptance criterion
  stated in the story?
- Are there missing cases, overlooked user needs, or gaps between what the story
  asks for and what the plan proposes to build?
- Is the scope appropriate — neither too narrow (misses the goal) nor too broad
  (solves more than asked)?

Output a **Verdict** (Approved / Needs changes) followed by specific gaps or
suggestions.

## 2. Repo & Dependency Coverage

- Read the plan's "Repos Involved" section to see which repos are already listed.
- For those repos only, check ~/Developer/work|personal/ and read their context
  files at ~/.claude/repo-context/<repo-name>.md if they exist.
- Are all necessary repos listed? Are any listed repos unnecessary?
- Are inter-repo dependencies (API contracts, shared types, event flows)
  correctly identified?

Output a **Verdict** (Approved / Needs changes / N/A).

## 3. Implementation Phase Clarity

The Implementation Phases must be clear enough for an agent to follow directly.
For each phase:
- Is it actionable without further decomposition?
- Are affected files or modules identified where non-obvious?
- Are dependencies between phases clear?

Output a **Verdict** (Approved / Needs changes) followed by specific concerns.
```

After the reviewer returns, write its output to
`~/.claude/features/<name>/plan-review.md`:

```md
# Plan Review

> Reviewed: <today's date>

## Story & Acceptance Criteria Coverage
[Verdict and findings]

## Repo & Dependency Coverage
[Verdict and findings, or "N/A — not a /work/ context"]

## Implementation Phase Clarity
[Verdict and findings]

## Suggested Changes
[Consolidated, deduplicated list of actionable changes]
```

## Step 8 — Fix the plan

Spawn a **foreground** subagent and **wait for it to finish** before continuing.

```
You are revising a high-level feature plan based on a review.

Story:  ~/.claude/features/<name>/story.md
Plan:   ~/.claude/features/<name>/plan.md
Review: ~/.claude/features/<name>/plan-review.md

Read all three files. Then:

1. For each item under "Suggested Changes" in the review, decide whether it is
   clearly correct and improves the plan — meaning it closes a genuine gap or
   fixes an error. Apply those changes. Skip anything speculative, stylistic,
   or that contradicts the story goal.
2. Rewrite ~/.claude/features/<name>/plan.md with accepted changes applied. Keep
   the same template structure. Update the header to add
   `> Last revised: <today's date>` below the Created line.
   Lines must not exceed 140 characters.
3. Append a `## Revisions` section at the bottom of plan.md with a changelog
   table:

| Suggestion | Decision | Rationale |
|------------|----------|-----------|
| [brief description] | Applied / Rejected | [why] |
```

## Step 9 — Confirm and offer next step

Tell the user the feature plan is finished. Show the feature folder path and give
a one-line summary of what was planned.

Include a brief review summary:
- Story & Acceptance Criteria Coverage verdict
- Repo & Dependency Coverage verdict (or N/A)
- Implementation Phase Clarity verdict
- Number of suggestions applied vs. rejected

Then prompt:

_"The plan is ready. Choose your implementation path:_
- _`/feature-implement` — interactive implementation in this session_
- _`/tasker` — autonomous task loop (one task per context window, runs until
  done)_
- _`/ralph` — true Ralph Wiggum loop (same prompt every iteration, agent
  decides what to do)"_

If a worktree was created in Step 5b, also tell the user:

_"The worktree is at `<worktree-path>`. Open it in a new tmux session with
`sess`, then start implementation from there:_

```
/feature-implement <name>
```

_or for autonomous loops:_

```
/tasker <name>
```

```
/ralph <name>
```
_"_

## Rules

- Never skip user sign-off on story (Step 2) or acceptance criteria (Step 4)
- Discovery (Step 3) must happen before criteria — it shapes what criteria exist
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<name>/`
- All related md files for a feature go in that feature's folder
- The `## Revisions` section appended to `plan.md` is the downstream-visible
  record of review changes; `plan-review.md` is for human inspection only and
  is not read by downstream skills
- Worktree naming convention: `<repo>--<feature-name>` as a sibling of the
  original repo directory. The `--` delimiter is required — downstream cleanup
  depends on it
- When a worktree is created, the `> Working directory:` in `story.md` must
  point to the worktree path (not the original repo)
- Lines in all markdown files must not exceed 140 characters
