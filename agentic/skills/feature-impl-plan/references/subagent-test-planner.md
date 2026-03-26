You are writing a detailed, low-level test plan for a feature implementation.

Note: you are running in parallel with the task breakdown subagent, so impl-tasks.md does not exist
yet. Write tests at the feature/component level. The reviewer will cross-reference coverage against
the final task list.

Feature folder: ~/.claude/features/<name>/

Read the following files to understand the goal and approach:
- ~/.claude/features/<name>/story.md  (includes user story and acceptance criteria)
- ~/.claude/features/<name>/plan.md   (includes design decisions and phases)

## Context gathering

1. Detect the tech stack: read package.json, pyproject.toml, build.gradle, *.csproj, Cargo.toml,
   go.mod, or equivalent. Fall back to scanning file extensions.
2. Get the project structure: run `git ls-files | head -100`
3. Look for existing test files to understand the project's testing conventions (location, naming,
   patterns, mock style).
4. Check ~/.claude/repo-context/<repo-name>.md for each relevant repo and read the testing conventions
   section if present.

## Acceptance criteria coverage

Read the "## Acceptance Criteria" section from story.md. Every criterion must be covered by at least
one E2E/acceptance test. List each criterion as a row in the coverage table at the end of the output.

## Test plan

Produce a comprehensive test plan covering all layers. Structure your output in three sections:

### Unit Tests
For each unit test:
- **What it tests**: specific function, method, or component
- **Setup / input**: the initial state or inputs required
- **Expected outcome**: what must be true after the test runs
- **Why it matters**: what bug or regression it catches

### Integration Tests
For each integration test:
- **What it tests**: the interaction between two or more components or layers
- **Setup**: data seeding, stubs, or environment required
- **Steps**: the actions to perform
- **Expected outcome**: what the system state must be
- **Why it matters**: what failure mode it catches

### End-to-End / Acceptance Tests
For each E2E test:
- **Scenario**: the user action being tested
- **Steps**: exact sequence of actions
- **Expected outcome**: what the user sees or the system produces
- **Acceptance criterion covered**: the specific criterion from story.md this validates

Include edge cases: empty states, validation errors, concurrent access, permission boundaries.
Do not skip a layer unless the tech stack genuinely has no equivalent.

End with an **Acceptance Criteria Coverage** table:
| Criterion | Test(s) |
|-----------|---------|

## Output

Write the full test plan to ~/.claude/features/<name>/test-plan.md
Lines must not exceed 140 characters (keeps files readable in editors and diff views).
