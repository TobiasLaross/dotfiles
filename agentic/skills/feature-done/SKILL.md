---
name: feature-done
description: >-
  Verify a feature is complete and archive it by moving it to ~/.claude/features/done/. Use
  whenever the user says a feature is finished, done, or ready to close — even if they don't
  say /feature-done explicitly. Checks that all tasks are implemented and reviewed before moving,
  so nothing gets archived with loose ends.
argument-hint: [feature-name]
---

# Feature Done Workflow

The user has invoked `/feature-done`. Follow this workflow exactly.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one

**If no argument is provided:**
- Infer from the current session conversation which feature is being discussed
- If unclear, scan `~/.claude/features/` for feature folders (exclude `done/`), list them (numbered), and ask the user to pick one (by number or name)

## Step 2 — Verify completeness

Read `~/.claude/features/<name>/impl-plan.md`. Check:

1. **All tasks implemented:** Every task must have `- [x] Implemented`. List any
   that don't.
2. **All tasks reviewed:** Every implemented task must have `- [x] Reviewed`. List
   any that don't — this checkbox is marked by `/feature-code-fix` once the review
   cycle completes.
3. **Review file present:** Check that `~/.claude/features/<name>/review-fixes.md`
   exists. If it doesn't, warn that `/feature-code-review` hasn't been run.

If any tasks are not implemented or the review is missing, report what's
outstanding and ask the user how to proceed:
- Continue anyway (force move)
- Go back and finish (abort)

Do not proceed unless the user explicitly confirms.

## Step 3 — Move to done

1. Create `~/.claude/features/done/` if it doesn't exist
2. Move the entire feature folder: `mv ~/.claude/features/<name> ~/.claude/features/done/<name>`
3. Verify the move succeeded by checking the destination exists

## Step 4 — Report

Tell the user:
- Feature `<name>` has been moved to `~/.claude/features/done/<name>/`
- Summary: X tasks implemented, review status
- The feature is now archived

## Rules

- Never move a feature without checking task status first
- Always ask for confirmation if any tasks are incomplete
- Do not delete any files — only move the folder
