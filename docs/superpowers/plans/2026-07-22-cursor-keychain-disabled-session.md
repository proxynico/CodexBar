# Cursor Refresh Without Keychain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Return live Cursor usage data when CodexBar intentionally disables Keychain access.

**Architecture:** Treat disabled Keychain access as an explicit no-cache mode at the Cursor session reconciliation boundary. Successful API data remains authoritative, while the existing concurrent session-change checks remain active whenever Keychain access is available.

**Tech Stack:** Swift 6, Swift Testing, SwiftPM

## Global Constraints

- Keep `debugDisableKeychainAccess` effective and do not add any new credential store.
- Do not run live provider probes or tests that can display macOS Keychain prompts.
- Make the smallest correct change and preserve existing Cursor account-race behavior.

---

### Task 1: Accept successful Cursor results in no-Keychain mode

**Files:**
- Modify: `Sources/CodexBarCore/Providers/Cursor/CursorStatusProbe.swift:1314`
- Test: `Tests/CodexBarTests/CursorImportedSessionScanningTests.swift`

**Interfaces:**
- Consumes: `KeychainAccessGate.isDisabled` and `CursorStatusProbe.resolveImportedSession`
- Produces: `CursorStatusProbe.reconcileResolvedSession` returning the already-fetched value without cache mutation when Keychain access is disabled

- [ ] **Step 1: Write the failing regression test**

```swift
@Test
func `resolved session accepts live result when keychain access is disabled`() async throws {
    let probe = CursorStatusProbe(browserDetection: BrowserDetection(cacheTTL: 0))
    let session = Self.makeSessionInfo(sourceLabel: "Cursor.app local auth", cookieValue: "live")

    let outcome = try await KeychainAccessGate.withTaskOverrideForTesting(true) {
        let observation = CookieHeaderCache.observeForConditionalMutation(provider: .cursor)
        return try await probe.resolveImportedSession(
            session,
            perform: { cookieHeader, _ in cookieHeader },
            log: { _ in },
            cacheObservation: observation)
    }

    guard case let .succeeded(cookieHeader) = outcome else {
        Issue.record("Expected the successful live Cursor result")
        return
    }
    #expect(cookieHeader == session.cookieHeader)
    #expect(CookieHeaderCache.load(provider: .cursor) == nil)
}
```

- [ ] **Step 2: Run the test and verify the current code fails**

Run: `swift test --filter 'CursorImportedSessionScanningTests/resolved session accepts live result when keychain access is disabled'`

Expected: FAIL with `Cursor session changed during refresh`.

- [ ] **Step 3: Add the no-cache reconciliation guard**

```swift
if KeychainAccessGate.isDisabled {
    context.log("Keychain access disabled; accepting uncached Cursor result from \(context.sourceLabel)")
    return value
}
```

Place this at the start of `reconcileResolvedSession`, before any `CookieHeaderCache` mutation.

- [ ] **Step 4: Run the focused test and related Cursor session tests**

Run: `swift test --filter CursorImportedSessionScanningTests`

Expected: all selected tests pass.

- [ ] **Step 5: Run repository verification**

Run: `make test && make check`

Expected: both commands exit 0 with no test, formatting, lint, or policy failures.

- [ ] **Step 6: Review, commit, and push**

```bash
git diff --check
git status --short
git add Sources/CodexBarCore/Providers/Cursor/CursorStatusProbe.swift \
  Tests/CodexBarTests/CursorImportedSessionScanningTests.swift \
  docs/superpowers/specs/2026-07-22-cursor-keychain-disabled-session-design.md \
  docs/superpowers/plans/2026-07-22-cursor-keychain-disabled-session.md
git commit -m "Fix Cursor refresh without Keychain"
git push fork main
```

Expected: the scoped commit is created and `fork/main` advances to it.
