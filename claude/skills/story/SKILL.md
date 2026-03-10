---
name: story
description: Create a new user story. Use when the user runs /story followed by a feature description. Drafts a user story for approval, then creates the story folder and md file under ~/.claude/stories/.
argument-hint: <feature description>
---

# Story Workflow

The user has invoked `/story` with a feature description. Follow this workflow exactly.

## Step 1 — Draft the story

From the user's description, draft:
- A **short folder name** (kebab-case, 2–4 words, e.g. `user-avatar-upload`)
- A **user story** in this format:

  **As a** [user type], **I want** [goal] **so that** [reason]

Present both to the user and ask for approval. Do not proceed until they confirm or request changes.

## Step 2 — Create the story file

Once approved, create the directory and file (the `~/.claude/stories/` directory may not exist yet — create it if needed):

```
~/.claude/stories/<short-name>/story.md
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

Story file: ~/.claude/stories/<short-name>/story.md

Read that file to understand the goal.

## Repo detection

If the current working directory contains /work/, list all directories in ~/Developer/work/. For each repo, read enough code to understand what it does — start with README.md, package.json, go.mod, Podfile, or equivalent manifest files. Based on the story goal and what you find, identify which repos will need changes.

## Plan

Write a plan.md file to ~/.claude/stories/<short-name>/plan.md with:

- **Summary** — what needs to be built
- **Design decisions** — key architectural choices
- **Implementation phases** — ordered steps
- **Repos involved** (only if in a /work/ context) — each repo with a short reason why it's needed

Keep it concise. Do not implement anything.
```

Run the subagent in the background so the user is not blocked.

## Step 4 — Confirm

Tell the user the story has been saved and that a plan is being drafted in the background. Show the story file path.

## Rules

- Never skip the approval step — the user must confirm before any file is written
- Use kebab-case for folder names, lowercase only
- Active stories live directly in `~/.claude/stories/`
- Completed stories are moved to `~/.claude/stories/done/<short-name>/`
- All related md files for a story go in that story's folder
