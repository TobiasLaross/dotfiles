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

Once approved, create:

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

## Step 3 — Confirm

Tell the user the story has been saved and show the file path. Let them know they can add acceptance criteria, tasks, or other md files to the same story folder.

## Rules

- Never skip the approval step — the user must confirm before any file is written
- Use kebab-case for folder names, lowercase only
- Active stories live directly in `~/.claude/stories/`
- Completed stories are moved to `~/.claude/stories/done/<short-name>/`
- All related md files for a story go in that story's folder
