---
name: swift-safety
description: >-
  Reviews a Swift diff for the runtime-safety bugs the other Swift review skills do not cover:
  swallowed errors (empty catch, try? that drops a meaningful error, fatalError or assert where
  the caller could recover), retain cycles (escaping closures and stored Tasks holding self
  strongly, strong delegates), switches that hide cases (@unknown default on SDK enums, a bare
  default over the project's own enums), iOS security (hardcoded secrets, tokens in
  UserDefaults or @AppStorage, ATS exceptions, unvalidated deep-link and universal-link input),
  and print() in shipped code. Use it on every Swift diff in any iOS or macOS project before
  committing or opening a PR, alongside /swiftui-pro and /swift-concurrency-pro, and whenever
  the user asks to check Swift code for crashes, leaks, error handling, or security. Do NOT use
  it for SwiftUI style, concurrency isolation, accessibility, or test-framework review: those
  belong to swiftui-pro, swift-concurrency-pro, swift-accessibility-skill and swift-testing-pro.
argument-hint: '[files, a directory, or "the diff" (defaults to the current branch diff)]'
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# Swift safety review

Five checks that catch bugs which compile cleanly, pass tests, and then fail quietly in
production. Each one has a narrow trigger and a list of look-alikes that are fine, because a
check that flags every `try?` is a check nobody reads.

## Scope

1. Find the changed Swift: the branch diff against the default branch plus uncommitted work
   (`git diff --name-only $(git merge-base HEAD origin/main)` and `git diff --name-only HEAD`),
   or the files the user named. Review only changed lines and the code they directly touch.
2. Read the project's `CLAUDE.md` and `.swiftlint.yml` first. Where the project already has a
   convention (a logging type, a secrets mechanism, a rule SwiftLint enforces), judge against
   that convention and don't re-flag what the linter already blocks.
3. Test targets are exempt from checks 1 and 5. A crash or a print in a test is a failing test.

## 1. Swallowed errors

Flag:

- An empty `catch {}`, or a `catch` whose only statement is a comment.
- `try?` on a call whose failure the user or the developer needs to know about: a save, a
  write, a network send, a decode of server data, a Keychain write. The tell is that the
  result is discarded (`_ = try? save()`) or collapses into a default that hides the failure
  (`(try? decode(data)) ?? []` showing an empty list instead of an error).
- `fatalError`, `preconditionFailure` or `precondition` on a condition the program can reach
  through bad input, a network response, a file on disk, or a missing resource. Those throw or
  return an error state.
- `assert` guarding something that must hold in release. `assert` is compiled out of release
  builds, so the release path runs on with the bad value. Use `precondition`, or handle it.

Fine, don't flag:

- `try?` where nil really is the answer: an optional cache read, `Task.sleep` in a cancellable
  loop, parsing an optional field, a best-effort cleanup that is logged elsewhere.
- `fatalError` for programmer errors that can't be reached at runtime: `required init?(coder:)`,
  an exhausted switch over a closed set, a resource the build guarantees is bundled.
- A `catch` that logs through the project's logger and moves to an error state.

Fix: propagate with `throws`, or catch, log, and surface an error state. Name the user-visible
consequence in the finding ("a failed save shows the old list with no message").

## 2. Retain cycles

Flag:

- An escaping closure stored on `self` or on something `self` owns that captures `self`
  strongly: completion handlers kept in properties, `NotificationCenter` block observers,
  timers, `AsyncStream` continuations' `onTermination`.
- A `Task` stored in a property of `self` whose body captures `self` strongly and runs a long
  or unbounded loop (`for await` over a stream, a polling loop). The task keeps `self` alive,
  so `deinit`, which is where the task would be canceled, never runs.
- A `delegate` / `dataSource` property that isn't `weak`.

Fine, don't flag:

- Non-escaping closures (`map`, `filter`, `withAnimation`, SwiftUI view builders).
- SwiftUI `.task {}`, `.onAppear`, `Button` actions: SwiftUI owns their lifetime.
- A short `Task { await self.load() }` that isn't stored and finishes. It holds `self` until
  done, which is usually what you want.
- Closures on value types (`struct` views capture a copy, not a reference).

Fix: `[weak self]` with `guard let self else { return }` at the top of the body, or cancel
the stored task from an explicit `stop()` that the owner calls. Don't rely on `deinit` to
cancel a task that captures `self`. Prefer `weak` over `unowned` unless the lifetime
guarantee is obvious from the code.

## 3. Switches that hide cases

Flag:

- A switch over an Apple SDK or other non-frozen library enum (`UNAuthorizationStatus`,
  `CLAuthorizationStatus`, `ScenePhase`, `PHAuthorizationStatus`, StoreKit and RevenueCat
  states) that uses `default:` instead of listing the known cases plus `@unknown default:`.
  With `@unknown default` the compiler warns when the SDK adds a case. With `default` it stays
  silent.
- A `default:` over an enum the project defines. Adding a case then compiles without touching
  this switch, which is how a new state ends up with the old behavior. List the cases.

Fine, don't flag: `default:` over `String`, `Int` and other open types, or over a project enum
with dozens of cases where the switch handles one or two deliberately (say so in the finding
if unsure, at low severity).

## 4. iOS security

Flag:

- A secret in source or in a committed config: API keys, signing secrets, private tokens,
  passwords. Public SDK keys meant to ship in the binary (a RevenueCat public key, an
  analytics write key) are fine, but check the project's convention for where they live.
- An access token, refresh token, password, or other credential stored in `UserDefaults`,
  `@AppStorage`, a plist, or a plain file. It belongs in the Keychain.
- A new `NSAppTransportSecurity` exception (`NSAllowsArbitraryLoads`, an exception domain)
  in `Info.plist`, `project.yml`, or an `.xcconfig`, without a stated reason.
- Input from outside the app used without checking it: `onOpenURL`, `onContinueUserActivity`,
  universal links, push payloads, the pasteboard, or a shared-container file. Check that the
  host and path are the expected ones, IDs parse to the expected type, and a malformed link
  lands on a safe screen rather than crashing or acting (no deep link may trigger a purchase,
  a delete, or a send without the user confirming).
- Logging a credential, token, or full auth header, at any log level.

Fine, don't flag: test fixtures with obviously fake values, and keys that are documented as
publishable.

## 5. print() in shipped code

Flag `print(`, `debugPrint(` and `dump(` in app-target code. Use the project's logging type
(look for an existing `Logger` / `os.Logger` wrapper and match it). Code inside `#if DEBUG`,
previews, scripts, and test targets is fine.

## Report

One block per finding, most severe first:

```
[HIGH] Sources/Feature/SyncService.swift:84: swallowed error
  `_ = try? store.save(snapshot)` drops a failed save; the user keeps editing and loses the
  change on next launch.
  Fix: make `persist()` throw and show the existing save-failed banner.
```

Severity:

- **HIGH**: a crash on reachable input, lost user data, a leaked credential, a deep link that
  acts without confirmation, a retain cycle on a screen the user opens repeatedly.
- **MEDIUM**: an error swallowed where a retry or message was possible, a hidden enum case, a
  strong delegate.
- **LOW**: `print` in shipped code, a borderline `default:`.

If nothing survives, say so in one line. Don't pad the report with checks that passed.

When the user asks to apply the fixes, make them, then build and run the project's test
command (from its `CLAUDE.md`). Never fix a finding by suppressing a lint rule.
