---
summary: "Nico fork roadmap: completed 0.45 integration and current maintenance priorities."
read_when:
  - Reviewing fork status
  - Planning the next upstream refresh
  - Deciding whether work belongs in the fork
---

# Fork roadmap

This roadmap tracks the current `proxynico/CodexBar` fork. It replaces the former topoffunnel/Augment roadmap.

## Completed: upstream 0.45 integration

The fork moved from 0.41.0/build 100 to upstream 0.45.0/build 107 using a clean upstream base. The integration kept
the complete upstream feature set and ported only the fork behavior still needed.

Completed proof:

- Upstream base pinned at `2ccb4525687c92ff1cd50c8c57f24420c1fcb71f`.
- Validated fork head `bfaaa1bbc85e47da020f435b9b5f9e319d529f2d` pushed to `fork/main`.
- Pre-integration state preserved on `codex/pre-upstream-0.45-safety-20260718`.
- Full sharded suite passed 718 selections across 60 groups.
- SwiftFormat and SwiftLint passed with no issues.
- Independent review reported no findings.
- `/Applications/CodexBar.app` 0.45.0/build 107 passed code-sign, launch-at-login, widget refresh, and one quiet refresh
  interval.

See the [integration completion record](superpowers/specs/2026-07-18-upstream-0.45-fork-integration-design.md#completion-record).

## Current maintenance priorities

1. Keep the fork delta small and explicit.
2. Preserve passive, non-interactive Keychain behavior and no-rewrite cookie caching.
3. Preserve the compact Codex/Claude presentation and Claude fallback order with focused tests.
4. Review upstream releases from an exact pinned commit; do not merge a large update into `main` first.
5. Keep fork-only GitHub automation absent unless Nico explicitly approves restoring it.
6. Update active docs and the fork integration record whenever behavior or remote policy changes.

## Decision rule for new work

Keep a change in the fork when it is a personal presentation choice, local operational policy, or behavior upstream
has intentionally chosen differently. Prefer an upstream contribution when the fix is general, small, tested, and
does not depend on fork policy.

Do not restore removed Kimi K2 or CrossModel relay code without a new, evidence-backed decision. Do not add providers,
dependencies, account systems, or automation merely because an old roadmap listed them.

## Next upstream refresh definition of done

- A dated safety branch exists remotely before integration starts.
- The exact upstream commit and release/build are written down.
- Every retained fork behavior has a focused regression test.
- `make test`, `make check`, and `git diff --check` pass.
- A reviewer checks the full fork-only production diff.
- Bundle/runtime checks are run only when the changed behavior needs them.
- The integration branch is pushed before `fork/main` moves.
- Installation, login-item proof, and quiet runtime observation are completed only when installation is in scope.

## Related docs

- [Fork Quick Start](FORK_QUICK_START.md)
- [Fork Setup](FORK_SETUP.md)
- [Upstream Strategy](UPSTREAM_STRATEGY.md)
- [Development](DEVELOPMENT.md)
- [Keychain Current State](KEYCHAIN_FIX.md)
