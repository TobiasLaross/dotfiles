---
name: code-commenter
description: Adds, reviews, or improves code comments so they explain intent and rationale rather than restating mechanics. **PROACTIVELY invoke in either of these cases: (1) you are about to write, modify, or extend a comment in any source file — including inline comments added during feature work or bug fixes; (2) you are modifying code that has a comment within a few lines above, below, or attached to it (doc comment, inline note, TODO, invariant, workaround marker) — because the edit may invalidate, contradict, or outdate that comment.** Also invoke whenever the user asks to comment code, review comments, or clean up noisy comments. Run it BEFORE committing any change that touches comments OR code adjacent to comments.
argument-hint: [file path or scope]
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Edit
---

# Code Commenter

## Two invocation modes

This skill runs in one of two modes — figure out which one you are in before doing anything else:

- **Comment-focused mode** — the user asked you to write, review, or clean up comments, or you are about to add
  a new comment as part of your own work. In this mode, follow the *Hard constraints* below: touch comments
  only, never code.
- **Code-edit mode** — you are mid-edit on source code and a comment lives within a few lines above, below, or
  attached to the lines you are changing (doc comment on the enclosing symbol, inline `//` note next to the
  expression, TODO/FIXME/HACK marker, invariant/precondition note, workaround/upstream-bug reference). In this
  mode, finish your code edit as planned, but **before moving on, check every nearby comment against the new
  code** and update or delete any that are now wrong, misleading, or stale. Use the same quality bar as
  comment-focused mode (see *When a comment IS warranted* and *Anti-patterns to remove*). The code edit is not
  done until adjacent comments still tell the truth.

## Hard constraints (comment-focused mode)

- **Only touch comments.** Never modify, refactor, rename, or reformat source code — not even obvious bugs, dead
  code, or style violations. Your sole output is comment changes. If you spot a real bug, mention it in your final
  message to the user but do not edit the code.
- **Preserve existing useful comments.** Only rewrite a comment if it is wrong, misleading, or pure restatement of
  the code. Do not churn comments for style.
- **Match the language's doc convention.** Use the idiomatic doc-comment style for the file's language (e.g.
  `///` for Swift/Rust, `/** */` for TS/Java, `//` starting with the symbol name for Go, docstrings for Python).
  Do not mix styles within a file.

## Default: write nothing

If the code is clear, a comment is noise. Add a comment only when a future engineer would otherwise be confused,
make a wrong assumption, or undo the code thinking it was a mistake. Prefer renaming a variable mentally over
explaining a bad name — but since you cannot edit code, leave it alone if a comment cannot fix it.

## When a comment IS warranted

1. **Non-obvious decisions and rejected alternatives.** Explain *why* a tricky approach was chosen, or *why* a
   simpler-looking one was avoided. Never describe *what* the code does — the code does that.
2. **External context that cannot be inferred from the code.** Link to issues, RFCs, specs, vendor bug reports,
   or upstream tickets (e.g. `// Workaround for upstream issue #12345 — server returns 200 with an error body`).
3. **Invariants and preconditions.** State assumptions the code relies on but does not enforce (e.g. "caller
   holds the write lock", "input is already sorted ascending", "must run on the main thread").
4. **Performance or correctness traps.** Warn future editors away from "obvious" simplifications that would
   break things ("Do not switch to `Set` — order matters for the diff below").
5. **Public API documentation.** Document every exported / public symbol with its contract: parameters, return
   values, errors thrown, side effects, and thread-safety expectations. Skip doc comments on private symbols
   unless the logic is genuinely subtle.
6. **TODO / FIXME / HACK markers.** Include a name or ticket and a concrete trigger for removal — never a bare
   `TODO: fix later`.

## Anti-patterns to remove

When reviewing existing comments, delete or rewrite:

- **Restatement.** `// increment i` above `i++`.
- **Stale comments.** Comments that contradict the code — the code is the source of truth, so delete the comment
  (do not "fix" the code to match).
- **Section banners** like `// ===== HELPERS =====` unless the file convention already uses them consistently.
- **Commented-out code.** Delete it; version control remembers.
- **Author / date stamps** (`// Written by X on 2019-04-01`) — git blame handles this.
- **Vague hand-waves** like `// magic` or `// don't touch` with no reason.

## Workflow — comment-focused mode

1. Read the target file(s) and identify each comment plus each public symbol without one.
2. For each existing comment, classify it: keep, rewrite, or delete (per the rules above).
3. For each undocumented public symbol, decide whether a doc comment adds value; if so, write one focused on
   contract, not implementation.
4. Apply edits. Keep diffs minimal — do not reflow surrounding code.
5. After writing comments, **invoke the `humanizer` skill** on the new/changed comments to strip AI writing tics
   and make them sound like a human wrote them.
6. Report a short summary: how many comments added, rewritten, and deleted, plus any code issues you noticed
   but deliberately left alone.

## Workflow — code-edit mode

You arrive here in the middle of a code change, not a comment task. Do not redirect the work — finish the code
edit. Then, before declaring the change done:

1. **Scan the comment neighborhood.** For each region you modified, look at the doc comment on the enclosing
   symbol and any inline comments within ~5 lines above or below the changed lines. Also check comments
   attached to the changed expression itself (trailing `// ...`, surrounding block comments).
2. **Compare each comment to the new code.** Ask: does this comment still describe what the code does? Are its
   invariants and preconditions still true? Does it still point at the right line, variable, or branch? Does
   the TODO/FIXME marker still apply, or did you just fix the thing it warned about?
3. **Update or delete stale comments.** Apply the same rules as comment-focused mode (see *Anti-patterns to
   remove* and *When a comment IS warranted*). If a comment now contradicts the code, the comment is wrong —
   fix it or delete it; do not "fix" the code to match the old comment. If a TODO was resolved by your edit,
   delete it (or its tracking reference). If the comment is still accurate, leave it alone.
4. **Run `humanizer` on any comments you added or rewrote** so they don't sound generated.
5. In your final message, briefly note any nearby comments you touched as part of the code change, and flag any
   comment you deliberately left alone because it is still accurate even though it looks adjacent to the
   diff.
