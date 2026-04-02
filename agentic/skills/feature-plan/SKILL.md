---
name: feature-plan
description: >-
  Create a new feature plan. Use this whenever the user wants to start building something new —
  even if they haven't said /feature-plan explicitly. If the user describes a feature, asks "how
  should I build X", or says "let's plan this", reach for this skill. Drafts a user story with
  acceptance criteria, generates a high-level plan with automated review, and saves everything
  under ~/.claude/features/.
argument-hint: <feature description>
---

# Feature Plan Workflow

The user has invoked `/feature-plan` with a feature description. Follow this workflow exactly.

## Step 1a — Draft the user story

From the user's description, draft:
- A **short folder name** (kebab-case, 2–4 words, e.g. `user-avatar-upload`)
- A **user story** in this format:

  **As a** [user type], **I want** [goal] **so that** [reason]

Before presenting to the user:
1. Check whether `~/.claude/features/<short-name>/` already exists. If it does, warn the user:
   _"A feature folder named `<short-name>` already exists. Proceeding will overwrite its files. Continue?"_
   Do not proceed until they confirm.
2. Check for a name collision with any other folder directly under `~/.claude/features/` (excluding `done/`).

Present the folder name and user story. Ask: _"Does this capture what you want to build? Confirm or suggest changes."_
If they request changes, redraft and re-present — repeat up to 2 times.
If still not approved after 2 redrafts, ask the user to provide a revised description directly.
Do not proceed to Step 1b until the user confirms the story.

## Step 1b — Draft acceptance criteria

Draft **3–5 acceptance criteria** — specific, testable conditions that must all be true for the story to be
considered done. Good criteria are:
- **Specific**: unambiguous about what must happen
- **Testable**: someone can verify pass/fail without interpretation
- **User-visible**: describes observable outcomes, not implementation details

Present the criteria in checkbox format. Ask:
_"These criteria will drive the entire plan and implementation — every design decision and task will trace back to
them. Does each one fully define a 'done' state? Are any missing, too vague, or out of scope? Refine as many
times as needed."_

If they request changes, redraft and re-present. Repeat until the user explicitly confirms they are satisfied.
There is no iteration cap — getting the acceptance criteria right is the most important step in the whole flow.

Do not proceed to Step 2 until the user explicitly approves the acceptance criteria.

## Step 2 — Create the story file

Once approved, create the directory and file (the `~/.claude/features/` directory may not exist yet — create it if needed):

```
~/.claude/features/<short-name>/story.md
```

Contents of `story.md`:

```md
# <Short descriptive title>

> Original request: <user's exact words, verbatim>
> Created: <today's date>

**As a** [user type], **I want** [goal] **so that** [reason]

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>
[add more as needed]

## Notes

-
```

## Step 3a — Spawn planning subagent

Spawn a **foreground** subagent (`subagent_type: general-purpose`) and **wait for it to finish** before continuing.
Replace `<short-name>` with the actual folder name.

```
You are creating a high-level plan for a user story.

Story file: ~/.claude/features/<short-name>/story.md

Read that file to understand the goal and acceptance criteria.

The acceptance criteria are the ground truth for what this feature must achieve. Treat them as primary design
constraints — every section of your plan must be traceable to at least one criterion, and no criterion should be
left unaddressed.

## Repo detection

Always start by identifying the current repo from the working directory name.

Check whether a context file exists at ~/.claude/repo-context/<repo-name>.md and read it if so — this contains
purpose, architecture, dependencies, design patterns, and inter-repo relationships. Do not re-read the source
for this repo if the context file covers what you need.

If the current working directory contains /work/, also list all directories in ~/Developer/work/. Then:
1. Check which repos have a pre-built context file: `ls ~/.claude/repo-context/ 2>/dev/null`
2. For repos **with** a context file, read `~/.claude/repo-context/<repo-name>.md`. Do not re-read source for
   these repos unless the context file says "Unknown" for something critical to the story.
3. For repos **without** a context file, read enough code to understand what it does — start with README.md,
   package.json, go.mod, Podfile, or equivalent manifest files.

Based on the story goal and acceptance criteria, identify which repos will need changes. Prefer repos listed
under "Internal repo dependencies" in context files of the current repo when tracing the call chain.

## Plan

Write a plan.md file to ~/.claude/features/<short-name>/plan.md using exactly this template:

---
# Plan: <Feature Title>

> Created: <today's date>

## Summary
[What needs to be built — 2–4 sentences]

## Design Decisions
[Key architectural choices and why]

## Implementation Phases
[Ordered steps — numbered list]

## Repos Involved
[Every repo that will need changes, each with a short reason why. Always includes at least the current repo.]

## Open Questions
[Ambiguities or decisions that need resolution before implementation starts. Leave blank if none.]
---

Keep it concise. Do not implement anything. Lines must not exceed 140 characters.
```

## Step 3b — Spawn review subagent

After the planning subagent has finished and `plan.md` exists, spawn **1 subagent** (`subagent_type: general-purpose`)
and **wait for it to finish** before continuing.

```
You are reviewing a high-level feature plan. You have access to the filesystem.

Story: ~/.claude/features/<short-name>/story.md
Plan:  ~/.claude/features/<short-name>/plan.md

Read both files.

## 1. Story & Acceptance Criteria Coverage

- Does the plan fully address the user's goal and each acceptance criterion stated in the story?
- Are there missing cases, overlooked user needs, or gaps between what the story asks for and what the plan
  proposes to build?
- Is the scope appropriate — neither too narrow (misses the goal) nor too broad (solves more than asked)?

Output a **Verdict** (Approved / Needs changes) followed by specific gaps or suggestions.

## 2. Repo & Dependency Coverage

- Read the plan's "Repos Involved" section to see which repos are already listed.
- For those repos only, check ~/Developer/work|personal/ and read their context files at
  ~/.claude/repo-context/<repo-name>.md if they exist.
- Are all necessary repos listed? Are any listed repos unnecessary?
- Are inter-repo dependencies (API contracts, shared types, event flows) correctly identified?

Output a **Verdict** (Approved / Needs changes / N/A).

## Step 3 — Collect review findings

After the reviewer returns, write its output to `~/.claude/features/<short-name>/plan-review.md`:

```md
# Plan Review

> Reviewed: <today's date>

## Story & Acceptance Criteria Coverage
[Verdict and findings]

## Repo & Dependency Coverage
[Verdict and findings, or "N/A — not a /work/ context"]

## Suggested Changes
[Consolidated, deduplicated list of actionable changes]
```

## Step 3b — Spawn fix subagent

Spawn a **foreground** subagent and **wait for it to finish** before continuing.

```
You are revising a high-level feature plan based on a review.

Story:  ~/.claude/features/<short-name>/story.md
Plan:   ~/.claude/features/<short-name>/plan.md
Review: ~/.claude/features/<short-name>/plan-review.md

Read all three files. Then:

1. For each item under "Suggested Changes" in the review, decide whether it is clearly correct and improves
   the plan — meaning it closes a genuine gap or fixes an error. Apply those changes.
   Skip anything speculative, stylistic, or that contradicts the story goal.
2. Rewrite ~/.claude/features/<short-name>/plan.md with accepted changes applied. Keep the same template
   structure. Update the header to add `> Last revised: <today's date>` below the Created line.
   Lines must not exceed 140 characters.
3. Append a `## Revisions` section at the bottom of plan.md with a changelog table:

| Suggestion | Decision | Rationale |
|------------|----------|-----------|
| [brief description] | Applied / Rejected | [why] |
```

## Step 4 — Confirm

Tell the user the feature plan is finished. Show the feature folder path and give a one-line summary of
what was planned.

Include a brief review summary:
- Story & Acceptance Criteria Coverage verdict
- Repo & Dependency Coverage verdict (or N/A)
- Architectural Soundness verdict
- Number of suggestions applied vs. rejected

Then prompt: _"Next step: run `/feature-impl-plan` to break this into tasks and build an implementation plan."_

## Rules

- Never skip the approval step — writing files before the user confirms can create stale or
  misnamed feature folders that are annoying to clean up
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<short-name>/`
- All related md files for a feature go in that feature's folder
- The `## Revisions` section appended to `plan.md` is the downstream-visible record of review changes;
  `plan-review.md` is for human inspection only and is not read by downstream skills
