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

**Before anything else**, create the feature folder to trigger filesystem
access approval early:

```sh
mkdir -p ~/.claude/features/<name>
touch ~/.claude/features/<name>/.gitkeep
```

Use a placeholder name derived from the user's description (the final name
is confirmed below). If the name changes after confirmation, rename the
folder.

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

This step has three phases: repo-context lookup, keyword pre-filtering,
and (optionally) a focused subagent.

#### Phase 1 — Repo-context lookup

Identify the repo name from the working directory. Check whether
`~/.claude/repo-context/<repo-name>.md` exists.

- **If it exists:** read it. This file is **authoritative** for general
  repo structure, architecture, tech stack, test setup, error handling
  conventions, and inter-repo dependencies. Do NOT re-explore these
  general topics — they are already covered.
- **If it does NOT exist:** create one by spawning a subagent
  (`subagent_type: explore`, thoroughness: `very thorough`):

  ```
  Explore the codebase at <working directory> and create a repo-context
  file at ~/.claude/repo-context/<repo-name>.md. Include: purpose,
  architecture overview, key directories, error handling conventions,
  test infrastructure, and notable patterns. Make it generally useful —
  not feature-specific.
  ```

  Wait for it to finish, then read the resulting file.

If the directory is under `/work/`, also list `~/Developer/work/` and
read context files at `~/.claude/repo-context/` for related repos.

#### Phase 2 — Keyword pre-filtering

Extract 3-6 key nouns and verbs from the confirmed user story (e.g.
"context menu," "record sound," "privacy mode," "upload avatar"). Run
targeted greps for each keyword in the working directory. Use the Grep
tool directly (not a subagent) — this takes seconds.

Collect the matched file paths and deduplicate them. These are the
**starting points** for feature-specific exploration.

#### Phase 3 — Decision gate

**If a repo-context file exists AND the keyword greps returned matches
in 5 or fewer files:** skip the subagent. Read those files directly
using the Read tool (in parallel when independent). Combine the
repo-context summary with what you learn from those files — this is
your codebase context for Step 3b. Proceed to Step 3b.

**Otherwise** (no repo-context file existed before Phase 1, or keyword
greps returned matches in more than 5 files): spawn a focused subagent
(`subagent_type: general`):

```
You are gathering feature-specific context for a discovery session.

User story: <the confirmed user story>
Working directory: <current working directory>

## Repo context (already gathered)

<paste the repo-context summary — do NOT re-explore general structure,
architecture, test infrastructure, or error handling conventions>

## Starting points (from keyword search)

These files matched keywords from the user story. Start here:
- <path/to/FileA> (matched "<keyword>")
- <path/to/FileB> (matched "<keyword>")
[list all matched files]

Read these files first. Only explore beyond them if you cannot answer
the questions below from these files alone.

## What to gather

Focus exclusively on feature-specific code paths:
1. Where in the codebase this feature would live (modules, packages,
   layers)
2. Existing patterns that are relevant (how similar things are
   currently done)
3. Dependencies this feature would touch or need
4. Any constraints (API contracts, shared types, config schemas)

General topics (repo structure, test infrastructure, error handling
conventions) are already covered by the repo-context above. Do not
re-explore them.

## Constraints

- Complete your exploration in **12 tool calls or fewer**. Prioritize
  reading files from the starting points list.
- When you need to read multiple independent files, read them in a
  single **parallel batch** rather than sequentially.
- If you search for a pattern or concept and find zero matches after
  2 attempts (e.g. a broader grep and a glob), **stop**. Report it
  as "not found in codebase" and move on — the orchestrator will ask
  the user for clarification.
- Do NOT re-read files already listed in the starting points unless
  you need to see a specific section not covered by the initial read.

Write a brief context summary (not full code) to stdout. Focus on
what would help someone ask smart questions about the feature. Be
concise — bullet points, not paragraphs.
```

### 3b — Generate discovery questions with recommended answers

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

**For each question, also propose a recommended answer.** The goal is to let the
user skim and respond only to the ones they disagree with — not to answer every
question from scratch. Base recommendations on:
- The user story and original request
- Codebase context and existing patterns
- Common product sense for the domain
- The principle of least surprise

Present questions in this format:

```md
**Q1.** <Question text>
**Recommended:** <Proposed answer> — <one-line rationale>

**Q2.** <Question text>
**Recommended:** <Proposed answer> — <one-line rationale>

...
```

Then prompt the user:

_"I've proposed recommended answers for each. Reply with only the ones you'd
change (e.g. 'Q2: ...', 'Q5: ...'). Anything you don't mention I'll take as
'accept the recommendation'."_

### 3c — Record and iterate

After each batch of responses:
- For questions the user didn't override, record the recommended answer as the
  accepted decision
- For questions the user overrode, record their answer
- Check if answers (overrides or accepted recommendations) revealed new areas to
  probe — if so, ask follow-up questions in the same recommended-answer format
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

## Step 4b — Test preference

Ask the user:

_"Should tests be run automatically by the agent, or do you want to run them
manually and share the output?"_

Store the answer as `auto` or `manual`. This will be recorded in `story.md`
and read by downstream skills.

## Step 5 — Create the story file

Create `~/.claude/features/` and `~/.claude/features/<name>/` if needed.

Write `~/.claude/features/<name>/story.md`:

```md
# <Short descriptive title>

> Original request: <user's exact words, verbatim>
> Created: <today's date>
> Working directory: <current working directory>
> Tests: <auto or manual>

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

## Step 8a — User review of the plan

Before any worktrees are created or implementation begins, the user must review
the finalized plan. The automated review catches gaps, but the user is the final
authority on scope, design decisions, and whether the plan reflects what they
actually want to build.

Read the revised `~/.claude/features/<name>/plan.md` and the
`~/.claude/features/<name>/plan-review.md`. Present a concise summary to the
user:

- **Summary** — the 2-4 sentence Summary section from `plan.md`
- **Design Decisions** — bullet list of the key choices the plan locked in
- **Implementation Phases** — numbered list (just titles/one-liners, not full
  detail)
- **Repos Involved** — repo names only
- **Open Questions** — verbatim if any, or "None"
- **Review verdicts** — one line each for the three review sections
- **Revisions applied vs. rejected** — counts from the `## Revisions` table

Then prompt:

_"The plan is finalized at `~/.claude/features/<name>/plan.md` (full file
available to read). Approve as-is, or tell me what to change — I'll revise and
re-show. Nothing downstream (worktrees, implementation) starts until you
approve."_

If the user requests changes:
- Apply them directly to `plan.md` (small edits) or spawn a revision subagent
  (large/structural edits), keeping the same template
- Append a new row to the `## Revisions` table marked `User-requested`
- Re-show the summary and prompt for approval again
- Iterate until the user explicitly approves. No cap on iterations.

Do **not** proceed to Step 8b until the user explicitly approves.

## Step 8b — Create worktrees

If the current working directory is not a git repository, skip to Step 9.

If the user's initial prompt explicitly requested **no worktrees**, skip to
Step 9. The feature will work in the current directories with feature
branches.

Otherwise, create worktrees for all repos involved in the feature.

Read the finalized `plan.md` and extract every repo listed under **Repos
Involved**. For each repo (including the current one):

1. Determine the repo root and its parent directory:
   ```sh
   repo_root="<repo-path>"   # e.g. ~/Developer/work/my-app
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
   git -C "$repo_root" worktree add \
     -b "feature/<name>" "$parent_dir/$repo_name--<name>"
   ```
   If the branch already exists (e.g. from a previous attempt), use:
   ```sh
   git -C "$repo_root" worktree add \
     "$parent_dir/$repo_name--<name>" "feature/<name>"
   ```

After creating all worktrees, update `story.md`:

1. Replace the `> Working directory:` line with the **primary** worktree
   path (the worktree for the current repo — the one `tasker.sh`/`ralph.sh`
   will `cd` into).
2. Add worktree metadata immediately after:
   ```md
   > Working directory: <primary-worktree-path>
   > Worktree: true
   > Worktree source: <primary-repo-root>
   > Branch: feature/<name>
   ```
3. If multiple repos have worktrees, add a `## Worktrees` section at the
   bottom of `story.md` (before `## Notes`):
   ```md
   ## Worktrees

   | Repo | Worktree path | Source | Branch |
   |------|---------------|--------|--------|
   | <repo-name> | <worktree-path> | <repo-root> | feature/<name> |
   | <repo-name-2> | <worktree-path-2> | <repo-root-2> | feature/<name> |
   ```

Tell the user which worktrees were created:
_"Created worktrees:_
- _`<repo-name>` → `<worktree-path>`_
- _`<repo-name-2>` → `<worktree-path-2>`_
_Each will show as a separate tmux session in the sessionizer."_

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

If worktrees were created in Step 8b, also tell the user:

_"Worktrees are ready. Open the primary worktree in a new tmux session with
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

- Never skip user sign-off on story (Step 2), acceptance criteria (Step 4), or
  the finalized plan (Step 8a)
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
