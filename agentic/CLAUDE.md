# Global Claude Instructions

## Feature Tracking

Features are tracked in `~/.claude/features/`. The folder and all files are created by
`/feature-plan` — do not create feature folders manually. When the user runs the skill,
it handles naming, folder creation, discovery, criteria drafting, and review.

### Three implementation flows

All flows start with `/feature-plan`, which creates `story.md` and seeds
`design.md`. `story.md` contains the user story, discovery decisions,
acceptance criteria (reviewed and revised by a subagent for full story
coverage), repos involved, and any open questions. `design.md` is a living
log of implementation-level design decisions (architecture, chosen patterns,
rejected alternatives with rationale) and is appended to by the
implementation, review, and fix flows as decisions get made. After planning,
the user chooses an implementation path:

- **Ralph** (`/feature-plan` → `/ralph`): True Ralph Wiggum loop. Same prompt piped to
  the agent every iteration. The agent sees its previous work through the filesystem
  and decides what to do next. No pre-decomposed tasks. Best for greenfield work where
  the agent should have full autonomy.
- **Feature flow** (`/feature-plan` → `/feature-implement` → review → fix → done):
  Interactive implementation in a single session. The agent reads `story.md` and
  implements using its own judgment for task ordering. Tracks progress via
  acceptance criteria checkboxes in `story.md`. Best for hands-on implementation
  where the user wants to guide decisions.
- **Auto** (`/feature-auto`): End-to-end autonomous flow orchestrated from the
  current session. Runs `/feature-plan` for the interactive story + Q&A, then
  subagents handle implementation, the review/fix loop (until no criterion has
  `Action Required` checked, capped at 3 rounds), linters, the full test suite
  with coverage top-up (≥95% on feature files), and PR creation for every repo
  involved. Does **not** invoke `/feature-done` — the user archives after the
  PRs merge. Best when the user wants a hands-off plan-to-PR flow and is happy
  to delegate review triage.

### Shared planning

`/feature-plan` is the single entry point for all flows. It produces two
artifacts:
- `story.md` — user story, discovery decisions, acceptance criteria (with
  `Implemented`/`Reviewed`/`Action Required` tracking), repos involved, and
  any open questions
- `design.md` — a living log of implementation-level design decisions
  (seeded empty by `/feature-plan`). Any flow that makes a non-obvious
  implementation choice appends an entry here so a future session can pick
  up without reverse-engineering the code. Product-level decisions stay in
  `story.md` under Discovery; `design.md` is for the *how*.

There is no separate plan file. Well-formed acceptance criteria carry the full
design intent of the feature; the implementation agent decides *how* to build them.

### Checkbox semantics

Each acceptance criterion in `story.md` has three nested checkboxes, each
owned by a different flow:

- **Implemented** — checked by `/feature-implement` or `/ralph`
  when the behavior is in the code.
- **Reviewed** — checked by the `/feature-code-review` Behavior Verification
  sub-agent per criterion it covers.
- **Action Required** — also checked by the same review sub-agent *at the
  same time as Reviewed* whenever that criterion has findings requiring a
  code change (PARTIAL/MISSING coverage, or HIGH/CRITICAL behavior drift).
  `/feature-code-fix` unchecks it once the findings for that criterion are
  resolved. `/feature-done` refuses to archive while any criterion still
  has Action Required checked.

A criterion is "truly done" only when `Implemented` and `Reviewed` are
checked and `Action Required` is unchecked.

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder
- Ralph loop files (`PROMPT.md`) also live in the feature folder

If a feature folder already exists, you may read its files to resume context across
sessions.

### Git worktrees

Features use **git worktrees** so the user can keep working on the main branch
while an agent (or another session) implements a feature in an isolated working
tree. Each worktree is a sibling directory of the original repo, visible to the
sessionizer as a separate tmux session.

#### Naming convention

Worktrees live as siblings of the original repo directory, named
`<repo>--<feature-name>`:

```
~/Developer/work/
  my-app/                       # main branch (original repo)
  my-app--user-avatar-upload/   # worktree for feature/user-avatar-upload
```

The `--` delimiter separates the repo name from the feature name. The
sessionizer picks up each worktree as a distinct fzf entry and tmux session.

#### story.md metadata

When worktrees are created, `story.md` records them:

```md
> Working directory: /Users/tobias/Developer/work/my-app--user-avatar-upload
> Worktree: true
> Worktree source: /Users/tobias/Developer/work/my-app
> Branch: feature/user-avatar-upload
```

- `> Worktree: true` signals downstream skills that the working directory is a
  worktree (skip branch creation — the worktree already has its branch).
- `> Worktree source:` is the path to the original repo (needed for cleanup).

If multiple repos have worktrees, `story.md` also contains a `## Worktrees`
table listing every worktree path, source repo, and branch. `/feature-done`
reads this table to clean up all worktrees.

#### Lifecycle

- `/feature-plan` **creates** worktrees after the plan is finalized
  (Step 8b). Worktrees are created by default for all repos involved in the
  feature. To skip worktree creation, the user must explicitly request no
  worktrees in the initial prompt.
- `/feature-implement` and `/ralph` detect `> Worktree: true` in
  `story.md` and **skip branch creation** — the worktree is already on the
  correct branch.
- `/feature-done` **cleans up** the worktree after archiving: removes the git
  worktree, deletes the directory, prunes stale worktree refs, and kills the
  associated tmux session if one exists.

#### Detection

To check if the current working directory is inside a worktree:

```sh
git rev-parse --is-inside-work-tree &>/dev/null \
  && [ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ]
```

If this returns true, the directory is a worktree (not the main repo).

#### Always-on repos: lilium, trillium, and logger

Any change to `~/Developer/personal/lilium`, `~/Developer/personal/trillium`,
or `~/Developer/personal/logger` — even a one-line bug fix outside a
`/feature-plan` flow — runs in a worktree. Never commit on `main` of those
repos directly. If a quick fix lands without a feature folder, create the
worktree manually:

```sh
cd ~/Developer/personal/<repo>
git worktree add ../<repo>--<short-name> -b <branch-name>
cd ../<repo>--<short-name>
```

`lilium` and `trillium` host the production iOS app and its backend; `logger`
is the always-on log dashboard the user runs locally. Touching them on `main`
risks pushing a half-finished change. Worktrees keep the original checkout
clean and let the user keep working on something else in parallel.

**Ad-hoc worktrees have no `/feature-done` to clean them up.** When you
open a PR from one of these manually-created worktrees, end that turn with
a reminder along the lines of *"PR is up — let me know when it's merged
and I'll delete the worktree."* That puts the cleanup on the user's radar
without nagging.

When the user later says the PR landed (or asks you to clean up),
**verify the change is on `main` before removing anything.** Trust the
GitHub PR state, not `git branch --merged` (squash merges leave the
original commits unreachable from `main` even though the PR is closed):

```sh
git -C ~/Developer/personal/<repo> fetch origin main --quiet
gh -R <owner>/<repo> pr view <branch> --json state,mergedAt
```

The PR must report `state: "MERGED"`. Also check the worktree itself:

```sh
git -C <worktree-path> status --porcelain
```

If anything is uncommitted, stop and ask — the diff is unrecoverable
once the worktree is removed. Only when the PR is MERGED *and* the
worktree is clean, run the cleanup (mirrors `/feature-done` Step 4b):

```sh
git -C ~/Developer/personal/<repo> worktree remove <worktree-path>
git -C ~/Developer/personal/<repo> branch -D <branch-name>
```

Kill the tmux session named after the worktree directory if one exists.

Then delete the Xcode caches keyed to that worktree path. Xcode hashes
the absolute workspace path into the DerivedData folder name, so the
worktree has its own folder separate from the source repo. Remove every
DerivedData folder whose `info.plist` references the worktree path:

```sh
for derived in "$HOME/Library/Developer/Xcode/DerivedData"/*/; do
  info_plist="$derived/info.plist"
  [ -f "$info_plist" ] || continue
  workspace_path=$(/usr/libexec/PlistBuddy \
    -c "Print :WorkspacePath" "$info_plist" 2>/dev/null) || continue
  case "$workspace_path" in
    "<worktree-path>"|"<worktree-path>"/*) rm -rf "$derived" ;;
  esac
done
```

Never touch the shared `ModuleCache.noindex` directory under DerivedData.
Per-worktree SwiftPM build output and `xcodebuild.nvim` caches live
inside the worktree directory and are removed with it.

### Implicit context loading

When the user mentions a feature or product by name — even without running a
skill — find and load the matching context automatically:

- **Features**: phrases like "load the gdpr consent feature", "regarding the
  gdpr feature", or "continue with gdpr consent" mean there is a folder
  matching the keyword under `~/.claude/features/` (active) or
  `~/.claude/features/done/` (archived). Glob for `~/.claude/features/*<keyword>*/`
  and read `story.md` (and `design.md` if it exists) from the best match.
- **Products**: phrases like "regarding the scomp product", "in the context of
  scomp", or "for the scomp module" mean there is a folder matching the
  keyword under `~/.claude/products/`. Glob for
  `~/.claude/products/*<keyword>*/` and read `index.md` first, then only
  the file(s) relevant to the current task.

Use fuzzy substring matching on the folder name — the user will not type the
exact folder name. If multiple folders match, prefer the closest match; if
still ambiguous, ask the user to clarify.

### Product / module context

Product and module context files live at `~/.claude/products/<product>/`. Each product
folder contains an `index.md` listing all files and when to read each one. Read
`index.md` first, then only the file(s) relevant to the current task — avoid loading
all files at once.

### Work repos

When working inside a `/work/` directory, related repositories live in
`~/Developer/work/`. Scan that directory to identify which repos are relevant to a
given task or feature.

Pre-built context files for each repo live at
`~/.claude/repo-context/<repo-name>.md`. When they exist, read them before reading
source code — they contain purpose, architecture, inter-repo dependencies, external
communication protocols, and canonical design patterns. Fall back to reading source
only when context files are missing or insufficient.

### Markdown files

When writing markdown files, make sure that lines are not longer than 140 characters
without trailing white-spaces.

### JavaScript / TypeScript style

Prefer native optional chaining (`?.`) and nullish coalescing (`??`) over lodash
helpers like `_.get`, `_.has`, and similar. Exceptions:

- If the surrounding function or file already uses lodash to read the same params
  or values, keep using lodash in the new code for consistency within that scope.
- Removing an existing lodash call in favor of optional chaining is fine only
  when it is a like-for-like replacement of the same function (e.g. `_.get(obj,
  'a.b')` → `obj?.a?.b`). Do not swap out lodash functions that have no direct
  native equivalent (e.g. `_.isEqual`, `_.cloneDeep`, `_.groupBy`).

### Naming

Never use one-letter variable names (`e`, `r`, `i`, `m`, etc.). The only exception is
the conventional loop counter inside a tight `for` body that fits on one line. Even
short-lived locals in `.map`, `.filter`, `.forEach`, `try/catch`, and arrow callbacks get
a real name (`entry`, `response`, `index`, `match`, `error`). The cost of a longer name
is one more character per occurrence; the benefit is a stack trace, log line, or grep
result that reads like prose.

### Testing style

When multiple test cases share the same setup/assertions and differ only in a
few variables (e.g. input values, expected status codes, flag states), use
parameterized tests — loop over an array of case objects — instead of
duplicating `describe`/`before`/`it` blocks. This keeps tests concise and
makes it easy to add new cases without copy-pasting scaffolding.

Never use faker (or similar random-data libraries) in tests. Use plain,
deterministic literals instead. Random values obscure intent, make failures
harder to reproduce, and add a dependency that provides no real coverage
benefit. When a test needs a UUID or similar identifier, hard-code a
realistic but fixed value (e.g. `"d7a1c3e0-4b2f-4e8a-9f6d-1a2b3c4d5e6f"`)
so it is grep-searchable across the codebase. Never generate UUIDs at
runtime in tests.

Never `Task.sleep` (or `setTimeout`, `Thread.sleep`, `time.sleep`,
`DispatchQueue.asyncAfter`, `RunLoop.run(until:)`, or any other "wait
wall-clock time" primitive) in tests — in any language. Sleep-based tests are
slow and flaky; under contention (parallel runners, shared MainActor / event
loop) the wake-up can be delayed arbitrarily. If a test seems to need a sleep,
the design is missing a seam. Make the time-dependent thing testable instead:

- **Inject a clock.** Pass a `() -> Date` / `Clock` / `Date.now`-equivalent
  function the SUT reads; in tests use a fake that returns whatever you set.
- **Expose the work the timer does as a method.** A periodic ticker should call
  a `tick()` (or `advance()`, `flush()`) method that does all the real work
  (recompute, fire side effects, dismiss when past deadline). Production wires
  the real timer → that method; tests advance the fake clock and call it
  directly. The timer plumbing becomes a thin shim, and the behavior lives in
  a deterministically-tested method.
- **Await the work itself**, not wall time. `await sut.lastTask?.value` for
  fire-and-forget Tasks; drive `AsyncStream` / `EventEmitter` continuations
  directly; `await` the promise the production code returns.
- **Inject a scheduler.** When an integration test really must cover the
  scheduling plumbing, extract a `Scheduler` protocol and inject a test
  scheduler whose `advance(by:)` synchronously fires due work — don't sleep
  longer and hope.

There is always a better way than `sleep`. If you cannot find one, the SUT
needs a refactor before the test does.
