---
name: feature-auto
description: >-
  End-to-end autonomous feature flow. Runs /feature-plan for the interactive story + Q&A
  phase, then subagents orchestrated from this session handle implementation, code review,
  fixes, linting, full test runs, coverage top-up, commits, and PR creation for every repo
  involved. Use when the user wants the whole plan-to-PR flow handled hands-off — even if
  they just say "do the whole thing", "plan and ship it", or "auto feature X". Does NOT
  run /feature-done; the feature folder stays active until PRs merge.
argument-hint: <feature description or existing-name>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion, Skill
---

# Feature Auto Workflow

The user has invoked `/feature-auto`. This is the hands-off end-to-end flow.

The only manual checkpoints are the two early `/feature-plan` sign-offs
that shape the feature's intent:

1. User story confirmation (`/feature-plan` Step 2)
2. Discovery Q&A (`/feature-plan` Step 3)

**Everything after Q&A is autonomous** — including the acceptance-criteria
draft + review, repos / open-questions capture, and the final story
write-out. The subagent-revised criteria from Step 5 are auto-approved; the
repos and open questions from discovery are written directly to `story.md`;
the final story review is skipped. Implementation, code review, fixes,
lint, full test runs, coverage top-up, commits, and PR creation are handled
by subagents **orchestrated from this session**. Worktrees are created by
`/feature-plan`; subagents operate on the worktree paths via absolute paths.
The orchestrator does not change its cwd, and no secondary `claude -p`
session is spawned (unlike `/ralph`).

**This skill does NOT run `/feature-done`.** The feature folder stays in
`~/.claude/features/<name>/` until the user runs `/feature-done` after the
PRs merge.

## Step 1 — Announce the flow

Tell the user up-front what `/feature-auto` does and what is manual:

```
Starting /feature-auto. Manual checkpoints are only two early gates:
  - Confirm user story
  - Answer discovery questions

Everything after Q&A is autonomous:
  - Acceptance criteria drafted + subagent-reviewed + auto-approved
  - Repos, open questions, and final story written to story.md without re-prompts
  - Worktrees created for every repo involved
  - Implementation (ad-hoc tests, AC marked Implemented incrementally,
    non-obvious decisions appended to design.md)
  - Review + fix loop (up to 3 rounds; every finding auto-applied —
    loop exits when no criterion has Action Required checked)
  - Linters + full test suite + coverage top-up (≥95% on feature files)
  - Commit, push, and gh pr create for every repo involved

The feature is NOT archived — run /feature-done <name> yourself after
the PRs merge.
```

## Step 2 — Plan via `/feature-plan`

Invoke the `/feature-plan` skill with `$ARGUMENTS`. Follow every step in
`agentic/skills/feature-plan/SKILL.md` **with these overrides — all post-Q&A
sign-offs are bypassed**:

- **Step 6 (acceptance-criteria approval):** do **not** prompt the user to
  approve the revised criteria. The Step 5 subagent's revised list is
  treated as approved. Still show the revised criteria and the Step 5
  changelog to the user as an informational update so they can spot
  anything obviously wrong — but proceed without waiting for a reply.
- **Step 7a/b (repos + open-questions confirmation):** do **not** ask the
  user to confirm. Derive the repos and open questions from discovery and
  write them directly into `story.md`.
- **Step 7c (test preference):** do **not** ask. Test preference for
  `/feature-auto` is always `auto`. Record `> Tests: auto` in `story.md`
  directly.
- **Step 9 (final story approval):** do **not** prompt for final approval.
  Write `story.md` and proceed straight to Step 10 (worktree creation).
- **Step 11 (offer implementation path):** do **not** prompt the user to
  pick `/feature-implement` / `/ralph`. After worktrees are
  created (Step 10), proceed directly to Step 3 below.

`/feature-plan` seeds both `story.md` and `design.md`. After it finishes:

1. Read `~/.claude/features/<name>/story.md`.
2. Note that `~/.claude/features/<name>/design.md` exists as an empty
   living log — every subagent you spawn must read it before working
   and append any non-obvious decisions it makes.
3. Extract the primary worktree path from `> Working directory:`.
4. If a `## Worktrees` table is present, collect every `(repo, worktree
   path, source, branch)` row. Otherwise the primary worktree covers
   the only repo.
5. Store this set — every downstream subagent needs the absolute
   worktree paths.

If `> Worktree: true` is **not** present in `story.md` (user declined
worktrees in the initial prompt to `/feature-plan`), use the repo
directories listed under **Repos Involved** as the working paths. The
rest of the flow is unchanged.

## Step 3 — Implement via subagent

Spawn one `general-purpose` subagent to carry out the implementation.
Wait for it to complete.

The subagent prompt must include:

- Full contents of `story.md` and `design.md`
- Feature folder path (`~/.claude/features/<name>/`)
- Every worktree path (absolute) with its repo name
- Instruction to follow `agentic/skills/feature-implement/SKILL.md`
  Steps 3b through 6, with these constraints:
  - Operate via **absolute paths** and `git -C "<worktree>"`. Do not
    assume a particular cwd; the orchestrator keeps its own.
  - Skip branch creation — worktrees already have `feature/<name>`
    checked out.
  - Write tests ad-hoc alongside implementation, targeting near-100%
    line/branch coverage for the code it introduces.
  - Mark each acceptance criterion `- [x] Implemented` in `story.md`
    incrementally as it satisfies them. Do **not** touch `Reviewed`
    or `Action Required` — those are owned by the review/fix flows.
  - Append non-obvious implementation decisions to `design.md` using
    the entry format at the bottom of that file, tagging the entry's
    **Source** as `feature-implement`.
  - Run only the test files it wrote/touched at the end (Step 6 `auto`
    mode). The full lint + test + coverage sweep runs later in Step 5.

When the subagent returns, re-read `story.md`. If any acceptance
criterion still shows `- [ ] Implemented`, spawn a follow-up subagent
with the remaining gaps and wait for it. Cap the follow-up at two
attempts — if criteria still aren't implemented after two retries,
surface the gap to the user.

## Step 4 — Review / fix loop

Iterate review + fix until **no criterion has `- [x] Action Required`**,
with a hard cap of **3 rounds**.

### 4a — Review

Spawn a `general-purpose` subagent to execute the full workflow in
`agentic/skills/feature-code-review/SKILL.md` for `<name>`. Include the
worktree paths, feature folder path, and `design.md` path in the
prompt. The subagent writes
`~/.claude/features/<name>/review-fixes.md` and — via `/review-code`'s
Behavior Verification agent — checks `- [x] Reviewed` on every
criterion it covers, and checks `- [x] Action Required` on every
criterion that has findings requiring a code change.

### 4b — Triage

Read `story.md` and `review-fixes.md`.

- If no criterion has `- [x] Action Required` checked: exit the loop
  and proceed to Step 5.
- Otherwise: proceed to 4c.

### 4c — Fix (auto-accept all findings)

Spawn a `general-purpose` subagent to execute
`agentic/skills/feature-code-fix/SKILL.md` Step 4 (the execution
subagent) directly. `/feature-auto` pre-authorises full auto-apply, so
**skip the Step 3 interactive triage** — every finding in
`review-fixes.md` is treated as accepted. The fix subagent will:

- Apply every accepted finding.
- Append non-obvious decisions to `design.md` with Source
  `feature-code-fix F<id>`.
- Uncheck `Action Required` for every criterion whose findings were
  all resolved.
- Update `review-fixes.md` with per-finding status.

Return to 4a for the next round.

### Loop exit

If round 3 still has criteria with `- [x] Action Required`, stop the
loop and surface the outstanding criteria + findings to the user —
this signals a reviewer/fixer disagreement that needs human judgment.
Do not proceed to Step 5 until the user decides.

After the loop exits cleanly, confirm that every criterion with
`- [x] Implemented` also has `- [x] Reviewed` and that no criterion
has `- [x] Action Required`. Any deviation means a subagent missed
an update — fix it before moving on.

## Step 5 — Lint, full tests, coverage

Spawn one `general-purpose` subagent per repo (parallel when repos are
independent). Each subagent receives:

- The worktree path (absolute)
- Repo name and `~/.claude/repo-context/<repo>.md` path (if it exists)
- Paths to `story.md` and `design.md` (for feature context)
- The list of files the feature touched (derive with
  `git -C <worktree> diff --name-only origin/<base-branch>`)

Each subagent's job:

1. **Detect tools.** From the repo's config files — `package.json`,
   `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle`,
   `Package.swift`, `.swiftformat`, `.swiftlint.yml`, `Makefile`, CI
   workflow files — identify the linter, formatter, test runner, and
   coverage tool. Fall back to repo-context if present.
2. **Run linters + formatters.** Fix every failure. Do not suppress or
   silence — fix the root cause.
3. **Run the full test suite.** All tests must pass.
4. **Measure coverage on files touched by the feature.** Use the repo's
   coverage tool when available.
5. **Top up coverage.** Target ≥95% line/branch coverage on feature
   files. For every uncovered line or branch, add a test that
   exercises it. Skip only genuinely unreachable code, with a one-line
   justification in the subagent report.
6. **Re-run lint + tests** to confirm green state after additions.
7. **Log test-strategy decisions.** If the subagent makes a non-obvious
   testing choice (e.g. stubbing a boundary, choosing contract vs unit
   scope for a piece of logic), append to `design.md` with Source
   `feature-auto Step 5`.

Each subagent reports back:

- Lint / format status
- Test counts (pass / fail)
- Coverage percentage per changed file and overall
- Any justified gaps

If any repo reports unresolved failures, or coverage below the
threshold without valid justification, surface it to the user before
Step 6.

## Step 6 — Commit, push, PR per repo

`/feature-auto` is a pre-authorisation for push + PR creation. Do not
re-prompt for confirmation at this step — the user signed up for this
when they invoked the skill.

For each repo listed under **Repos Involved** in `story.md`:

1. **Commit.** From the worktree, stage only the feature-related files
   and commit with a message matching the repo's style.
   ```sh
   git -C "<worktree>" add <feature-related paths>
   git -C "<worktree>" commit -m "<short imperative message>"
   ```
   Inspect `git -C <worktree> log --oneline -20` to match the repo's
   commit-message style (e.g. this dotfiles repo uses `Added <X>` /
   `Updated <X>` / `Fixed <X>`). Split into multiple commits when it
   produces a cleaner history. Do **not** include Claude attribution
   (no `Co-Authored-By` line) unless the user asks.
2. **Push.**
   ```sh
   git -C "<worktree>" push -u origin "feature/<name>"
   ```
3. **Open the PR.** Run `gh` from inside the worktree
   (`cd "<worktree>" && gh pr create ...`) so `gh` picks up the repo
   automatically.
   ```sh
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   - <bullet 1 from AC>
   - <bullet 2>

   ## Test plan
   - Unit tests: <count> passing
   - Integration tests: <count> passing
   - Coverage on feature files: <%>
   - Linters: clean

   Feature folder: ~/.claude/features/<name>/
   EOF
   )"
   ```
   Title derives from the user story (under 70 chars). Capture the PR
   URL from stdout.

After every PR is created, append a `## PRs` section to `story.md`
(place it before `## Notes`):

```md
## PRs

| Repo | PR |
|------|----|
| <repo-name> | <pr-url> |
| <repo-name-2> | <pr-url-2> |
```

## Step 7 — Final report

Tell the user:

- **Implementation:** N of N acceptance criteria implemented + reviewed
- **Review/fix loop:** N rounds used, all Action Required cleared (or
  note what was surfaced)
- **Lint / tests / coverage:** per repo, with coverage percentages
- **PRs:** clickable list, one per repo
- **Design log:** whether `design.md` got any new entries
- **Next step:** `/feature-done <name>` once the PRs merge — the
  feature folder is intentionally still active

## Rules

- The only manual moments in `/feature-auto` are the two early
  `/feature-plan` sign-offs: user story confirmation (Step 2) and
  discovery Q&A (Step 3). The rest of the flow runs autonomously.
- Every subagent operates on worktree paths via absolute paths; the
  orchestrator never changes its own cwd.
- Every subagent reads `design.md` before working and appends
  non-obvious decisions with the correct Source tag.
- Force `> Tests: auto`; never ask.
- Exit the review/fix loop on **no `Action Required` checkboxes**, not
  on finding severity counts.
- Never invoke `/feature-done` from this skill — the user archives
  after merge.
- `/feature-auto` pre-authorises `git push` and `gh pr create`; do not
  re-prompt at Step 6.
- Surface — don't swallow — lint failures, coverage shortfalls, or
  outstanding Action Required criteria after 3 rounds.
- Markdown lines must stay under 140 characters.
