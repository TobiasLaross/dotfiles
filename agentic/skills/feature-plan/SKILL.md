---
name: feature-plan
description: >-
  Create a new feature plan. Use this whenever the user wants to start building something
  new — even if they haven't said /feature-plan explicitly. Drafts a user story with
  acceptance criteria (with Implemented/Reviewed tracking), runs discovery Q&A, has a
  subagent review and tighten the criteria for full story coverage, and saves everything
  under ~/.claude/features/. Both /feature-implement and /ralph read the output directly.
argument-hint: <feature description or existing-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Feature Plan Workflow

The user has invoked `/feature-plan`. Follow this workflow exactly.

This skill creates a single artifact — `story.md` — containing the user story,
discovery decisions, acceptance criteria, repos involved, and any open questions.
There is no separate plan: well-formed acceptance criteria carry the full design
intent of the feature, and the implementation agent (whether `/feature-implement`,
`/tasker`, or `/ralph`) decides *how* to build them. Getting the criteria right
matters — keep review rigor high.

## Step 1 — Resume or start

**If `$ARGUMENTS` matches an existing folder in `~/.claude/features/`:**
- Read its `story.md`
- Report status: what exists, what's missing
- If `story.md` exists and is complete (user story, discovery, acceptance
  criteria, repos, open questions), ask the user:
  _"Feature already planned. Continue to implementation with `/feature-implement`,
  `/tasker`, or `/ralph`, or replan from scratch?"_
- If the folder exists but `story.md` is missing or partial, continue from
  Step 2 (or whichever step the work stopped at)

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

Ask: _"Anything else I should know, or are we ready to draft the acceptance
criteria?"_

Do **not** proceed until the user says they're ready.

## Step 4 — Draft initial acceptance criteria

Using everything from discovery, draft an initial set of **acceptance criteria**
covering the feature. Aim for behavior-level criteria, not implementation steps.

Each criterion must be:
- **Specific**: unambiguous about what must happen
- **Testable**: pass/fail verifiable without interpretation
- **User-visible** (or system-observable): describes outcomes, not internals

Cover:
- The happy path
- Edge cases and empty/zero states
- Error and failure modes surfaced during discovery
- Cross-cutting concerns when relevant: accessibility, live updates, persistence,
  permissions, multi-user / multi-device behavior
- Explicit out-of-scope items (as criteria of the form _"X is out of scope: ..."_
  when the user surfaced something the team intentionally chose not to handle)

The criteria are the **only** spec the implementation agent will receive about
*what* to build. They do not specify *how*. Avoid file paths, exact APIs,
syntax, parameter names, numeric constants, or pseudocode. Stay at the level of
behavior and intent.

Format each criterion as a checkbox with nested `Implemented` and `Reviewed`
checkboxes:

```md
- [ ] <criterion text>
  - [ ] Implemented
  - [ ] Reviewed
```

Do not show the criteria to the user yet — Step 5 will revise them first.

## Step 5 — Review and tighten the criteria (subagent)

Spawn a **foreground** subagent (`subagent_type: general`) to review the draft
criteria for coverage of the user story and discovery decisions, and to tighten
them for clarity. **Wait for it to finish** before continuing.

```
You are reviewing and revising a draft list of acceptance criteria for a feature.
The criteria are the ONLY spec the implementation agent will receive about WHAT
to build, so they must be complete and unambiguous.

## Inputs

User story:
<paste the confirmed user story from Step 2>

Discovery decisions:
<paste a summary of the decisions and constraints from Step 3 — every
overridden or accepted recommendation, plus any free-form clarifications>

Draft acceptance criteria:
<paste the draft criteria from Step 4 in the checkbox format>

## Your job

Produce a revised list of acceptance criteria. Apply these checks:

1. **Story coverage** — Every meaningful element of the user story (the actor,
   the goal, the "so that" benefit) is covered by at least one criterion.
   Identify any gap and add a criterion for it.

2. **Discovery coverage** — Every product-owner decision and constraint from
   discovery is reflected in at least one criterion. If a discovery decision
   has no corresponding criterion, add one or note why it shouldn't be a
   criterion (e.g. it's a constraint on something already covered).

3. **Edge and error cases** — Each criterion that describes a happy path
   should have an explicit pair (or sibling criterion) for the failure / empty
   / boundary case unless the failure mode is genuinely irrelevant to this
   feature.

4. **Cross-cutting concerns** — Check whether the feature implicates any of:
   accessibility (VoiceOver, keyboard, focus order), live updates (state
   changes while a related view is open), persistence across sessions /
   devices, permissions / role-gating, internationalization, mobile vs
   desktop, offline behavior. Add criteria for any that apply and aren't
   covered.

5. **Ambiguity** — Each criterion must be testable without interpretation.
   Rewrite anything ambiguous, vague, or open to multiple readings. Replace
   weasel words ("appropriate", "reasonable", "where possible") with concrete
   conditions.

6. **Implementation leakage** — Criteria must describe behavior, not
   implementation. Strip any file paths, API names, syntax, parameter names,
   numeric constants, or pseudocode. Restate at the level of intent.

7. **Out-of-scope** — Discovery sometimes surfaces things the user
   intentionally excluded. Capture those as explicit out-of-scope criteria so
   the implementation agent does not silently add them.

8. **Right-sizing** — Criteria should typically be one or two sentences.
   Split anything that bundles multiple independent behaviors. Merge
   trivial criteria that always go together.

## Output

Return TWO sections:

### Revised criteria

<the full revised list in the checkbox format with nested
Implemented / Reviewed boxes — this is what will replace the draft>

### Changes made

Bulleted summary of the changes you made and why (added/removed/rewrote/
merged/split). Keep this short — one bullet per change. The orchestrator
will show this to the user along with the revised list.

Do not propose alternative versions or hedge — produce the single best
revised list and the changelog. Do not include a plan, design notes, or
implementation guidance — only the criteria and the changelog.
```

When the subagent returns, replace the draft criteria in your working state
with the revised list. Keep the changelog for the next step.

## Step 6 — Present revised criteria and iterate to approval

Show the user:

1. The revised acceptance criteria (full list, checkbox format)
2. A short summary of the changes the subagent made (the changelog from Step 5)

Then ask:

_"These criteria drive everything downstream — implementation, review, and
sign-off. Does each one fully define a 'done' state? Any missing, too vague,
or out of scope? Reply with edits or 'approved'."_

Iterate until the user explicitly approves. Apply any user edits directly
(small changes inline; larger restructures may warrant another pass through
the Step 5 subagent — use judgment). No cap on iterations — getting criteria
right is the most important step in the entire flow.

Do **not** proceed until the user confirms.

## Step 7 — Confirm repos, open questions, test preference

Once the criteria are approved, gather the remaining metadata needed for
`story.md`. Present all three together so the user can answer in one pass.

### 7a — Repos involved

From the discovery context, identify which repos will need changes. Always
include the current repo. For `/work/` features, list any related repos that
the feature touches based on the discovery exploration.

### 7b — Open questions

List any unresolved questions surfaced during discovery — ambiguities that
were deferred, decisions that depend on something not yet known, or items
the user said to revisit. If none, say so.

### 7c — Test preference

Ask whether tests should be run automatically by the agent (`auto`) or
the user wants to run them manually and share output (`manual`).

Present in one message, e.g.:

```
Before I write `story.md`, please confirm:

**Repos involved:** <repo-name> [, <repo-name-2> ...]
**Open questions:** <list, or "None">
**Test preference:** auto / manual?

Edit any of these or reply "looks good".
```

Iterate until the user confirms. Then proceed.

## Step 8 — Create the story file

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

## Repos Involved

- **<repo-name>** — <one-line reason>
[add more as needed; always at least the current repo]

## Open Questions

[Bulleted list of unresolved questions, or "None".]

## Notes

-
```

The nested `Implemented` and `Reviewed` checkboxes under each criterion are the
tracking mechanism for all flows. `/feature-implement` and `/ralph` mark
`Implemented`, `/feature-code-fix` marks `Reviewed`, and `/feature-done` checks
both.

## Step 9 — Final review of the full story

Present a concise summary of the written `story.md` and prompt the user for
final approval before any worktrees are created or implementation begins:

- **User story** — the one-line "As a / I want / so that"
- **Acceptance Criteria** — count only (e.g. "8 criteria")
- **Repos Involved** — repo names only
- **Open Questions** — verbatim if any, or "None"
- **Tests** — auto / manual

Then prompt:

_"`story.md` is at `~/.claude/features/<name>/story.md` (full file available to
read). Approve as-is, or tell me what to change — I'll revise and re-show.
Nothing downstream (worktrees, implementation) starts until you approve."_

If the user requests changes:
- Apply them directly to `story.md`
- Re-show the summary and prompt for approval again
- Iterate until the user explicitly approves

Do **not** proceed to Step 10 until the user explicitly approves.

## Step 10 — Create worktrees

If the current working directory is not a git repository, skip to Step 11.

If the user's initial prompt explicitly requested **no worktrees**, skip to
Step 11. The feature will work in the current directories with feature
branches.

Otherwise, create worktrees for all repos involved in the feature.

Read `story.md` and extract every repo listed under **Repos Involved**. For
each repo (including the current one):

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

## Step 11 — Confirm and offer next step

Tell the user the feature is planned. Show the feature folder path and give
a one-line summary of what was planned (criterion count, repos, test mode).

Then prompt:

_"The feature is ready. Choose your implementation path:_
- _`/feature-implement` — interactive implementation in this session_
- _`/tasker` — autonomous task loop (one task per context window, runs until
  done)_
- _`/ralph` — true Ralph Wiggum loop (same prompt every iteration, agent
  decides what to do)"_

If worktrees were created in Step 10, also tell the user:

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

- Never skip user sign-off on the story (Step 2), the acceptance criteria
  (Step 6), the repos / open questions / test preference (Step 7), or the
  finalized story (Step 9)
- Discovery (Step 3) must happen before criteria — it shapes what criteria exist
- The Step 5 subagent revises the draft criteria; it does not just review them.
  Replace the draft with the subagent's revised list before showing the user
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<name>/`
- All related md files for a feature go in that feature's folder
- Worktree naming convention: `<repo>--<feature-name>` as a sibling of the
  original repo directory. The `--` delimiter is required — downstream cleanup
  depends on it
- When a worktree is created, the `> Working directory:` in `story.md` must
  point to the worktree path (not the original repo)
- Lines in all markdown files must not exceed 140 characters
