---
name: review-plan
description: Reviews an implementation plan from 6 perspectives in parallel — technical feasibility, security, performance & scalability, maintainability & architecture, test coverage, and design pattern consistency. Use when asked to review a plan.
argument-hint: [implementation plan]
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash
---

Review the following implementation plan. Follow these steps exactly:

**Step 1 — Gather context**
Collect the following before launching agents:

- **The plan:** Use `$ARGUMENTS` if provided, otherwise extract the most recent implementation plan from conversation. If none found, ask the user and stop.
- **Tech stack:** Read `package.json`, `pyproject.toml`, `build.gradle`, `*.csproj`, `Cargo.toml`, `go.mod`, or equivalent to identify language, framework, and key dependencies. Fall back to scanning file extensions if no manifest found.
- **Base branch:** Run `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` to detect whether the project uses main, master, develop, or another base branch.
- **Project structure:** Run `git ls-files | head -80` to get an overview of the codebase layout.

Store all of this. You will inject it into each sub-agent prompt.

**Step 2 — Launch 6 sub-agents in parallel**
Call the Agent tool exactly 6 times in the same response. Do NOT wait for one to finish before launching the next. Replace placeholders with actual content from Step 1.

Agent 1 — Technical Feasibility:
"Review the following implementation plan for technical correctness and feasibility. Focus on: missing or incorrect dependencies, wrong assumptions about APIs/libraries, implementation gaps, steps that are technically unsound or unrealistic, and anything that simply won't work as described. Be specific and cite the relevant parts of the plan. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\nProject structure overview:\n[PROJECT_STRUCTURE]\n\nPlan:\n[PLAN]"

Agent 2 — Security:
"Review the following implementation plan for security risks. Focus on: authentication and authorization gaps, input validation and injection risks (SQL, XSS, command injection, etc.), sensitive data exposure, insecure defaults, missing rate limiting or abuse vectors, and anything that introduces a security vulnerability. Be specific and cite the relevant parts of the plan. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\n\nPlan:\n[PLAN]"

Agent 3 — Performance & Scalability:
"Review the following implementation plan for performance and scalability concerns. Focus on: algorithmic inefficiencies (O(n²) etc.), N+1 query patterns, missing indexes or caching, blocking operations that should be async, resource leaks, and steps that will break under load. Be specific and cite the relevant parts of the plan. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\n\nPlan:\n[PLAN]"

Agent 4 — Maintainability & Architecture:
"Review the following implementation plan for maintainability and architectural quality. Focus on: violations of separation of concerns, tight coupling, poor testability, missing abstractions or over-engineering, naming and code organization issues, and anything that will make the codebase hard to change later. Be specific and cite the relevant parts of the plan. Use severity flags CRITICAL / HIGH / LOW on each finding.\n\nTech stack: [TECH_STACK]\nProject structure overview:\n[PROJECT_STRUCTURE]\n\nPlan:\n[PLAN]"

Agent 5 — Test Coverage:
"Analyze the following implementation plan and produce a comprehensive test plan. Identify what tests are needed to cover both the main flow and edge cases. Structure your output as two sections:\n\n1. **Main Flow Tests** — the happy path scenarios that must work for the feature to be considered complete. For each test, describe: what it tests, the input/setup, and the expected outcome.\n\n2. **Edge Case Tests** — boundary conditions, error states, unexpected inputs, concurrency issues, and failure modes. For each test, describe: what edge case it covers, why it matters, and how to trigger it.\n\nBe specific and tie each test back to the relevant part of the plan.\n\nTech stack: [TECH_STACK]\n\nPlan:\n[PLAN]"

Agent 6 — Design Pattern Consistency:
"You are reviewing whether an implementation plan aligns with the established design patterns in this codebase. You have access to the filesystem.\n\n1. Read the project structure overview to identify where similar features live.\n2. Use Glob and Grep to find 2-4 existing features that are similar in nature to what the plan describes.\n3. Read those files to understand how they are structured: naming conventions, how layers are separated, how errors are handled, how data flows, how dependencies are injected, etc.\n4. Compare the plan against those patterns and flag any deviations — places where the plan would introduce a different design pattern than what the rest of the codebase uses.\n\nUse severity flags CRITICAL / HIGH / LOW. CRITICAL means the deviation would make this feature feel foreign to the rest of the codebase and create long-term inconsistency. LOW means a minor style difference.\n\nBase branch: [BASE_BRANCH]\nTech stack: [TECH_STACK]\nProject structure overview:\n[PROJECT_STRUCTURE]\n\nPlan:\n[PLAN]"

**Step 3 — Synthesize findings**
After all 6 agents return their results, present everything in this format:

---

## Plan Review

Severity flags:
- **CRITICAL:** must fix before implementation — blocks success or causes serious harm
- **HIGH:** significant concern — should be addressed before or early in implementation
- **LOW:** worth noting — can be addressed later or is a minor improvement

### Technical Feasibility
[Agent 1 findings — bullet points with severity flags]

### Security
[Agent 2 findings — bullet points with severity flags]

### Performance & Scalability
[Agent 3 findings — bullet points with severity flags]

### Maintainability & Architecture
[Agent 4 findings — bullet points with severity flags]

### Test Coverage
#### Main Flow Tests
[Agent 5 main flow tests — numbered list with description, setup, and expected outcome]

#### Edge Cases
[Agent 5 edge case tests — numbered list with description, why it matters, how to trigger it]

### Design Pattern Consistency
[Agent 6 findings — bullet points with severity flags, referencing specific existing files as examples]

### Summary
**Overall assessment:** [1-2 sentences on whether the plan is ready to implement]

**Top concerns to address before starting:**
1. [Most critical issue]
2. [Second most critical issue]
3. [Third — if applicable]

**Safe to proceed with:** [aspects that are solid]

---

**Step 4 — Update the plan**
Go through every finding from all 6 agents and decide for each one:

- **Apply it** — incorporate the fix or addition into the updated plan
- **Reject it** — leave the plan unchanged, but provide an explicit argument for why

Present the updated plan in full, followed by a changelog:

## Updated Plan

[Full updated plan text with all accepted changes incorporated]

## Changelog

| Finding | Decision | Rationale |
|---|---|---|
| [brief description] | Applied / Rejected | [why] |

---

> **CRITICAL WARNING:** If any CRITICAL finding was **Rejected** in the changelog above, highlight it here explicitly before the user proceeds to implementation. The user must consciously acknowledge they are accepting a known critical risk.
