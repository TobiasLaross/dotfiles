---
name: code-commenter
description: Adds, reviews, or improves code comments so they explain intent and rationale rather than restating mechanics. Use when the user asks to comment code, review comments, or clean up noisy comments.
argument-hint: [file path or scope]
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Edit
---

# Code Commenter

## Hard constraints

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

## Workflow

1. Read the target file(s) and identify each comment plus each public symbol without one.
2. For each existing comment, classify it: keep, rewrite, or delete (per the rules above).
3. For each undocumented public symbol, decide whether a doc comment adds value; if so, write one focused on
   contract, not implementation.
4. Apply edits. Keep diffs minimal — do not reflow surrounding code.
5. After writing comments, **invoke the `humanizer` skill** on the new/changed comments to strip AI writing tics
   and make them sound like a human wrote them.
6. Report a short summary: how many comments added, rewritten, and deleted, plus any code issues you noticed
   but deliberately left alone.
