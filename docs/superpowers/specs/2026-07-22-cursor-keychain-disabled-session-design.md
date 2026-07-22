---
summary: "Accept live Cursor usage results when CodexBar Keychain access is intentionally disabled."
read_when:
  - Changing Cursor session reconciliation
  - Debugging Cursor refreshes with Keychain access disabled
---

# Cursor Refresh Without Keychain — Design

**Status:** approved
**Date:** 2026-07-22

## Problem

Cursor's authenticated usage request succeeds, but session reconciliation then tries to publish the resolved session to `CookieHeaderCache`. When `KeychainAccessGate.isDisabled` is true, that store is intentionally unavailable. Reconciliation mistakes the unavailable cache for a concurrent session replacement and throws `Cursor session changed during refresh`, discarding the valid live result.

## Design

Keep the global Keychain block intact. In `reconcileResolvedSession`, return the successful fetched value immediately when Keychain access is disabled. Do not attempt a cache read or write in that mode. When Keychain access is enabled, keep the existing conditional mutation and concurrent account-change protection unchanged.

## Testing

Add a focused test around `resolveImportedSession` that disables Keychain access, performs a successful fetch, and proves the fetched value is returned without a cache entry. Preserve the existing tests that verify same-credential acceptance and different-credential retry behavior while Keychain access is available.

## Non-goals

- Re-enable Keychain access.
- Store Cursor cookies in plaintext configuration.
- Change Cursor API parsing, refresh cadence, or account selection.
