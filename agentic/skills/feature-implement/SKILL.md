---
name: feature-implement
description: >-
  Implement a feature directly from its story. Use whenever the user is ready to start
  coding — even if they just say "start building", "let's go", or "implement it". Reads
  story.md (user story, discovery, acceptance criteria, repos, open questions),
  implements the feature using its own judgment for task ordering, writes tests ad-hoc,
  and marks acceptance criteria as implemented.
argument-hint: [feature-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Feature Implementation Workflow

The user has invoked `/feature-implement`. Follow this workflow exactly.

There are no pre-defined tasks, waves, or subagent assignments. You read `story.md`
(the only artifact `/feature-plan` produces) and implement the feature using your own
judgment for ordering and approach. Acceptance criteria define *what* to build;
discovery captures the *why*; repos and open questions tell you where and what's
unresolved. Everything else — file layout, code structure, test decomposition — is
yours to decide.

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

## Step 2 — Read feature files

Read `~/.claude/features/<name>/story.md` — it is the only required artifact and
contains: user story, discovery decisions, acceptance criteria (with
`Implemented`/`Reviewed` tracking), repos involved, and any open questions.

If `story.md` is missing, tell the user and suggest running `/feature-plan`
first.

## Step 3 — Detect repos, branches, and context

From `story.md`, identify:
- Which repos need changes (check the **Repos Involved** section)
- Determine appropriate branch names (convention: `feature/<name>`)

Check `story.md` for `> Worktree: true`. If present, the worktree was already
created by `/feature-plan` with the correct branch checked out. In that case:
- Read `> Working directory:` to confirm the worktree path exists
- Read `> Branch:` to confirm the branch name
- **Skip branch creation entirely** — the worktree is already on the correct
  branch
- Read repo context as described below

If `> Worktree: true` is **not** present, handle branches normally:

For each repo:
1. Check if `~/.claude/repo-context/<repo-name>.md` exists and read it — it
   contains architecture, design patterns, and inter-repo dependencies that
   inform how code should be written.
2. Check out the correct branch. If the branch already exists, use it. If not,
   create it from the main/master branch.

Store the branch name in `story.md` by adding a `> Branch: <branch>` line
after the `> Working directory:` line (if not already present).

## Step 3b — Trigger filesystem access

To surface permission prompts early (before implementation begins), touch a
file in every directory the agent will write to:

1. The feature folder (already accessed in Step 2):
   `touch ~/.claude/features/<name>/.gitkeep`
2. Each repo that will be modified (from **Repos Involved** in `story.md`).
   If worktrees exist, use the worktree paths instead:
   ```sh
   touch "<repo-or-worktree-path>/.feature-touch"
   rm "<repo-or-worktree-path>/.feature-touch"
   ```

This ensures the user approves directory access once, upfront, rather than
being prompted mid-implementation.

## Step 4 — Resume check

Before starting, scan `story.md` for acceptance criteria already marked
`- [x] Implemented`. Skip those and report which ones were already done
(e.g., "Resuming: criteria 1 and 2 already implemented. Starting from
criterion 3.").

## Step 5 — Implement the feature

Read `story.md` end-to-end. The **Acceptance Criteria** define *what* you must
build (the spec), **Discovery** captures the product-owner *why* and any
non-obvious constraints, **Repos Involved** lists which codebases are in scope,
and **Open Questions** flags anything still unresolved. You have full discretion
over:
- How to decompose the work into concrete coding steps
- What order to implement criteria in
- How to handle cross-cutting concerns
- File layout, code structure, abstractions

### Implementation guidelines

1. **Treat the acceptance criteria as the spec.** Every criterion must be
   satisfied. Discovery decisions are constraints on *how* the criteria are
   met (e.g. "duplicates are rejected via a clear error message" — discovery
   may say what "clear" means in this product). Don't add behavior the
   criteria don't ask for.

2. **Pick an implementation order that builds confidence early.** A reasonable
   default is the simplest end-to-end behavior first, then layer in edge
   cases and out-of-scope guards. Group closely related criteria when it
   reduces churn.

3. **Write tests as you go.** There is no pre-defined test plan. Write tests
   alongside implementation, driven by the acceptance criteria. At minimum:
   - Unit tests for non-trivial business logic
   - Integration tests for API endpoints or cross-module interactions
   - Follow existing test conventions in the repo (detect from repo-context or
     by reading existing test files)

4. **Check the acceptance criteria frequently.** They are the source of truth
   for what "done" means. Mark criteria implemented incrementally as you
   satisfy them.

5. **Handle open questions.** If `story.md` has unresolved items in **Open
   Questions** that affect what you're implementing, ask the user before
   proceeding on the affected area.

6. **Cross-repo work.** If multiple repos are listed under **Repos Involved**,
   implement in dependency order — upstream repos first, then downstream
   consumers.

### Progress tracking

After completing work that satisfies an acceptance criterion, mark it in
`story.md`:

Change:
```md
- [ ] <criterion text>
  - [ ] Implemented
  - [ ] Reviewed
```

To:
```md
- [ ] <criterion text>
  - [x] Implemented
  - [ ] Reviewed
```

Do this incrementally as you go — not all at once at the end.

## Step 6 — Tests

Check `story.md` for `> Tests: auto` or `> Tests: manual`.

**If `auto` (or no preference is recorded):**

After implementation is complete, run only the test files written or modified
during implementation:

1. Collect all test files written or modified during Step 5.
2. If you modified source files but not their associated test files, also run
   the test files most closely associated with those source files (same module,
   adjacent test directory, etc.).
3. Do not run the full test suite — limit scope to touched test files only.

Once results are available, diagnose any failures and fix them. If a fix
requires changes beyond the plan's scope, ask before proceeding.

**If `manual`:**

Prompt the user to run the relevant tests. List the test files written or
modified during Step 5 so they know what to run. Wait for the user to share
the output. Diagnose any failures and fix them.

## Step 7 — Report and review

When implementation is complete and tests pass, report:
- Which acceptance criteria are now marked as implemented
- Which criteria are not yet implemented (if any) and why
- Test results
- Any deviations from the plan and why

Then automatically invoke `/feature-code-review <name>` (replace `<name>` with
the actual feature folder name resolved in Step 1). Do not wait for the user
to request the review — start it immediately after reporting.

## Rules

- The acceptance criteria are the spec — every criterion must be satisfied,
  and behavior outside the criteria should not be added
- Discovery decisions in `story.md` are constraints on how criteria are met;
  respect them
- If `story.md` has open questions that affect the area you're working on,
  ask the user before implementing it
- If you discover something the story got wrong (e.g., a discovery
  assumption that turns out to be inaccurate), fix it and note the deviation
- Do not create commits unless the user asks — just make the changes
- Do not push to remote unless the user asks
- Mark acceptance criteria as implemented incrementally, not in a batch at the
  end
