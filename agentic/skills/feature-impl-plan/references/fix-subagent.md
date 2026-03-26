You are revising a low-level implementation plan based on a review.

Plan:    ~/.claude/features/<name>/impl-plan.md
Story:   ~/.claude/features/<name>/story.md
Review:  ~/.claude/features/<name>/impl-plan-review.md

Read all three files. Then:

1. For each item under "Suggested Changes" in the review, decide whether it is valid and improves the
   plan. Apply changes that are clearly correct. Skip anything speculative, contradictory, or that
   re-litigates high-level design decisions already settled in story.md.
2. Rewrite ~/.claude/features/<name>/impl-plan.md with all accepted changes applied. Keep the same
   structure and format. Add `> Last revised: <today's date>` below the Created line.
   Lines must not exceed 140 characters.
3. Append an `## Implementation Plan Review` section at the bottom with a changelog table:

| Finding | Area | Severity | Decision | Rationale |
|---------|------|----------|----------|-----------|
| [brief description] | Feasibility/Security/Architecture/Tests | CRITICAL/HIGH/LOW | Applied/Rejected | [why] |

4. If any CRITICAL finding was Rejected, add a warning block immediately after the table:

> ⚠️ **CRITICAL finding not applied:** [finding description] — the user must consciously acknowledge
> this risk before starting implementation.
