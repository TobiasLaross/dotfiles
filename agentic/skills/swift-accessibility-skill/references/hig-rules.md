# Objective accessibility rules (Apple HIG + SwiftUI)

These are the checkable rules behind the audit. Each entry says **what to look for**,
**why it matters** (so you can judge borderline cases instead of pattern-matching),
**how to detect it** in SwiftUI source, and **the fix**. Apply judgment — a rule is a
lens, not a tripwire. A finding is only real when a VoiceOver/Switch Control/Dynamic
Type/Voice Control user would actually be worse off.

Severity guide:
- **Blocker** — a user relying on assistive tech literally cannot operate or perceive the control.
- **High** — the control works but is degraded for a real assistive-tech setting (clips, mis-announced, hard to hit).
- **Medium** — meaningful polish; state or grouping is unclear.
- **Low** — nice-to-have refinement.

---

## 1. VoiceOver semantics

### 1.1 Every interactive element is reachable and named — Blocker
A control VoiceOver can't name is a dead end. SwiftUI derives a label from a `Button`'s
title `Text`, but **icon-only** buttons, `TextField`s with only a `prompt:`, and
`.onTapGesture` views get nothing.

- Detect: `Button { … } label: { Image(systemName:) }` with no `Text` and no
  `.accessibilityLabel`; `TextField("", text:, prompt:)` with no label; any
  `.onTapGesture` view.
- Fix: add `.accessibilityLabel("…")`. Prefer the API that bakes the label in:
  `Button("Save", systemImage: "checkmark") { }` and
  `Menu("Options", systemImage: "ellipsis.circle") { }` carry an invisible text label for free.

### 1.2 Tap gestures are announced as buttons — High
`.onTapGesture` produces no button trait, so VoiceOver reads the view as plain text and
Switch Control skips it. Prefer a real `Button`; only use `.onTapGesture` when you need
tap location/count.

- Detect: `.onTapGesture` without `.accessibilityAddTraits(.isButton)` in the chain.
- Fix: convert to `Button`, or add `.accessibilityAddTraits(.isButton)` and a label.

### 1.3 State is exposed, not just drawn — Medium
A control whose meaning is visual (a selected chip, a count badge, a learned/unlearned
toggle) needs its state in the AX tree, or VoiceOver announces the same thing in both states.

- Fix: `.accessibilityValue("Selected")`, `.accessibilityAddTraits(.isSelected)`, or fold
  the state into the label. For headers, `.accessibilityAddTraits(.isHeader)` so rotor
  navigation works.

### 1.4 Decorative images are hidden; meaningful ones are labeled — Medium
A decorative `Image` that VoiceOver reads (e.g. `Image(.newBanner2026)` → "new banner 2026")
is noise. A meaningful image with no label is lost.

- Fix: decorative → `Image(decorative:)` or `.accessibilityHidden(true)`; meaningful →
  `.accessibilityLabel("…")`.

### 1.5 Group compound rows; don't over-group interactive content — Medium
A list row of several `Text`s reads as separate stops. Wrap with
`.accessibilityElement(children: .combine)` so it reads as one. But a container that holds
its own buttons must use `.accessibilityElement(children: .contain)` — `.combine` (or a
container-level `.accessibilityIdentifier`) **swallows the children's identifiers and labels**,
which both hurts VoiceOver and breaks the agentic test bots (see lilium-conventions.md).

---

## 2. Dynamic Type

### 2.1 No hardcoded font sizes — High
`.font(.system(size: 17))` doesn't scale, so users on larger text sizes get a layout that
never grows. Prefer semantic styles (`.body`, `.headline`, `.caption`) that scale automatically.

- Detect: `.font(.system(size:))` / `.font(Font.system(size:))`.
- Fix: use a semantic style. If a custom size is genuinely required, scale it:
  `@ScaledMetric var size = 17` then `.font(.system(size: size))`, or on iOS 26+
  `.font(.body.scaled(by:))`.

### 2.2 Fixed heights don't clip text — High
A `.frame(height:)` around text or a label clips at AX5 sizes. Let it grow, or cap scaling
deliberately.

- Detect: `.frame(height: N)` wrapping a `Text`/`Label`/button title.
- Fix: remove the fixed height, or add `.minimumScaleFactor(0.7)` / `.lineLimit(nil)` and
  verify at the largest accessibility size.

### 2.3 Layout survives large type — Medium
Side-by-side icon+text that must wrap should use `ViewThatFits` or switch axis at large sizes
(`@Environment(\.dynamicTypeSize)`). Flag only where clipping is plausible, not speculatively.

---

## 3. Touch targets (HIG: 44×44pt minimum)

### 3.1 Interactive elements are at least 44×44pt — High
Below 44pt is hard to hit for motor-impaired users and fails the HIG minimum. Icon-only
buttons are the usual offenders (e.g. a `trash` button in a 30×40 frame).

- Detect: `.frame(width:/height:)` < 44 on or near a `Button`/tap target.
- Fix: enlarge the frame, or keep the glyph small but expand the hit area with
  `.frame(minWidth: 44, minHeight: 44)` plus `.contentShape(Rectangle())` so the whole
  area is tappable.

---

## 4. Color & contrast

### 4.1 Color is never the only signal — High
State shown by color alone (red = error, green = done, a color-only selected state) is invisible
to color-blind users and anyone with `differentiateWithoutColor` on.

- Fix: add a glyph, shape, stroke, or text. Respect
  `@Environment(\.accessibilityDifferentiateWithoutColor)` where the difference is load-bearing.

### 4.2 Foreground/background contrast — High
Body text should clear WCAG AA (4.5:1; 3:1 for large text). In this app the recurring trap is
velvet-on-purple — see lilium-conventions.md for the exact token rules. Flag system-adaptive
colors used on the always-purple TIL card (they flip to dark-on-purple).

### 4.3 Reduce Motion — Medium
Large motion-based **animations** should degrade to a crossfade when `reduceMotion` is on. The
trigger is *animated* movement — a spring, a repeating pulse, a slide-in, a
`withAnimation`-driven transform. A **static** `.scaleEffect(1.6)` / `.offset(...)` that never
animates is not motion and is not a finding here; don't flag it.

- Detect: `withAnimation` / `.animation(...)` / `repeatForever` driving a transform, with no
  `reduceMotion` guard.
- Fix: gate the animated transform on `@Environment(\.accessibilityReduceMotion)` and fall back to
  `.opacity`.
