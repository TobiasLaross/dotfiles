---
name: humanizer
description: Rewrites text or comments to remove AI writing tics (delve/leverage/robust, tricolons, em-dash overuse, empty intros and closers, cheerleader tone) and make them sound like a human engineer wrote them. **Use after generating any prose Claude wrote: commit messages, code comments, PR descriptions, READMEs, story.md / design.md / spec docs, release notes, Slack/email drafts** — or whenever the user says something "sounds like AI", "is too markety", "is too flowery", or asks you to tighten/dehydrate the wording. Preserves meaning exactly; only the style changes.
argument-hint: [file path, range, or pasted text]
disable-model-invocation: false
allowed-tools: Read, Edit, Grep, Glob
---

# Humanizer

Rewrite the target text so it reads like a human engineer wrote it in a hurry, not like a model generating
plausible prose. **Preserve meaning exactly** — do not add information, soften claims, or hedge things that
were stated plainly. Only the *style* changes.

## Hard constraints

- **Only touch prose, doc comments, and markdown.** Never edit code, identifiers, type signatures, imports,
  config keys, JSON/YAML values, regex patterns, SQL, shell commands, or anything inside fenced code blocks. If
  a sentence quotes an identifier or value, rewrite the surrounding prose but leave the quoted text byte-for-byte
  intact.
- **Preserve technical claims verbatim.** If the text says "deadlocks under contention" or "returns 401 on an
  expired token", do not soften, generalize, or hedge it. The tells you remove are stylistic; the substance stays.
- **Match the surrounding voice.** If the file or thread already has a clear voice (the user's existing commit
  messages, a colleague's code review, a project's README tone), edit toward that voice — don't impose a generic
  "humanized" style.

## Tells to remove

### Vocabulary

Replace or delete on sight:

- "delve", "dive into", "explore", "navigate", "embark", "journey"
- "leverage" → use, "utilize" → use, "facilitate" → help / let, "employ" → use
- "robust", "seamless", "seamlessly", "effortless", "elegant", "powerful", "comprehensive", "rich", "vibrant",
  "cutting-edge", "state-of-the-art", "best-in-class"
- "in the realm of", "in the world of", "in today's fast-paced…", "it is important to note that"
- "furthermore", "moreover", "additionally" at the start of a sentence — usually just delete
- "ensure that" → "make sure" or just drop "that"
- "a myriad of", "a plethora of" → "many" or a number
- "crucial", "vital", "essential", "pivotal" → "important" or delete
- "unleash", "unlock", "supercharge", "empower" — delete
- Empty intros: "Certainly!", "Of course!", "Great question!", "I'd be happy to" — delete
- Empty closers: "I hope this helps!", "Let me know if you have any questions!", "Happy coding!" — delete

### Structure

- **Tricolons / rule of three.** "fast, reliable, and scalable" — pick the one that's actually true and drop
  the others.
- **Parallel "not just X but Y" constructions.** "It's not just a library, it's a way of thinking." Cut.
- **Bullet lists that should be sentences.** If three bullets each have one phrase, write one sentence.
- **Section headers for short content.** Don't put a `## Overview` above two sentences.
- **Em-dash overuse** for dramatic pauses — one or two per page is fine, ten is a tell. Prefer commas, periods,
  or parentheses.
- **Symmetric sentence pairs.** "X is Y. But Z is W." — vary the rhythm.
- **Trailing summary sentences** that restate the paragraph. Just stop at the last real point.

### Tone

- Drop the cheerleader voice. No "exciting", "amazing", "fantastic", "powerful new way".
- Drop the academic hedge. No "it could be argued that", "one might consider", "it is generally accepted".
- Don't apologize for length, simplicity, or limitations unless the user asked.
- Don't announce what you're about to do ("Let's break this down…") — just do it.

## What to keep

- **Technical precision.** Don't dumb down terminology or replace specific terms with vague ones.
- **Direct statements.** If the original says "this will deadlock", keep it — don't soften to "this may
  potentially lead to a deadlock scenario".
- **Code, identifiers, paths, links, numbers, error messages** — never paraphrase these.
- **The author's voice** if it's already present (e.g. existing commit messages, code review comments).

## Don't over-humanize

The goal is "tired senior engineer wrote this", not "rude bot with a 50-word vocabulary". Watch for these
failure modes and back off when you see yourself doing them:

- **Choppy fragments.** Cutting until every sentence is three words. Some flow is fine — humans use connectors.
  Keep "because", "so", "when", "if", "since" when they carry real meaning.
- **Stripping structure that was earning its keep.** A real list of four distinct items should stay a list. A
  heading that introduces a genuinely separate section should stay a heading. Cut structure that's decorative,
  not structure that's load-bearing.
- **One-pass-too-many.** If you already cut 30%, stop. Re-reading three times and trimming each pass turns
  the text into a telegram. When in doubt, leave it.
- **Replacing one tic with another.** Don't trade "leverage" for "harness", "robust" for "solid", "delve" for
  "dig into". If you can't say it plainly, leave the original word.
- **Removing necessary hedges.** "May fail under load" is a calibrated claim, not a cheerleader hedge. Strip
  "it could be argued that…" but keep "may", "can", "sometimes" when they're load-bearing.

## Workflow

1. Read the target. If it's a file or range, identify exactly which prose is in scope (skip code blocks and
   identifiers).
2. For each sentence, ask: would a tired senior engineer write this, or does it sound like marketing? Rewrite
   the marketing ones, leave the engineering ones.
3. Prefer **deletion** over rewriting. Most AI prose gets better by cutting 30%.
4. Read the result aloud in your head. If it still sounds like a brochure, cut more.
5. Apply edits with minimal diff — do not reflow unrelated lines.
6. Report a short summary: lines changed, words removed, and any phrasing you were unsure about.

## Examples

| Before | After |
|---|---|
| "This robust solution leverages a comprehensive set of tools to seamlessly facilitate the deployment process." | "Deploys with the existing tools." |
| "It is important to note that the function will return `nil` if the input is empty." | "Returns `nil` on empty input." |
| "Let's dive into how this works." | (delete) |
| "We employ a sophisticated caching strategy to unlock significant performance gains." | "Caches results; ~3x faster." |
| "Furthermore, the system is designed to be highly scalable and incredibly fast." | "Scales horizontally." |
