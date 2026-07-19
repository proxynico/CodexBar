---
summary: "Nico fork upstream strategy: compare, integrate, validate, publish, and roll back."
read_when:
  - Checking for official upstream changes
  - Integrating a new upstream release
  - Preparing an upstream contribution
---

# Upstream strategy

## Repository roles

```text
origin  official upstream  https://github.com/steipete/CodexBar.git
fork    writable fork      https://github.com/proxynico/CodexBar.git
```

Local `main` tracks `fork/main`. Treat `origin` as read-only unless Nico explicitly asks for an upstream publication.

## Check for updates

```bash
git fetch origin --prune
git fetch fork --prune
git status --short --branch
git log --oneline --decorate fork/main..origin/main
git diff --stat fork/main..origin/main
```

Commit counts alone are not enough when the histories diverge. Record the upstream release, build number, and exact
commit that is being considered.

## Choose an integration method

### Small isolated change

Use a focused `codex/` branch. Inspect the whole commit, cherry-pick it, resolve against current fork policy, and run
the focused tests plus the full handoff gates.

### Large release jump

Use a clean upstream base. This was the successful 0.45 method and is the default recommendation:

```bash
(
  set -euo pipefail
  VERSION="0.46.0"                 # replace with the target version
  INTEGRATION_DATE="$(date +%Y%m%d)"
  PIN="0123456789abcdef"           # replace with the full upstream commit
  SAFETY_BRANCH="codex/pre-upstream-${VERSION}-safety-${INTEGRATION_DATE}"
  INTEGRATION_BRANCH="codex/upstream-${VERSION}-integration"
  INTEGRATION_DIR=".worktrees/upstream-${VERSION}"

  test -z "$(git status --porcelain)"
  git fetch origin --prune
  git fetch fork --prune
  test "$(git rev-parse main)" = "$(git rev-parse fork/main)"
  git branch "$SAFETY_BRANCH" fork/main
  git push fork "$SAFETY_BRANCH"
  git worktree add "$INTEGRATION_DIR" -b "$INTEGRATION_BRANCH" "$PIN"
)
```

Replace `VERSION` and `PIN`, then continue inside the resulting `.worktrees/upstream-${VERSION}` directory. The
fail-fast subshell stops without terminating the interactive shell if a precondition fails. The isolated worktree keeps the configured checkout
on `main` and prevents local files from following a branch switch onto the upstream base.

Port each surviving fork behavior as a focused commit. Do not copy the old fork wholesale, restore code removed
upstream, or carry obsolete test characterizations merely to reduce diff size.

For each port:

1. Add or update a focused regression test.
2. Run the narrow test.
3. Make the smallest production change.
4. Re-run the focused test.
5. Commit the focused behavior.

Keep fork GitHub workflows and bundled release skills absent. Preserve upstream architecture unless a documented fork
requirement needs a deliberate difference.

## Validation gates

Routine validation must not touch real provider sessions or show Keychain prompts.

```bash
make test
make check
git diff --check
PINNED_UPSTREAM_COMMIT="2ccb4525687c92ff1cd50c8c57f24420c1fcb71f"
git diff --stat "${PINNED_UPSTREAM_COMMIT}..HEAD"
```

Review every fork-only production change from the pinned upstream commit. Use
`./Scripts/compile_and_run.sh` only when UI or runtime behavior needs a fresh app bundle. Installation and live account
observation require explicit scope.

## Publish an integration

Push the reviewed integration branch first:

```bash
INTEGRATION_BRANCH="codex/upstream-0.45-integration"
git push -u fork "$INTEGRATION_BRANCH"
```

Move `fork/main` only after all required checks and any in-scope runtime proof pass. Keep the safety branch until the
new fork has been stable long enough to make rollback unnecessary.

## Rollback

Do not rewrite or delete the safety branch. If the new integration must be abandoned, create a recovery branch from
the safety ref, verify it, and move `fork/main` only with explicit approval. Preserve the failed integration branch
for diagnosis.

## Contribute a fix upstream

Start from the latest official upstream commit, not from fork `main`:

```bash
(
  set -euo pipefail
  TOPIC="short-topic"              # replace with the branch topic
  FIX_COMMIT="0123456789abcdef"    # replace with the general fix commit
  FIX_BRANCH="codex/upstream-fix-${TOPIC}"
  FIX_DIR=".worktrees/upstream-fix-${TOPIC}"

  git fetch origin --prune
  git worktree add "$FIX_DIR" -b "$FIX_BRANCH" origin/main
  cd "$FIX_DIR"
  git cherry-pick "$FIX_COMMIT"
  make test
  make check
  git diff --check
  git push -u fork "$FIX_BRANCH"
)
```

Before opening a PR, confirm the branch contains no fork-only presentation policy, credentials, local paths, release
configuration, or unrelated commits.

## Legacy scripts

The inherited `check_upstreams.sh`, `review_upstream.sh`, and `prepare_upstream_pr.sh` scripts use the older
`origin`-is-fork and `upstream`-is-official naming scheme. They can add or switch remotes and branches. Prefer the
commands above unless those scripts are first updated and tested against the current layout.

## 0.45 reference

- Upstream pin: `2ccb4525687c92ff1cd50c8c57f24420c1fcb71f`.
- Safety branch: `codex/pre-upstream-0.45-safety-20260718` at
  `9bbef21c877122f3e291128928781e3f3104eff0`.
- Validated fork head: `bfaaa1bbc85e47da020f435b9b5f9e319d529f2d`.
- Full record: [Upstream 0.45 Fork Integration Design](superpowers/specs/2026-07-18-upstream-0.45-fork-integration-design.md).
