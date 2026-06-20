# Lilium / BookNotes accessibility conventions

Project-specific rules that layer on top of the generic HIG rules. These come from
`CLAUDE.md`, `docs/design-system.md`, and hard-won gotchas. Where this file and the generic
rules disagree, this file wins for the Lilium codebase.

## The two-modifier contract — Blocker if missing

Every `Button`, `TextField`, `SecureField`, `Toggle`, `Picker`, `Stepper`, `Slider`, view
with `.onTapGesture`, and anything tagged `.accessibilityAddTraits(.isButton)` MUST carry
**both**:

1. `.accessibilityLabel("…")` — what the control IS, plain English ("Email", "Save note").
   Most critical for icon-only buttons and `TextField`s with `prompt:` (no auto-label).
   SwiftUI already derives a label from a `Button` title or single `Text` child — don't
   double-label those.
2. `.accessibilityIdentifier("namespace.elementName")` — stable handle for the agentic test
   bots and UI tests. Not localized, survives copy edits.

A missing identifier isn't just a polish issue here: the agentic-QA bots resolve taps by
identifier, so an un-ided control is **untestable**, and a control with neither is invisible
to VoiceOver too.

## Identifier namespaces — flat dot-namespace per surface

Use an existing prefix when the element belongs to that surface; coin a new one only for a
genuinely new surface. Established prefixes (counts are rough usage in the repo, so the big
ones are the safe pattern to copy):

`groups.*`, `settings.*`, `groupDeck.*`, `captureTIL.*`, `tilCard.*`, `library.*`, `auth.*`,
`feed.*`, `bookClubChapters.*`, `practice.*`, `groupDetail.*`, `suggestions.*`, `manualBook.*`,
`bookBrowse.*`, `quiz.*`, `import.*`, `userProfile.*`, `groupComments.*`, `bookSearch.*`,
`banner.*`, `groupDiscussion.*`, `linkedEditions.*`, `export.*`, `club.*`, `chapterPost.*`,
`bookDetail.*`, `readingListImport.*`, `profile.*`, `migration.*`, plus cross-cutting
`paywall.*`, `onboarding.*`, `nav.*`.

Identifier style: `surface.elementName` in lowerCamel, e.g. `captureTIL.saveButton`,
`tilCard.deleteAlertConfirm`. Note the **capture surface uses `captureTIL.*`** (renamed from
the old `createTIL.*`).

## Gotcha — container identifier swallows child ids — High

Putting `.accessibilityIdentifier(...)` (or `.accessibilityElement(children: .combine)`) on a
container that holds buttons collapses the children: their ids/labels stop enumerating, so the
bots can't reach them. When a container needs an id but contains interactive children, use
`.accessibilityElement(children: .contain)`. Audit any `.accessibilityIdentifier` on a `VStack`/
`HStack`/`ZStack`/row that wraps tappable children.

## Gotcha — `.keyboard` toolbars don't reach the AX tree — High

Buttons inside `ToolbarItem(placement: .keyboard)` / `ToolbarItemGroup(placement: .keyboard)`
render on screen but iOS bridges the whole bar to accessibility as a single empty `Toolbar`
group — the individual buttons' identifiers never enumerate. A bar whose content is
*conditional* (`if isFocused { … }`) also races UIKit's accessory capture on a physical device
and can land empty forever (#776).

Fix for both: pin the bar as an ordinary view via `safeAreaInset(edge: .bottom)` instead of a
`.keyboard` toolbar. Already migrated: `ClozeKeyboardAccessoryBar`,
`TILMarkdownKeyboardToolbar` (via `MarkdownEditorAccessoryBar`). Still on `.keyboard` and worth
flagging if a scenario must drive them: the static single-button Done bars (sign-in / sign-up,
book search, manual book entry).

## Velvet color & contrast traps — High

The design system has two user-picked themes; tokens are asset-backed
(`Color.velvetGold`, `velvetParchment`, `velvetListRow`, `velvetCardBase`, `velvetInk`, …).
Accessibility-relevant traps:

- **Inside the always-purple TIL card**, foreground must be `Color.velvetParchmentFixed`
  (non-adaptive cream) or `Color.velvetGold`. **Never** `velvetInk` / `Color.primary` / any
  system-adaptive color there — they flip to dark-on-purple and tank contrast.
- **Tappable containers** (buttons, chips, rows, inputs) fill with `Color.velvetListRow`.
  The old recipe `velvetParchment.blended(with: .black, amount: 0.04–0.06)` is invisible in
  dark mode — flag it.
- Don't force a theme per-view (`.preferredColorScheme(.light)`,
  `.toolbarColorScheme(.light, …)`) — it breaks the user's chosen appearance.
- Don't drop system-themed controls (`.pickerStyle(.segmented)`, default `Form`/`List` chrome)
  onto velvet surfaces — they bring colors that fight the palette and can lose contrast.

## Live verification via idb — the AXUniqueId rule

When verifying on the simulator, idb exposes `.accessibilityIdentifier` under the JSON key
**`AXUniqueId`** — there is **no** `AXIdentifier` key. Tooling that looks for `AXIdentifier`
finds nothing and silently falls back to the localized `AXLabel`, which breaks under a non-
English launch. The shared matcher `ax.py` (used by `shots.sh tap-label` / `wait-label` /
`tap-tab`) already matches `AXUniqueId` first, so drive navigation by the dot-namespaced id.

To confirm an element actually reaches the AX tree, dump the live tree and grep for the id:

```sh
idb ui describe-all --json | python3 -c "import sys,json; \
  [print(e.get('AXUniqueId'), '|', e.get('AXLabel'), '|', e.get('frame')) \
   for e in json.load(sys.stdin) if e.get('AXUniqueId')]"
```

If an id you added in source doesn't appear here, suspect a container-collapse or `.keyboard`-
toolbar swallow (the two gotchas above) rather than a typo. See
`~/.claude/references/idb-ax-debugging.md` for live AX debugging.
