---
name: review-code
description: >-
  Reviews implemented code from 3 perspectives in parallel — behavior verification
  against the spec, contextual review, and pattern consistency. Use when asked to
  review code, a completed implementation, or when another skill delegates a code
  review step.
argument-hint: "[file paths or description of what was implemented]"
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Code Review Workflow

This skill can be invoked directly by the user (`/review-code`), or delegated to by
other skills (feature-code-review, bugfix).

When delegated, the calling skill may pass context via `$ARGUMENTS` — this can include
file paths, a feature folder path, or a description of what to review. The calling skill
may also have already gathered context (changed files, diffs, feature docs) — if so, use
what is available in the conversation rather than re-collecting.

## Step 1 — Gather context

Collect the following before launching agents. Skip any item that was already provided
by the calling skill or conversation context.

- **Changed files:** Run
  `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD
  2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null`
  to get files changed relative to the base branch. If `$ARGUMENTS` contains file
  paths, use those instead.
- **Full diff:** Run
  `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD
  2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) 2>/dev/null`
  to get the complete diff against the base branch.
- **Base branch:** Run
  `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
  to identify main/master/develop.
- **File contents:** Read all changed source and test files in full using the Read tool.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`, `*.csproj`,
  `Cargo.toml`, `go.mod`, or equivalent. Fall back to file extensions.
- **Project structure:** Run `git ls-files | head -80`.

**Context files (for Agents 2 and 3):**
- **Repo context:** Detect the repo name from the working directory path. Check whether
  `~/.claude/repo-context/<repo-name>.md` exists. If it does, read it in full.
- **Feature/scope docs:** If this review is for a feature, read the relevant `.md` files
  from the feature folder (story.md and any others present). If this is a bugfix,
  read the bug folder files (bug.md, investigation.md, fix.md, failing-test.md).
- **Requirements:** Extract the original task, feature description, or acceptance criteria
  from the conversation context or feature docs.

If no changed files can be identified, ask the user to specify which files to review
and stop.

Store all of this. You will inject relevant parts into each sub-agent prompt.

## Step 2 — Launch 3 sub-agents in parallel

Call the Agent tool exactly 3 times in the same response. Do NOT wait for one to
finish before launching the next. Replace placeholders with actual content from Step 1.

---

### Agent 1 — Behavior Verification (spec vs. code)

This agent verifies that the implemented code exhibits each acceptance criterion
(or, for a bugfix, the expected fix behavior). It receives the criteria/spec, the
full diff, and the code. Its job is to walk the spec one item at a time and
confirm the behavior is actually present in the code — not just that
similar-looking code exists.

```
You are verifying that implemented code matches a specification of behavior, one
item at a time.

You have:
- The acceptance criteria (or bug-fix behavior) the code is supposed to satisfy.
- The full diff and the changed files.
- The filesystem, so you can read surrounding code to confirm integration points.

For each criterion (or bug-fix expectation), determine:

1. **Present** — the code clearly exhibits the specified Given/When/Then
   behavior (or, for rule-style criteria, enforces the rule and matches the
   example). State where in the code (file:line) the behavior is realized.
2. **Partial** — some parts are implemented but not all (e.g. the happy path
   works but the error case isn't handled; the rule is enforced but the
   example outcome is wrong). Explain what's missing.
3. **Missing** — the criterion is not implemented. Explain what you looked
   for and where you expected to find it.

Also flag:
- **Behavior drift** — code that implements something close to but different
  from what the criterion specifies (wrong observable, wrong message, wrong
  trigger, wrong boundary).
- **Unclaimed behavior** — behaviors visible in the diff that no criterion
  asked for. These may be scope creep or missing criteria; flag either way.

Tests are written ad-hoc in this flow. Do NOT require test-first or any
particular test style, and the mere absence of a test on a criterion is not a
finding. Only flag a missing test if the behavior cannot be verified from the
code alone AND has a nontrivial risk of silent regression.

If no acceptance criteria or spec were provided (direct /review-code with no
feature), say so up-front and note that criterion coverage cannot be verified.
Then fall back to reviewing the diff for obvious bugs, unclear logic, missing
error handling, and anything that looks wrong — report these under "Behavior
drift" and "Unclaimed behavior" as best fits.

Keep findings concise. Reference file names and line numbers. Use severity
flags CRITICAL / HIGH / LOW.

- CRITICAL: a criterion is missing, or behavior drift produces a wrong
  observable outcome
- HIGH: a criterion is partial, or unclaimed behavior meaningfully changes
  product surface area
- LOW: minor mismatch or drift that doesn't affect observable behavior

Output format:

### Criterion coverage

One bullet per criterion, in the order they appear in the spec:
`[PRESENT|PARTIAL|MISSING] <final severity if not PRESENT> — <criterion title>
— <file:line or "not found"> — <one-line note>`

### Behavior drift

Bulleted list of drift findings with file:line and severity, or "None".

### Unclaimed behavior

Bulleted list of behaviors the diff adds that no criterion covers, or "None".

Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]
Requirements: [REQUIREMENTS]

[REPO_CONTEXT]

[FEATURE_OR_BUG_DOCS]

[CODE]
```

---

### Agent 2 — Contextual Review (full context, minimal guidelines)

This agent receives everything — the code, the diff, requirements, feature/bug docs,
repo context, and project structure. It reviews with the full picture but still with
minimal prescriptive guidelines. It should catch issues that only become apparent when
you understand what the code is supposed to do and how it fits into the larger system.

```
You are reviewing code with full context about the project and its requirements.
Review the code honestly — look for anything that concerns you, with the benefit
of understanding what this code is supposed to do and how it fits into the codebase.

You have context about the requirements, the project structure, and the repo's
architecture. Use this to catch issues that would be invisible without context:
misunderstood requirements, incomplete implementations, incorrect integration with
existing systems, missing edge cases specific to the domain, or subtle bugs that
only appear when you understand the intended behaviour.

Keep findings concise. Reference file names and line numbers. Use severity flags
CRITICAL / HIGH / LOW on each finding.

- CRITICAL: will cause incorrect behaviour, crashes, data loss, or security
  vulnerabilities — or a core requirement is not met
- HIGH: significant concern that should be addressed
- LOW: minor improvement or nit

Tech stack: [TECH_STACK]
Project structure: [PROJECT_STRUCTURE]
Base branch: [BASE_BRANCH]
Files reviewed: [FILE_PATHS]
Requirements: [REQUIREMENTS]

[REPO_CONTEXT]

[FEATURE_OR_BUG_DOCS]

[CODE]
```

---

### Agent 3 — Pattern Consistency (full context, pattern-focused)

This agent also receives full context but has a single focused mandate: verify that
the new code follows the same design patterns, coding style, and conventions as the
rest of the codebase. It has filesystem access to read existing code for comparison.

```
You are reviewing code specifically for consistency with existing codebase patterns
and coding style. You have access to the filesystem.

Your job is to ensure the new code looks like it belongs in this codebase — same
patterns, same conventions, same style. New code should be indistinguishable from
existing code in how it structures logic, handles errors, names things, and
organises files.

Steps:
1. Detect the current repo name from the working directory path.
2. Check whether a pre-built context file exists:
   `cat ~/.claude/repo-context/<repo-name>.md 2>/dev/null`. If it exists, read
   the '## Design patterns' section as your primary source of truth for canonical
   patterns.
3. Use Glob and Grep to find 2-4 existing files or features similar to what was
   implemented. Read those files to understand the established patterns.
4. Compare the new implementation against those patterns and flag deviations.
   If the context file named a canonical pattern for an area touched by the new
   code, flag any deviation as HIGH or CRITICAL.

Focus areas: naming conventions, error handling patterns, file/module organisation,
abstraction levels, test structure and conventions, API patterns, state management
patterns, and any repo-specific idioms.

Reference file names and line numbers. When flagging a deviation, cite the existing
file that demonstrates the correct pattern. Use severity flags
CRITICAL / HIGH / LOW on each finding.

- CRITICAL: breaks a canonical pattern documented in repo-context or universally
  followed in the codebase
- HIGH: deviates from a common pattern followed by most similar code
- LOW: minor style inconsistency

Tech stack: [TECH_STACK]
Project structure: [PROJECT_STRUCTURE]
Files reviewed: [FILE_PATHS]

[REPO_CONTEXT]

[FEATURE_OR_BUG_DOCS]

[CODE]
```

## Step 3 — Synthesize findings

Once all 3 agents have returned, present the results in this format:

---

## Code Review

Severity flags:
- **CRITICAL:** must fix before merging — correctness, security, or data integrity risk
- **HIGH:** significant concern — should be fixed before or shortly after merging
- **LOW:** worth addressing — code quality, minor improvements

### Behavior Verification
[Agent 1 output — keep the three sub-sections as returned: criterion coverage
(one bullet per criterion, in spec order), behavior drift, unclaimed behavior.
PARTIAL and MISSING entries and any behavior drift are the most load-bearing
findings and should stay prominent.]

### Contextual Review
[Agent 2 findings — bullet points with file:line references and severity flags]

### Pattern Consistency
[Agent 3 findings — bullet points with file:line references and severity flags,
citing existing files as examples]

### Summary
**Overall assessment:** [1-2 sentences on whether the code is ready to merge]

**Must fix before merging:**
1. [Most critical issue]
2. [Second most critical issue]
3. [Third — if applicable]

**Safe to merge as-is:** [aspects that are solid]

---

> **CRITICAL WARNING:** If any CRITICAL finding was identified, highlight it
> prominently so the user can address it before merging.
