---
summary: "Nico fork quick start: retained behavior, safe checks, and current Git workflow."
read_when:
  - Onboarding to Nico's CodexBar fork
  - Reviewing fork-specific behavior
  - Choosing build and test commands
---

# Nico fork quick start

This checkout is the [`proxynico/CodexBar`](https://github.com/proxynico/CodexBar) fork. The public upstream is
[`steipete/CodexBar`](https://github.com/steipete/CodexBar).

## Current baseline

- Fork branch: `main`, tracking `fork/main`.
- Upstream base: 0.45.0/build 107 at `2ccb4525687c92ff1cd50c8c57f24420c1fcb71f`.
- Validated integration head: `bfaaa1bbc85e47da020f435b9b5f9e319d529f2d`.
- Pre-integration safety branch: `codex/pre-upstream-0.45-safety-20260718` at
  `9bbef21c877122f3e291128928781e3f3104eff0`.
- Installed runtime target: `/Applications/CodexBar.app`.

Use Git and the installed app as live truth. These commit IDs are the 0.45 integration record, not a promise that the
fork will stay at those commits.

## Retained fork behavior

- Codex cards hide additional quota rows, credit balances, and buy-credit actions.
- Claude hides only the routines row. Other model-specific limits remain visible.
- An exhausted Claude extra-usage cap becomes the primary blocking window.
- Claude Auto mode uses OAuth, web, then CLI. Normal web failures may fall through to CLI; cancellation does not.
- CLI enrichment reuses an existing manual Claude web session and does not start browser-cookie discovery merely to
  add extras.
- Passive Security.framework reads are non-interactive. Keychain UI denial is treated as unavailable data.
- Unchanged cookie-cache refreshes retain the stored entry and avoid a Keychain write.
- Deprecated trusted-application ACL attachment is not used for cache writes.
- Status-item observation changes only at the same value buckets that can change the rendered icon.
- Kimi K2 and CrossModel stay removed, matching upstream 0.45.
- Fork GitHub CI/release/upstream-monitor workflows and bundled release agent skills stay absent.

## Development commands

Use the narrowest check that proves the change:

```bash
swift test --filter ClaudeSourcePlannerTests
make test
make check
```

`make test` is the required full sharded test gate before handoff. Run `make check` after code changes. These tests use
stubs and test stores; do not replace them with live provider probes or real Keychain reads.

Build the bundle only when UI or runtime behavior needs it:

```bash
./Scripts/compile_and_run.sh
```

That script kills old instances, builds, packages, signs, relaunches the repo-local `CodexBar.app`, and checks that it
stays running. Add `--test` only when a bundle-level validation also needs the full suite.

To relaunch an already packaged repo-local bundle:

```bash
pkill -x CodexBar || pkill -f CodexBar.app || true
cd /Users/nicolasmontero/Developer/tools/codexbar
open -n /Users/nicolasmontero/Developer/tools/codexbar/CodexBar.app
```

Do not treat the repo-local bundle as proof of the installed app. Verify `/Applications/CodexBar.app` separately when
installation or login-at-startup behavior is in scope.

## Git workflow

The canonical remotes in Nico's checkout are:

```text
origin  https://github.com/steipete/CodexBar.git
fork    https://github.com/proxynico/CodexBar.git
```

Create work on a `codex/` branch and push it to `fork`. Do not push to `origin` unless Nico explicitly asks to publish
an upstream contribution.

For an upstream refresh, use the clean-base port strategy in [Upstream Strategy](UPSTREAM_STRATEGY.md). Do not assume
a large upstream move is a safe merge or rebase.

## Key docs

- [Development](DEVELOPMENT.md)
- [Development setup and signing](DEVELOPMENT_SETUP.md)
- [Fork setup](FORK_SETUP.md)
- [Upstream strategy](UPSTREAM_STRATEGY.md)
- [Keychain prompt troubleshooting](keychain-prompts.md)
- [Current Keychain architecture](KEYCHAIN_FIX.md)
- [Release policy](RELEASING.md)
- [0.45 integration record](superpowers/specs/2026-07-18-upstream-0.45-fork-integration-design.md)
