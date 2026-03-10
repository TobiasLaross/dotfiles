---
name: feature-plan
description: Create a new feature plan. Use when the user runs /feature-plan followed by a feature description. Drafts a user story for approval, then creates the feature folder and files under ~/.claude/features/.
argument-hint: <feature description>
---

# Feature Plan Workflow

The user has invoked `/feature-plan` with a feature description. Follow this workflow exactly.

## Step 1 — Draft the story

From the user's description, draft:
- A **short folder name** (kebab-case, 2–4 words, e.g. `user-avatar-upload`)
- A **user story** in this format:

  **As a** [user type], **I want** [goal] **so that** [reason]

Present both to the user and ask for approval. Do not proceed until they confirm or request changes.

## Step 2 — Create the story file

Once approved, create the directory and file (the `~/.claude/features/` directory may not exist yet — create it if needed):

```
~/.claude/features/<short-name>/story.md
```

Contents of `story.md`:

```md
# <Short descriptive title>

**As a** [user type], **I want** [goal] **so that** [reason]

## Notes

- Created: <today's date>
```

## Step 3 — Spawn planning subagent

Immediately after writing `story.md`, spawn a subagent (`subagent_type: general-purpose`) with this prompt:

```
You are creating a high-level plan for a user story.

Story file: ~/.claude/features/<short-name>/story.md

Read that file to understand the goal.

## Repo detection

If the current working directory contains /work/, list all directories in ~/Developer/work/. For each repo, read enough code to understand what it does — start with README.md, package.json, go.mod, Podfile, or equivalent manifest files. Based on the story goal and what you find, identify which repos will need changes.

## Plan

Write a plan.md file to ~/.claude/features/<short-name>/plan.md with:

- **Summary** — what needs to be built
- **Design decisions** — key architectural choices
- **Implementation phases** — ordered steps
- **Repos involved** (only if in a /work/ context) — each repo with a short reason why it's needed

Keep it concise. Do not implement anything.

## After writing plan.md

Spawn a subagent (subagent_type: general-purpose) in the background to review the plan:

```
You are reviewing a plan against a user story.

Story: ~/.claude/features/<short-name>/story.md
Plan:  ~/.claude/features/<short-name>/plan.md

Read both files. Then:

1. Check whether the plan fully addresses the story goal — are there gaps, missing cases, or unclear phases?
2. If the current working directory contains /work/, re-examine the repos listed in plan.md. For each listed repo, verify the reasoning is sound by reading relevant code. Also check whether any repo in ~/Developer/work/ was missed.

Write your findings to ~/.claude/features/<short-name>/plan-review.md with:

- **Verdict** — Approved / Needs changes
- **Gaps** — anything the plan doesn't address that the story requires
- **Repo feedback** (only if in /work/ context) — corrections or additions to the repos listed
- **Suggested changes** — specific, actionable edits to plan.md if needed

After writing plan-review.md, spawn a subagent (subagent_type: general-purpose) in the background to apply agreed fixes:

```
You are revising a feature plan based on a review.

Story:  ~/.claude/features/<short-name>/story.md
Plan:   ~/.claude/features/<short-name>/plan.md
Review: ~/.claude/features/<short-name>/plan-review.md

Read all three files. Then:

1. For each item under "Suggested changes" in the review, decide whether it is clearly correct and improves the plan. Apply only the changes you agree with — skip anything speculative, stylistic, or that contradicts the story goal.
2. Rewrite ~/.claude/features/<short-name>/plan.md with the agreed fixes applied. Keep the same structure; only change what needs changing.
3. Append a ## Revisions section at the bottom of plan.md listing each change you made and why, and each suggestion you skipped and why.
```
```

Run the planning subagent in the background so the user is not blocked.

## Step 4 — Confirm

Tell the user the feature has been saved, that a plan is being drafted, and that a review will follow automatically. Show the feature folder path.

## Rules

- Never skip the approval step — the user must confirm before any file is written
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<short-name>/`
- All related md files for a feature go in that feature's folder
