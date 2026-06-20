---
name: swift-accessibility-skill
description: >-
  Audits SwiftUI accessibility in the Lilium / BookNotes app against Apple's Human Interface
  Guidelines AND the project's own conventions (the mandatory .accessibilityLabel +
  dot-namespaced .accessibilityIdentifier on every interactive element), then reports findings
  with file:line, severity, and a concrete fix — and offers to apply them. Covers VoiceOver
  semantics, Dynamic Type, 44pt touch targets, color/contrast (incl. velvet-on-purple traps),
  Reduce Motion, and the .keyboard-toolbar / container-collapse AX-tree gotchas, with an
  optional live pass that drives the simulator via idb to confirm identifiers actually resolve.
  Use this WHENEVER the user wants to check, audit, review, or improve accessibility / a11y /
  VoiceOver / Dynamic Type support for a SwiftUI view, screen, or diff — even phrased as "is
  this screen usable with VoiceOver?", "did I miss any accessibility labels?", "make this view
  accessible", "check the new sheet for a11y", or "audit accessibility before I open the PR".
  Also trigger it proactively after building or restyling any SwiftUI view, since the
  type-checker can't see missing labels, clipped Dynamic Type, or undersized tap targets. Do
  NOT use it for backend/API code, for pure copy/localization review, or as a general SwiftUI
  correctness review (use swiftui-pro for that).
argument-hint: '[files, a directory, or "the diff" — defaults to the current diff]'
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# SwiftUI accessibility audit

Audit SwiftUI code so a VoiceOver, Switch Control, Voice Control, or Dynamic Type user can
actually operate it — and so the agentic-QA bots can drive it. You are checking against two
things at once: **Apple's HIG** (the objective rules in `references/hig-rules.md`) and **this
project's conventions** (the label+identifier contract and the velvet/idb gotchas in
`references/lilium-conventions.md`). Read both reference files before judging; they carry the
*why* behind each rule so you can reason about borderline cases instead of pattern-matching.

The goal is real findings a real assistive-tech user would feel — not a lint dump. A clean
build proves nothing here: the compiler never sees a missing label, a clipped frame at AX5
text, an undersized tap target, or a color-only state.

## 1. Establish scope

- Default (no argument, or "the diff"): the changed Swift files — `scripts/a11y_scan.py --diff`.
- A path/directory: audit those files.
- A whole surface ("the Groups screens"): glob the matching views.

Audit only SwiftUI view code (`.swift` files with view bodies). Skip tests, mocks, and
non-view types.

## 2. Run the candidate finder

```sh
python3 scripts/a11y_scan.py <paths|--diff>
```

This is a **heuristic pre-filter, not the verdict.** Regex can't see Swift types or view
composition, so each hit is a *candidate*: a child view may already supply the label, a small
frame may not be the tap target, an `Image` may be decorative. Treat the output as a checklist
of sites to open and confirm — never report a scanner hit as a finding without reading the code
around it. The scanner's value is coverage (nothing interactive slips past) and a starting map.

It flags: icon-only buttons with no label (A11Y001), `.onTapGesture` without the button trait
(A11Y002), hardcoded font sizes (A11Y003), sub-44pt frames near controls (A11Y004), `.keyboard`
toolbars (A11Y005), interactive elements with no identifier (A11Y006), and duplicate identifier
literals across the scanned files (A11Y007). A11Y007 is a *candidate* like the rest: the same id
on two mutually-exclusive screens (sign-in vs sign-up) is usually fine; the real bug is the same
id within one screen, or shared between a reusable component and a live call site — there the
bots match the wrong element.

## 3. Read and judge each candidate, plus what the scanner can't see

Open each flagged site and the views in scope. Confirm or dismiss each candidate, and check the
things regex misses — these need eyes on the code:

- **The two-modifier contract** (lilium-conventions.md): every interactive element has BOTH a
  label and a dot-namespaced identifier. Confirm the identifier's prefix matches the surface.
- **VoiceOver semantics** (hig-rules.md §1): state exposed not just drawn, decorative images
  hidden, compound rows grouped — and the **container-collapse** trap (an id or `.combine` on a
  container that holds buttons swallows their ids).
- **Dynamic Type** (§2): fixed heights around text, layouts that won't survive AX5.
- **Touch targets** (§3): confirm a flagged small frame is really the hit area.
- **Color & contrast** (§4): color-only state; velvet-on-purple traps (system-adaptive colors
  on the always-purple TIL card, the invisible-in-dark `blended` recipe).
- **Reduce Motion** (§4.3): big animations with no degraded path.

- **Reachability & duplicate ids** (A11Y007 + a quick check): for a reusable component, grep the
  repo for its type name (`grep -rn "<TypeName>(" Lilium`) — if it has no call site it's dead code,
  and the fix is to delete it, not to decorate it; say so instead of filing a11y findings against
  it. Confirm each A11Y007 duplicate: same id within one screen, or shared between a component and a
  live path, means the bots can match the wrong element — flag it; the same id on two screens that
  never coexist is fine.

When you add labels/identifiers to a view, also fix nearby interactive elements missing them —
but don't fan out into unrelated files just to add coverage.

### Precision — what NOT to flag

The skill's edge over a generic review is restraint: a report full of non-issues trains the user
to ignore it. Before writing a finding, make sure it would actually hurt a real assistive-tech
user. Common false alarms to suppress (the scanner will surface some of these as candidates — your
job is to dismiss them):

- **A `.white` / `velvetParchmentFixed` / `velvetGold` foreground inside the always-purple TIL
  card.** That's the *correct* non-adaptive choice there (lilium-conventions.md). Don't recommend
  `velvetInk`/`Color.primary` for it — that's the actual bug, reversed.
- **A `Button` whose label comes from a `Text` child or the highlight/title content.** SwiftUI
  derives the VoiceOver label from it; an explicit `.accessibilityLabel` would double it up.
- **Decorative images already `.accessibilityHidden(true)`**, and small frames on decorative
  shapes (an 8pt badge dot) that aren't the tap target.
- **A static `.scaleEffect`/`.offset` with no animation.** Reduce Motion is about *animations* —
  a constant transform isn't motion, so it isn't a Reduce Motion finding.
- **`.font(.system(.body, design: .serif))` and friends** — that's a *semantic* style with a
  design, which scales. Only a literal `.font(.system(size: 17))` breaks Dynamic Type.

## 4. Optional — verify live on the simulator

Offer this when identifiers/AX-tree reachability is the concern (the `.keyboard` and
container-collapse gotchas only show at runtime), or when the user asks to confirm on device.
It needs a running sim with the screen reachable. Follow the **idb / AXUniqueId** procedure in
`references/lilium-conventions.md`: dump `idb ui describe-all --json` and confirm each id you
expect appears under `AXUniqueId`. An id present in source but absent from the tree means a
swallow, not a typo.

This drives the simulator — respect the screenshot/agentic-testing hygiene in the repo docs and
don't collide with a running regression. Skip it for a pure source audit.

## 5. Report

Group findings by file, ordered by severity (Blocker → High → Medium → Low). For each:

```
### <file>:<line>  [<Severity>]  <rule>
What: <the problem, one line>
Why:  <who is affected and how — VoiceOver/Dynamic Type/motor/color-blind user>
Fix:  <concrete SwiftUI change, with the exact modifier/identifier to add>
```

Open with a one-line tally (e.g. "3 Blocker, 2 High, 1 Medium across 4 files"). If a screen is
clean, say so plainly — don't invent findings to fill the report. Note anything that needs the
live pass to confirm.

Severity meanings: **Blocker** = assistive-tech user can't operate/perceive it; **High** =
degraded for a real setting (clips, mis-announced, hard to hit); **Medium** = unclear state or
grouping; **Low** = polish. Definitions in hig-rules.md.

## 6. Offer to fix

After the report, ask whether to apply the fixes. The mechanical ones (add a missing
identifier/label, enlarge a hit area, swap a hardcoded font for a semantic style) are safe to
batch. The judgment ones (regrouping for VoiceOver, restructuring a `.keyboard` toolbar into a
`safeAreaInset`) are worth confirming first. Per repo rules, code changes go in a worktree, not
on `main` — if the user wants the fixes applied, set that up. If a fix changes what's on screen,
the change still needs a screenshot to verify (the type-checker can't see it).
