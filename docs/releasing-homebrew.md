---
summary: "Official-upstream Homebrew release reference; disabled for Nico's fork."
read_when:
  - Reviewing the official CodexBar Homebrew release path
  - Deciding whether to create a separate fork release channel
---

# Homebrew release reference

> [!WARNING]
> Authorized official-upstream release only. Nico's fork is not configured to publish GitHub, Sparkle, Homebrew Cask,
> or CLI formula releases. The upstream `.github/workflows/release-cli.yml` workflow is intentionally absent here.

Homebrew installs the UI app through a Cask. Those builds disable Sparkle and show an "update via brew" hint in
About. The official project also publishes a standalone CLI formula.

## Current fork state

- `.mac-release.env` targets `steipete/CodexBar` and the official appcast.
- The release CLI workflow that builds assets and dispatches `steipete/homebrew-tap` is not present in this fork.
- Normal fork work stops at `./Scripts/package_app.sh` unless Nico explicitly authorizes a separate publication
  project.

Do not edit or push `steipete/homebrew-tap` from this checkout.

## Official-upstream reference

In the authorized official flow, the release workflow publishes the universal app zip and platform CLI tarballs,
then updates:

- `Casks/codexbar.rb` with the app zip URL and SHA-256.
- `Formula/codexbar.rb` with macOS and glibc Linux CLI tarball URLs and SHA-256 values.

Static musl CLI tarballs are release assets but are not the default Homebrew Linux runtime contract.

Official verification includes reinstalling `steipete/tap/codexbar`, checking the app signature and version, and
verifying that every referenced release asset exists. Those steps are external publication checks, not fork
development validation.

## Enabling a fork Homebrew channel

A future fork channel needs explicit choices for repository, release assets, app bundle identity, signing team,
Sparkle behavior, tap ownership, formula/cask names, update automation, and rollback. Follow
[RELEASING.md](RELEASING.md#enabling-a-future-fork-release); do not reuse official credentials or endpoints by
default.
