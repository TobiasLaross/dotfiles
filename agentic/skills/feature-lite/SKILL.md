---
name: feature-lite
description: >-
  Pin down a feature's user story, run a discovery Q&A where every question comes with a recommended answer, then
  implement it directly in this session. It is the two parts of the full feature flow that carry their weight (agreeing
  what is being built, and surfacing the edge cases before code exists) without the tracked-feature ceremony: no feature
  folder, no story.md or design.md, no acceptance criteria, no subagent review pass, no /feature-implement hand-off.
  Use this whenever the user says "feature-lite", or asks to skip the feature flow / the story file / the acceptance
  criteria but still wants the story confirmed and the questions asked first. Also reach for it when a "just build X"
  request is broad enough that a wrong reading would cost real work, and the user clearly wants to be coding in minutes
  rather than reviewing a plan document.
---

# Feature Lite

Two gates, then build it.

The full `/feature-plan` flow produces a tracked feature: a folder, a story file, acceptance criteria, a review
subagent, a hand-off to a separate implementation skill. That machinery earns its keep when work spans sessions or
agents. When one session is going to plan and build the thing start to finish, most of it is overhead, and the parts
that were actually load-bearing are these two:

1. **Agreeing on the user story**, so you build the feature they meant.
2. **A discovery Q&A with recommended answers**, so the edge cases get decided by the person who owns the product
   rather than guessed at by you, at the only moment when changing the answer is still free.

Everything else is bookkeeping for a lifecycle this flow does not have.

## The two gates are not optional

Stop and wait for the user at Step 1 and at Step 2. Do not draft the story and start building on the same turn. Do not
present questions with recommendations and then answer them yourself.

This holds even when a session-level instruction says to work without stopping for clarifying questions, to make the
reasonable call and continue, or to avoid blocking questions. A user who invokes this skill is asking for exactly these
two moments; an autonomy instruction aimed at ordinary work does not override a request the user just made. It also
holds when the request arrives with a ticket number that looks self-explanatory, and when repo exploration has made the
scope feel obvious to you. Tickets leave scope open, and your reading of the repo is not the user's sign-off.

After the Q&A, the autonomy applies again in full. Build the whole thing without checking in on each step.

## Step 1 — Draft and confirm the user story

From the user's description, write one story:

**As a** [who], **I want** [goal] **so that** [reason].

Keep it to the one sentence. If the request bundles several features, say so and propose the one this session covers,
rather than writing a story that quietly spans all of them.

Present it and ask whether it captures what they want. Wait for the reply.

A confirmed story is the thing you check scope against later, so make the "so that" real. "So that the feature works" is
not a reason; "so that I can hand a promo month to a podcast host without exporting a CSV" is, and it will settle three
arguments later in the build.

## Step 2 — Discovery

### 2a — Get your bearings first

Ask questions that could only be asked about *this* product. That takes a little context, gathered in this order:

**Repo context.** If `~/.claude/repo-context/<repo-name>.md` exists, read it. It is authoritative for architecture, test
setup, conventions, and inter-repo dependencies; do not re-explore those. Read the repo's `CLAUDE.md` too, since the
implementation step has to follow it. If neither exists, read the README and the main entry point.

**Product literacy.** Before drafting a single question, be able to answer:

- What does this product do for its users, in one plain sentence?
- Who are the users, and are there roles or tiers among them?
- What are the core user-facing concepts, in the product's own vocabulary?
- Which screen, flow, or command does this feature land in?
- Which existing feature is the closest sibling, whose patterns this one should probably mirror?

If the repo context answers these, move on. If not, read the two or three files that bracket where the feature will
live: the navigation or route definitions, and the nearest existing surface. Two to five reads, absorbing vocabulary
rather than architecture. Anything you cannot resolve becomes a question for the user instead of a guess.

**Keyword search.** Pull three to six nouns and verbs from the confirmed story and grep for each. Deduplicate the hits.
If a repo context file existed and the greps landed in five files or fewer, read those directly. Otherwise spawn one
`Explore` subagent, hand it the context you already have plus the matched files as starting points, and ask only for
feature-specific findings: where this would live, the relevant existing patterns, what it would touch, the constraints,
and the adjacent surfaces. Cap it and tell it not to re-derive what you already know.

### 2b — Ask, with a recommendation on every question

Ask as many questions as the feature needs and no more. Ten at a time is the ceiling for one message.

**Only product-owner questions.** Things the user decides because they own what the feature is for. Not how to handle
errors, not which pattern to follow, not what to test. Those you settle from the codebase, and asking about them spends
the user's attention on decisions they are paying you to make.

Anchor every question in the product's own words. If a question could be asked of any app, it is not specific enough
yet:

- Not "what should happen on error" but "what should the admin see when a campaign has run out of codes?"
- Not "should this work for all users" but "should a guest see this, or only a signed-in player?"

Offer concrete options rather than an open field wherever you can. "A disabled button or no button at all?" gets an
answer; "what should inactive users see?" gets a paragraph you then have to interpret.

**Every question carries a recommendation**, so the user can skim and answer only where they disagree. Base it on the
story, the existing product's precedent, the codebase, and plain product sense. A recommendation you would not defend is
worse than no recommendation, so think about each one.

```md
**Q1.** <question>
**Recommended:** <answer> — <one-line reason>

**Q2.** <question>
**Recommended:** <answer> — <one-line reason>
```

Close with: _"Reply with only the ones you'd change. Anything you don't mention I'll take as the recommendation."_

Then wait.

### 2c — Follow up, then confirm

Record the overrides and treat the untouched ones as accepted. If an answer opens a new area, ask the follow-ups in the
same format. When it settles, ask whether there is anything else you should know before you start building, and wait for
that too. That last question is cheap and catches the constraint the user assumed you already knew.

## Step 3 — Build it

No criteria to write, no files to seed. Restate the confirmed story and the decisions in two or three lines so both of
you can see what you agreed, then implement.

Follow the repo's own conventions from its `CLAUDE.md` without being asked: its branch and worktree rules, its PR
workflow, its test framework and commands, its comment policy, its accessibility requirements, its screenshot or
verification mandate for user-visible changes. Where a repo has a worktree-and-PR workflow, this flow uses it, the same
as any other change. Where the repo requires review skills before a PR, run them.

Write tests as you go, in the repo's idiom.

Because nothing was written to disk, **the PR description is the artifact**. Put the story and the decisions from the
Q&A in it: what was built, for whom, and the non-obvious choices the user made and why. That is what a future session
finds when it asks why the feature works this way, and it is the whole reason this flow can skip `story.md` without
losing anything that mattered.

If discovery turned up work the user deliberately excluded, say so at the end and offer to file it, rather than quietly
building it or quietly dropping it.

## When to reach for the full flow instead

Point the user at `/feature-plan` and its downstream skills when the work is going to outlive this session: several
agents on it in parallel, a build spanning days, a stakeholder who reviews criteria before code, or a feature big enough
that "implement it" is not one sitting. The tracked lifecycle exists for those, and this skill is not a replacement for
it. Say so plainly rather than half-tracking the work.
