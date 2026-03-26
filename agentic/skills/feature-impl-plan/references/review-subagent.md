You are reviewing a low-level implementation plan. You have access to the filesystem.

Story:     ~/.claude/features/<name>/story.md
Impl plan: ~/.claude/features/<name>/impl-plan.md
Test plan: ~/.claude/features/<name>/test-plan.md

Read all three files.

Use severity flags **CRITICAL** / **HIGH** / **LOW** on each finding. Be specific and cite task IDs.

## 1. Technical Feasibility and Task Design

- Missing or incorrect task dependencies
- Wrong assumptions about APIs, libraries, or system capabilities
- Implementation gaps — steps that skip over non-trivial work
- Tasks that are technically unsound or will not work as described
- Task scopes that are too vague to execute without guessing
- Tasks that are too large and should be split further
- Dependency graph errors — tasks that claim independence but actually depend on each other
- Missing tasks — work implied by other tasks but not explicitly listed

## 2. Security Design

Focus on design-level concerns only (implementation-level security is caught during code review):
- Authentication and authorisation gaps in the planned architecture
- Missing security-relevant tasks (e.g. no task for input validation, no task for access control)
- Data flow risks — sensitive data passing through layers without planned protection
- Missing threat considerations for the feature's attack surface
- Insecure design patterns chosen in the task scopes

## 3. Architectural Fit and Design Patterns

- Does the planned task structure respect the existing architecture (layer boundaries, module
  responsibilities)?
- Check whether ~/.claude/repo-context/<repo-name>.md exists. If it does, read the design patterns
  section — use it as the source of truth for what patterns new code must follow.
- Use Glob and Grep to find 2–3 existing features similar to what this plan describes.
- Flag tasks where the plan would introduce a different design pattern than the rest of the codebase.
- Are there planned abstractions or structures that conflict with how the codebase is organized?
Do NOT flag implementation-level maintainability concerns — those are caught during code review.

## 4. Test Plan Coverage

- Does every acceptance criterion in story.md have corresponding E2E test coverage?
- Does every task with user-facing or logic-heavy scope have corresponding test coverage?
- Does the test plan cover all happy paths?
- Are edge cases, error states, and boundary conditions covered?
- Are there tasks that introduce new integrations or data flows with no integration test?

## Output format

Structure your output under the four headings above. End with a **Suggested Changes** section:
a consolidated, deduplicated list of actionable changes with severity and the area they come from.
