---
summary: "Nico fork setup: canonical remotes, branches, validation, and rollback."
read_when:
  - Setting up Nico's CodexBar checkout
  - Syncing with the official upstream
  - Recovering from an upstream integration
---

# Fork setup

## Canonical remotes

Nico's checkout deliberately names the official repository `origin` and the writable fork `fork`:

```bash
git remote set-url origin https://github.com/steipete/CodexBar.git
git remote add fork https://github.com/proxynico/CodexBar.git
git remote -v
```

If `fork` already exists, use `git remote set-url fork ...` instead of adding it. Expected output:

```text
fork    https://github.com/proxynico/CodexBar.git (fetch)
fork    https://github.com/proxynico/CodexBar.git (push)
origin  https://github.com/steipete/CodexBar.git (fetch)
origin  https://github.com/steipete/CodexBar.git (push)
```

The local `main` branch tracks `fork/main`:

```bash
git branch --set-upstream-to=fork/main main
```

## First verification

```bash
git fetch --all --prune
git status --short --branch
git branch -vv
git log -5 --oneline --decorate
```

For the completed 0.45 integration, `main` should descend from upstream commit
`2ccb4525687c92ff1cd50c8c57f24420c1fcb71f`. The recovery branch
`fork/codex/pre-upstream-0.45-safety-20260718` preserves the prior fork at
`9bbef21c877122f3e291128928781e3f3104eff0`.

## Normal change workflow

```bash
git switch -c codex/short-topic
# edit and run focused tests
make test
make check
git status --short
git diff --check
git push -u fork codex/short-topic
```

Do not run live provider probes, browser-cookie imports, real account usage commands, or ad hoc Security.framework
reads as routine validation. They can display macOS Keychain prompts. Use parser tests, stubs, test stores, and
`KeychainNoUIQuery` seams.

## Upstream refresh workflow

For small, isolated upstream changes, inspect the exact commits and cherry-pick only after checking conflicts with
fork behavior.

For a large release jump:

1. Require a clean working tree and verify local `main` equals the intended `fork/main` head.
2. Fetch and pin the exact upstream commit.
3. Push a dated safety branch from the verified `fork/main` ref.
4. Create an isolated worktree and `codex/upstream-<version>-integration` branch from the pinned upstream commit.
5. Port only the fork behavior that still matters, one focused change at a time, with focused tests.
6. Run `make test`, `make check`, and `git diff --check`.
7. Run `./Scripts/compile_and_run.sh` only if UI or bundle-runtime proof is required.
8. Review the entire fork-only diff from the pinned upstream commit.
9. Push the integration branch to `fork` before moving `fork/main`.
10. Install and observe the app only when Nico explicitly includes installation in scope.

The detailed policy and rollback commands are in [Upstream Strategy](UPSTREAM_STRATEGY.md).

## Legacy helper scripts

`Scripts/check_upstreams.sh`, `Scripts/review_upstream.sh`, and `Scripts/prepare_upstream_pr.sh` were inherited from an
older remote layout. They expect a remote named `upstream`; `prepare_upstream_pr.sh` also assumes `origin` is the
writable fork. That is not Nico's canonical layout. Prefer the direct Git commands in the current docs unless the
script has first been reviewed for the active remotes.

`Scripts/analyze_quotio.sh` is an optional research helper. Quotio is not part of the fork's source or sync chain.

## Automation policy

The fork intentionally does not carry upstream GitHub CI, release, or upstream-monitor workflows. Local validation
is the source of truth. Adding or restoring external automation requires explicit approval.

## Setup checklist

- [ ] `origin` points to `steipete/CodexBar`.
- [ ] `fork` points to `proxynico/CodexBar`.
- [ ] Local `main` tracks `fork/main`.
- [ ] `git fetch --all --prune` succeeds.
- [ ] `make test` and `make check` pass without live account or Keychain probes.
- [ ] The maintainer understands the safety-branch and clean-base integration workflow.
