---
name: feature-implement
description: >-
  Implement a feature directly from its story and high-level plan. Use whenever the user is
  ready to start coding — even if they just say "start building", "let's go", or "implement
  it". Reads story.md and plan.md, implements the feature using its own judgment for task
  ordering, writes tests ad-hoc, and marks acceptance criteria as implemented.
argument-hint: [feature-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Feature Implementation Workflow

The user has invoked `/feature-implement`. Follow this workflow exactly.

There are no pre-defined tasks, waves, or subagent assignments. You read the story and
high-level plan, then implement the feature using your own judgment for ordering and approach.

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

Read all `.md` files in `~/.claude/features/<name>/`. Expect at minimum:
- `story.md` — the user story with acceptance criteria (the source of truth)
- `plan.md` — the high-level plan with design decisions and implementation phases

If `story.md` or `plan.md` is missing, tell the user and suggest running
`/feature-plan` first.

## Step 3 — Detect repos, branches, and context

From `plan.md`, identify:
- Which repos need changes (check the **Repos Involved** section)
- Determine appropriate branch names

For each repo:
1. Check if `~/.claude/repo-context/<repo-name>.md` exists and read it — it contains
   architecture, design patterns, and inter-repo dependencies that inform how code
   should be written.
2. Check out the correct branch. If the branch already exists, use it. If not,
   create it from the main/master branch.

## Step 4 — Resume check

Before starting, scan `story.md` for acceptance criteria already marked
`- [x] Implemented`. Skip those and report which ones were already done
(e.g., "Resuming: criteria 1 and 2 already implemented. Starting from criterion 3.").

## Step 5 — Implement the feature

Read the **Implementation Phases** and **Design Decisions** sections from `plan.md`. Use
them as your guide, but you have full discretion over:
- How to decompose the work into concrete coding steps
- What order to implement things in
- How to handle cross-cutting concerns

### Implementation guidelines

1. **Follow the plan's design decisions.** If the plan says "use a middleware approach"
   or "store in Redis", do that. Don't second-guess reviewed decisions.

2. **Follow the plan's implementation phases in order.** The phases define a logical
   progression. You may split a phase into sub-steps or combine small phases, but don't
   reorder them unless there's a technical reason (and note the deviation).

3. **Write tests as you go.** There is no pre-defined test plan. Write tests alongside
   implementation, guided by the acceptance criteria. At minimum:
   - Unit tests for non-trivial business logic
   - Integration tests for API endpoints or cross-module interactions
   - Follow existing test conventions in the repo (detect from repo-context or by
     reading existing test files)

4. **Check the acceptance criteria frequently.** They are the source of truth for what
   "done" means. After completing each implementation phase, check which criteria you've
   satisfied.

5. **Handle open questions.** If `plan.md` has an **Open Questions** section with
   unresolved items that affect what you're implementing, ask the user before proceeding.

6. **Cross-repo work.** If the plan involves multiple repos, implement changes in
   dependency order — upstream repos first, then downstream consumers.

### Progress tracking

After completing work that satisfies an acceptance criterion, mark it in `story.md`:

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

After implementation is complete, run only the test files written or modified during
implementation:

1. Collect all test files written or modified during Step 5.
2. If you modified source files but not their associated test files, also run the test
   files most closely associated with those source files (same module, adjacent test
   directory, etc.).
3. Do not run the full test suite — limit scope to touched test files only.

**Exception:** For Xcode/iOS projects, automated test runs can get stuck or time out. In
that case, prompt the user to run the relevant tests and share the output instead.

Once results are available (from auto-run or user-reported), diagnose any failures and fix
them. If a fix requires changes beyond the plan's scope, ask before proceeding.

## Step 7 — Report

When implementation is complete, report:
- Which acceptance criteria are now marked as implemented
- Which criteria are not yet implemented (if any) and why
- Test results
- Any deviations from the plan and why

Then prompt: _"Next step: run `/feature-code-review <name>` to review the
implemented code, then `/feature-code-fix <name>` to apply any fixes."_
(replace `<name>` with the actual feature folder name resolved in Step 1).

## Rules

- Follow the plan's design decisions — they have been reviewed and approved
- If the plan has open questions, ask the user before implementing the affected areas
- If you discover something the plan got wrong (e.g., a file path changed, a function
  was renamed, an API works differently than assumed), fix it and note the deviation
- Do not create commits unless the user asks — just make the changes
- Do not push to remote unless the user asks
- Mark acceptance criteria as implemented incrementally, not in a batch at the end
