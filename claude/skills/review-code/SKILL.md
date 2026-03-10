---
name: review-code
description: Reviews implemented code from 7 perspectives in parallel — correctness, security, performance & scalability, maintainability & architecture, test quality, acceptance criteria, and design pattern consistency. Use when asked to review code or a completed implementation.
argument-hint: [file paths or description of what was implemented]
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash
---

Review the implemented code. Follow these steps exactly:

**Step 1 — Gather context**
Collect the following before launching agents:

- **Changed files:** Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) --name-only 2>/dev/null` to get files changed relative to the base branch. If `$ARGUMENTS` is provided, treat it as file paths instead.
- **Full diff:** Run `git diff $(git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') 2>/dev/null) 2>/dev/null` to get the complete diff against the base branch.
- **Base branch:** Run `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` to identify main/master/develop.
- **File contents:** Read all changed source and test files in full using the Read tool.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`, `*.csproj`, `Cargo.toml`, `go.mod`, or equivalent. Fall back to file extensions.
- **Project structure:** Run `git ls-files | head -80`.
- **Original requirements:** Extract the original task or feature description from the conversation context.

If no changed files can be identified, ask the user to specify which files to review and stop.

Store all of this. You will inject it into each sub-agent prompt.

**Step 2 — Launch 7 sub-agents in parallel**
Call the Agent tool exactly 7 times in the same response. Do NOT wait for one to finish before launching the next. Replace placeholders with actual content from Step 1.

Agent 1 — Correctness:
"Review the following code for correctness. Focus on: logic errors, off-by-one errors, incorrect assumptions, missing null/undefined checks, wrong return values, broken control flow, misuse of APIs or libraries, and anything that will produce wrong results at runtime. Reference file names and line numbers where possible. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nBase branch: [BASE_BRANCH]\nTech stack: [TECH_STACK]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 2 — Security:
"Review the following code for security vulnerabilities. Focus on: injection risks (SQL, XSS, command injection), broken authentication or authorization, sensitive data in logs or responses, hardcoded secrets, insecure deserialization, missing input validation, and any OWASP Top 10 issues present in the actual implementation. Reference file names and line numbers where possible. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 3 — Performance & Scalability:
"Review the following code for performance and scalability issues. Focus on: N+1 query patterns, missing database indexes, synchronous operations that should be async, unnecessary loops or recomputation, memory leaks, large payloads loaded into memory, missing pagination, and anything that will degrade under load. Reference file names and line numbers where possible. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 4 — Maintainability & Architecture:
"Review the following code for maintainability and architectural quality. Focus on: functions or classes doing too much, duplicated logic, misleading names, missing or misleading comments on non-obvious logic, magic numbers or strings, deeply nested code, tight coupling between modules, and anything that will make this code hard to change or understand later. Reference file names and line numbers where possible. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\nProject structure: [PROJECT_STRUCTURE]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 5 — Test Quality:
"Review the following test code for completeness and quality. Identify:\n\n1. **Missing edge cases** — inputs or states not covered but should be: boundary values, empty/null inputs, error states, concurrent access, large inputs, invalid types, etc.\n2. **Poorly implemented tests** — tests that give false confidence: tests that never fail, assertions that are too loose, tests that test implementation details instead of behavior, missing assertions, tests that depend on each other or on execution order, brittle tests.\n3. **Missing main flow coverage** — any critical happy path with no test.\n\nFor each issue, reference the specific test file and test name. Use severity flags CRITICAL / HIGH / LOW.\n\nTech stack: [TECH_STACK]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 6 — Acceptance Criteria:
"You are verifying whether the following implementation satisfies the original requirements. You have access to the filesystem.\n\nOriginal requirements:\n[REQUIREMENTS]\n\nFor each requirement or acceptance criterion:\n1. Determine whether the implementation covers it — fully, partially, or not at all.\n2. If partially or not covered, describe specifically what is missing.\n3. Check the changed files and, if needed, adjacent files to confirm the behavior is actually wired up end-to-end (not just partially implemented).\n\nUse severity flags CRITICAL / HIGH / LOW. CRITICAL means a core requirement is missing from the implementation entirely.\n\nBase branch: [BASE_BRANCH]\nFiles reviewed: [FILE_PATHS]\n\n[CODE]"

Agent 7 — Design Pattern Consistency:
"You are reviewing whether the following implementation aligns with the established design patterns in this codebase. You have access to the filesystem.\n\n1. Detect the current repo name from the working directory path.\n2. Check whether a pre-built context file exists: `cat ~/.claude/repo-context/<repo-name>.md 2>/dev/null`. If it exists, read the '## Design patterns' section — it lists canonical patterns per area and resolves any conflicts between old and new approaches. Use this as your primary source of truth for what patterns new code should follow.\n3. Read the project structure to identify where similar features live.\n4. Use Glob and Grep to find 2-4 existing features that are similar in nature to what was implemented.\n5. Read those files to confirm the patterns match what the context file describes (or to discover patterns if no context file exists).\n6. Compare the new implementation against those patterns and flag any deviations. If the context file named a canonical pattern for an area touched by the new code, flag any deviation from that canonical pattern as HIGH or CRITICAL.\n\nUse severity flags CRITICAL / HIGH / LOW. CRITICAL means the deviation would make this feature feel foreign to the codebase and create long-term inconsistency.\n\nBase branch: [BASE_BRANCH]\nTech stack: [TECH_STACK]\nProject structure: [PROJECT_STRUCTURE]\nNew files reviewed: [FILE_PATHS]\n\n[CODE]"

**Step 3 — Synthesize findings**
After all 7 agents return their results, present everything in this format:

---

## Code Review

Severity flags:
- **CRITICAL:** must fix before merging — correctness, security, or data integrity risk
- **HIGH:** significant concern — should be fixed before or shortly after merging
- **LOW:** worth addressing — code quality, minor improvements

### Correctness
[Agent 1 findings — bullet points with file:line references and severity flags]

### Security
[Agent 2 findings — bullet points with file:line references and severity flags]

### Performance & Scalability
[Agent 3 findings — bullet points with file:line references and severity flags]

### Maintainability & Architecture
[Agent 4 findings — bullet points with file:line references and severity flags]

### Test Quality
#### Missing Edge Cases
[Agent 5 missing edge case findings — bullet points with severity flags]

#### Poorly Implemented Tests
[Agent 5 poor test findings — bullet points referencing test name and file]

#### Missing Main Flow Coverage
[Agent 5 coverage gaps — bullet points]

### Acceptance Criteria
[Agent 6 findings — each requirement listed with: Fully covered / Partially covered / Not covered, and explanation]

### Design Pattern Consistency
[Agent 7 findings — bullet points with severity flags, referencing specific existing files as examples of the expected pattern]

### Summary
**Overall assessment:** [1-2 sentences on whether the code is ready to merge]

**Must fix before merging:**
1. [Most critical issue]
2. [Second most critical issue]
3. [Third — if applicable]

**Safe to merge as-is:** [aspects that are solid]

---

**Step 4 — Apply fixes**
Go through every finding from all 7 agents and for each one:

- **Apply it** — fix the code using the Edit tool, OR write the missing test
- **Reject it** — leave unchanged, but provide an explicit argument for why

After applying all changes:

1. **Re-review each CRITICAL fix** — for every CRITICAL finding that was applied, spawn a single follow-up agent to verify the fix is correct and hasn't introduced a new problem.

2. **Write missing tests** — for every missing test identified by Agent 5 (edge cases and main flow gaps) that was accepted, write the actual test code now.

3. Present the changelog:

## Changelog

| Finding | Decision | Rationale |
|---|---|---|
| [brief description] | Applied / Rejected | [why] |

---

> **CRITICAL WARNING:** If any CRITICAL finding was **Rejected** in the changelog above, highlight it here explicitly. The user must consciously acknowledge they are accepting a known critical risk before this work is considered done.
