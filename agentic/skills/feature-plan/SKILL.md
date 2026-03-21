---
name: feature-plan
description: Create a new feature plan. Use when the user runs /feature-plan followed by a feature description. Drafts a user story for approval, then creates the feature folder and files under ~/.claude/features/.
argument-hint: <feature description>
---

# Feature Plan Workflow

The user has invoked `/feature-plan` with a feature description. Follow this workflow exactly.

## Step 1 — Draft the story

From the user's description, draft:
- A **short folder name** (kebab-case, 2–4 words, e.g. `user-avatar-upload`)
- A **user story** in this format:

  **As a** [user type], **I want** [goal] **so that** [reason]

Present both to the user and ask for approval. Do not proceed until they confirm or request changes.

## Step 2 — Create the story file

Once approved, create the directory and file (the `~/.claude/features/` directory may not exist yet — create it if needed):

```
~/.claude/features/<short-name>/story.md
```

Contents of `story.md`:

```md
# <Short descriptive title>

**As a** [user type], **I want** [goal] **so that** [reason]

## Notes

- Created: <today's date>
```

## Step 3a — Spawn planning subagent

Spawn a **foreground** subagent (`subagent_type: general-purpose`) and **wait for it to finish** before continuing. Replace `<short-name>` with the actual folder name.

```
You are creating a high-level plan for a user story.

Story file: ~/.claude/features/<short-name>/story.md

Read that file to understand the goal.

## Repo detection

Always start by identifying the current repo from the working directory name.

If the current working directory contains /work/, list all directories in ~/Developer/work/. Then:

1. Check which repos have a pre-built context file: `ls ~/.claude/repo-context/ 2>/dev/null`
2. For repos **with** a context file, read `~/.claude/repo-context/<repo-name>.md` — this contains purpose, architecture, dependencies, design patterns, and inter-repo relationships. Do not re-read the source for these repos unless the context file says "Unknown" for something critical to the story.
3. For repos **without** a context file, read enough code to understand what it does — start with README.md, package.json, go.mod, Podfile, or equivalent manifest files.

Based on the story goal and what you find, identify which repos will need changes. Prefer repos listed under "Internal repo dependencies" in context files of the current repo when tracing the call chain.

If not in a /work/ context, the affected repo is the current one — still include it in the **Repos involved** section below.

## Plan

Write a plan.md file to ~/.claude/features/<short-name>/plan.md with:

- **Summary** — what needs to be built
- **Design decisions** — key architectural choices
- **Implementation phases** — ordered steps
- **Repos involved** — every repo that will need changes, each with a short reason why. Always includes at least the current repo.

Keep it concise. Do not implement anything.
```

## Step 3b — Spawn review subagents in parallel

After the planning subagent has finished and `plan.md` exists, spawn **3 subagents in the same response** (`subagent_type: general-purpose`) and **wait for all 3 to finish** before continuing. These review the high-level plan — not implementation details.

---

**Reviewer 1 — Story coverage:**

```
You are reviewing a high-level feature plan against its user story.

Story: ~/.claude/features/<short-name>/story.md
Plan:  ~/.claude/features/<short-name>/plan.md

Read both files. Assess:
1. Does the plan fully address the user's goal as stated in the story?
2. Are there missing cases, overlooked user needs, or gaps between what the story asks for and what the plan proposes to build?
3. Is the scope appropriate — neither too narrow (misses the goal) nor too broad (solves more than asked)?

Output your findings as a structured list with a **Verdict** (Approved / Needs changes) at the top, followed by specific gaps or suggestions. Be concise — this is a high-level plan, not an implementation.
```

---

**Reviewer 2 — Repo and dependency coverage** (run unconditionally — if not in a /work/ context, the reviewer will note that and return "N/A"):

```
You are reviewing whether a feature plan covers the right set of repositories and dependencies.

Story: ~/.claude/features/<short-name>/story.md
Plan:  ~/.claude/features/<short-name>/plan.md

Read both files. Then:
1. Check if the current working directory contains /work/. If not, output "Not a /work/ context — no repo review needed" and stop.
2. If in /work/: list all directories in ~/Developer/work/. For each, check whether a context file exists at ~/.claude/repo-context/<repo-name>.md and read it if so.
3. Based on what each repo does and what the story requires, assess:
   - Are all necessary repos listed in the plan?
   - Are any listed repos unnecessary for this story?
   - Are inter-repo dependencies (API contracts, shared types, event flows) correctly identified?

Output your findings as a structured list with a **Verdict** (Approved / Needs changes) at the top.
```

---

**Reviewer 3 — Architectural soundness:**

```
You are reviewing the architectural and design decisions in a high-level feature plan.

Story: ~/.claude/features/<short-name>/story.md
Plan:  ~/.claude/features/<short-name>/plan.md

Read both files. Assess:
1. Are the proposed design decisions sound for the problem? Are there simpler or more robust approaches that should be considered?
2. Do the implementation phases make sense in order? Are there missing phases or phases that could be combined?
3. Are there any obvious architectural risks — tight coupling, wrong layer of abstraction, approaches that will be hard to test or extend?

Output your findings as a structured list with a **Verdict** (Approved / Needs changes) at the top. Focus on high-level design — do not critique implementation details that haven't been decided yet.
```

---

## Step 3c — Collect review findings

After all 3 reviewers return, synthesize their findings and write to `~/.claude/features/<short-name>/plan-review.md`:

```md
# Plan Review

> Reviewed: <today's date>

## Story Coverage
[Reviewer 1 verdict and findings]

## Repo & Dependency Coverage
[Reviewer 2 verdict and findings, or "N/A — not a /work/ context"]

## Architectural Soundness
[Reviewer 3 verdict and findings]

## Suggested Changes
[Consolidated, deduplicated list of actionable changes recommended across all reviewers]
```

## Step 3d — Spawn fix subagent

Spawn a **foreground** subagent and **wait for it to finish** before continuing.

```
You are revising a high-level feature plan based on a review.

Story:  ~/.claude/features/<short-name>/story.md
Plan:   ~/.claude/features/<short-name>/plan.md
Review: ~/.claude/features/<short-name>/plan-review.md

Read all three files. Then:

1. For each item under "Suggested Changes" in the review, decide whether it is clearly correct and improves the plan. Apply only the changes you agree with — skip anything speculative, stylistic, or that contradicts the story goal.
2. Rewrite ~/.claude/features/<short-name>/plan.md with the agreed fixes applied. Keep the same structure; only change what needs changing.
3. Append a ## Revisions section at the bottom of plan.md listing each change you made and why, and each suggestion you skipped and why.
```

## Step 4 — Confirm

Tell the user the feature plan is finished. Show the feature folder path and give a one-line summary of what was planned.

Then prompt: _"Run `/feature-impl-plan` to break this into tasks and build an implementation plan."_

## Rules

- Never skip the approval step — the user must confirm before any file is written
- Use kebab-case for folder names, lowercase only
- Active features live directly in `~/.claude/features/`
- Completed features are moved to `~/.claude/features/done/<short-name>/`
- All related md files for a feature go in that feature's folder
