---
name: feature-done
description: >-
  Verify a feature is complete and archive it by moving it to ~/.claude/features/done/.
  Use whenever the user says a feature is finished, done, or ready to close — even if they
  don't say /feature-done explicitly. Checks that all acceptance criteria are implemented
  and reviewed in story.md before moving, so nothing gets archived with loose ends.
argument-hint: [feature-name]
---

# Feature Done Workflow

The user has invoked `/feature-done`. Follow this workflow exactly.

This flow checks acceptance criteria checkboxes in `story.md`.

## Step 1 — Resolve the feature

**If `$ARGUMENTS` is provided:**
- Treat it as the folder name under `~/.claude/features/<name>/`
- If the folder does not exist, try a fuzzy match against existing folder names
  in `~/.claude/features/` (exclude `done/`)
- If no match is found, list available features and ask the user to pick one

**If no argument is provided:**
- Infer from the current session conversation which feature is being discussed
- If unclear, scan `~/.claude/features/` for feature folders (exclude `done/`),
  list them (numbered), and ask the user to pick one (by number or name)

## Step 2 — Verify completeness

Read `~/.claude/features/<name>/story.md`. Check each acceptance criterion:

1. **All criteria implemented:** Every criterion must have `- [x] Implemented`
   under it. List any that don't.
2. **All criteria reviewed:** Every implemented criterion must have
   `- [x] Reviewed` under it. List any that don't — this checkbox is marked by
   `/feature-code-fix` once the review cycle completes.
3. **Review file present:** Check that `~/.claude/features/<name>/review-fixes.md`
   exists. If it doesn't, warn that `/feature-code-review` hasn't been run.

If any criteria are not implemented or the review is missing, report what's
outstanding and ask the user how to proceed:
- Continue anyway (force move)
- Go back and finish (abort)

Do not proceed unless the user explicitly confirms.

## Step 3 — Mark top-level criteria

Before moving, mark each fully completed criterion's top-level checkbox. For every
criterion where both `- [x] Implemented` and `- [x] Reviewed` are checked, change
the top-level `- [ ]` to `- [x]`:

```md
- [x] <criterion text>
  - [x] Implemented
  - [x] Reviewed
```

This gives a clean final state in `story.md` where all criteria are visibly complete.

## Step 4 — Move to done

1. Create `~/.claude/features/done/` if it doesn't exist
2. Move the entire feature folder:
   `mv ~/.claude/features/<name> ~/.claude/features/done/<name>`
3. Verify the move succeeded by checking the destination exists

## Step 4b — Clean up worktrees

Read `story.md` (now at `~/.claude/features/done/<name>/story.md`) and check
for `> Worktree: true`. If that line is **not** present, skip this step.

If the feature used worktrees:

1. **Collect all worktrees to clean up.** Check for a `## Worktrees` table in
   `story.md`. If present, each row is a worktree to remove. If no table
   exists, use the single worktree from the header metadata:
   - `> Worktree source:` — the path to the original repo
   - `> Working directory:` — the worktree path to remove

2. **For each worktree**, run the following cleanup:

   a. Remove the git worktree from the source repo:
      ```sh
      git -C "<worktree-source>" worktree remove "<worktree-path>" --force
      ```
      If the worktree directory was already deleted or is not registered, run:
      ```sh
      git -C "<worktree-source>" worktree prune
      ```
   b. If the worktree directory still exists after removal (e.g. untracked
      files prevented cleanup), delete it:
      ```sh
      rm -rf "<worktree-path>"
      ```
   c. Kill the associated tmux session if one exists. Derive the session name
      from the worktree directory basename using the same logic as the
      sessionizer — replace `:`, spaces, and `.` with `_`, lowercase, then
      capitalise the first letter:
      ```sh
      dir_name=$(basename "<worktree-path>")
      session_name=$(echo "$dir_name" \
        | tr ':. ' '___' | tr '[:upper:]' '[:lower:]')
      session_name=$(echo "${session_name:0:1}" \
        | tr '[:lower:]' '[:upper:]')${session_name:1}
      tmux kill-session -t "$session_name" 2>/dev/null
      ```
      If no tmux session with that name exists, this is a no-op.

## Step 5 — Report

Tell the user:
- Feature `<name>` has been moved to `~/.claude/features/done/<name>/`
- Summary: X of Y acceptance criteria completed, review status
- If a worktree was cleaned up: which directory was removed, which tmux
  session was killed (or "no active session found"). If multiple worktrees
  were cleaned up, list each one.
- The feature is now archived

## Rules

- Never move a feature without checking acceptance criteria status first
- Always ask for confirmation if any criteria are incomplete
- Do not delete any files — only move the folder
- Worktree cleanup must happen after the feature folder is moved, not before
- Never delete the worktree source repo — only the worktree directory itself
