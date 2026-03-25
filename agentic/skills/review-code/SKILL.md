---
name: review-code
description: >-
  Reviews implemented code from 4 perspectives in parallel — runtime safety, performance,
  code quality, and completeness. Use when asked to review code or a completed implementation.
argument-hint: [file paths or description of what was implemented]
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash
---

Review the implemented code. Follow these steps exactly:

**Step 1 — Gather context**
Collect the following before launching agents:

- **Changed files:** Run
  `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD
  2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null`
  to get files changed relative to the base branch. If `$ARGUMENTS` is provided,
  treat it as file paths instead.
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
- **Original requirements:** Extract the original task or feature description from
  the conversation context.

If no changed files can be identified, ask the user to specify which files to review
and stop.

Store all of this. You will inject it into each sub-agent prompt.

**Step 2 — Launch 4 sub-agents in parallel**
Call the Agent tool exactly 4 times in the same response. Do NOT wait for one to
finish before launching the next. Replace placeholders with actual content from Step 1.

Agent 1 — Runtime Safety (correctness + security):
"Review the following code for runtime correctness and security. Focus on:

Correctness: logic errors, off-by-one errors, incorrect assumptions, missing
null/undefined checks, wrong return values, broken control flow, misuse of APIs
or libraries, anything that will produce wrong results at runtime.

Security: injection risks (SQL, XSS, command injection), broken authentication or
authorization, sensitive data in logs or responses, hardcoded secrets, insecure
deserialization, missing input validation, OWASP Top 10 issues.

Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Base branch: [BASE_BRANCH]
Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 2 — Performance & Scalability:
"Review the following code for performance and scalability issues. Focus on: N+1
query patterns, missing database indexes, synchronous operations that should be
async, unnecessary loops or recomputation, memory leaks, large payloads loaded
into memory, missing pagination, and anything that will degrade under load.
Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 3 — Code Quality (maintainability + design patterns):
"Review the following code for maintainability and design pattern consistency.

Maintainability: functions or classes doing too much, duplicated logic, misleading
names, missing or misleading comments on non-obvious logic, magic numbers or
strings, deeply nested code, tight coupling between modules, anything that will
make this code hard to change or understand later.

Design pattern consistency: You have access to the filesystem.
1. Detect the current repo name from the working directory path.
2. Check whether a pre-built context file exists:
   `cat ~/.claude/repo-context/<repo-name>.md 2>/dev/null`. If it exists, read
   the '## Design patterns' section — use this as your primary source of truth
   for what patterns new code should follow.
3. Use Glob and Grep to find 2-4 existing features similar to what was
   implemented. Read those files to confirm patterns.
4. Compare the new implementation against those patterns and flag deviations.
   If the context file named a canonical pattern for an area touched by the new
   code, flag any deviation as HIGH or CRITICAL.

Reference file names and line numbers where possible. Use severity flags
CRITICAL / HIGH / LOW on each finding.

Tech stack: [TECH_STACK]
Project structure: [PROJECT_STRUCTURE]
Files reviewed: [FILE_PATHS]

[CODE]"

Agent 4 — Completeness (acceptance criteria + test quality):
"Review the following implementation for completeness against requirements and
test quality. You have access to the filesystem.

Part A — Acceptance Criteria:
Original requirements:
[REQUIREMENTS]

For each requirement or acceptance criterion:
1. Determine whether the implementation covers it — fully, partially, or not at all.
2. If partially or not covered, describe specifically what is missing.
3. Check the changed files and, if needed, adjacent files to confirm the behavior
   is actually wired up end-to-end (not just partially implemented).

Part B — Test Quality:
1. Missing edge cases — inputs or states not covered: boundary values, empty/null
   inputs, error states, concurrent access, large inputs, invalid types, etc.
2. Poorly implemented tests — tests that give false confidence: tests that never
   fail, assertions too loose, tests that test implementation details instead of
   behavior, missing assertions, tests that depend on each other or execution
   order, brittle tests.
3. Missing main flow coverage — any critical happy path with no test.

For each issue, reference specific files, line numbers, and test names. Use
severity flags CRITICAL / HIGH / LOW. CRITICAL means a core requirement is missing
or a critical happy path has no test.

Base branch: [BASE_BRANCH]
Tech stack: [TECH_STACK]
Files reviewed: [FILE_PATHS]

[CODE]"

**Step 3 — Synthesize findings**
After all 4 agents return their results, present everything in this format:

---

## Code Review

Severity flags:
- **CRITICAL:** must fix before merging — correctness, security, or data integrity risk
- **HIGH:** significant concern — should be fixed before or shortly after merging
- **LOW:** worth addressing — code quality, minor improvements

### Runtime Safety
[Agent 1 findings — bullet points with file:line references and severity flags]

### Performance & Scalability
[Agent 2 findings — bullet points with file:line references and severity flags]

### Code Quality
[Agent 3 findings — bullet points with file:line references and severity flags]

### Completeness
#### Acceptance Criteria
[Agent 4 Part A — each requirement: Fully / Partially / Not covered, with explanation]

#### Test Quality
[Agent 4 Part B — bullet points with severity flags, referencing test names and files]

### Summary
**Overall assessment:** [1-2 sentences on whether the code is ready to merge]

**Must fix before merging:**
1. [Most critical issue]
2. [Second most critical issue]
3. [Third — if applicable]

**Safe to merge as-is:** [aspects that are solid]

---

**Step 4 — Apply fixes**
Go through every finding from all 4 agents and for each one:

- **Apply it** — fix the code using the Edit tool, OR write the missing test
- **Reject it** — leave unchanged, but provide an explicit argument for why

After applying all changes:

1. **Run tests** — run the repo's test suite to verify fixes haven't introduced
   regressions. If the test command is expected to take longer than 2 minutes,
   ask the user before running.

2. Present the changelog:

## Changelog

| Finding | Decision | Rationale |
|---|---|---|
| [brief description] | Applied / Rejected | [why] |

---

> **CRITICAL WARNING:** If any CRITICAL finding was **Rejected** in the changelog
> above, highlight it here explicitly. The user must consciously acknowledge they
> are accepting a known critical risk before this work is considered done.
