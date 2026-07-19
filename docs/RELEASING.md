---
summary: "Release policy for Nico's fork, local packaging, and the guarded official release path."
read_when:
  - Packaging or installing a local CodexBar build
  - Considering a fork release
  - Reviewing the inherited official release scripts
---

# Release and installation policy

## Current fork policy

This checkout is not configured to publish a `proxynico/CodexBar` release.

The inherited `.mac-release.env` still targets:

- Repository: `steipete/CodexBar`.
- Sparkle feed: `https://raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml`.
- Download prefix: official `steipete/CodexBar` GitHub releases.
- Bundle identifier: `com.steipete.codexbar`.
- Official Developer ID identity and App Store Connect credentials.

The fork also intentionally removes the upstream GitHub CI and release workflows. Therefore:

> Do not run `./Scripts/release.sh` from this fork. It is an external publication command configured for the official
> upstream repository, not a local packaging helper.

Publishing a fork release requires a separate, explicit decision and configuration pass. Local packaging or
installation does not authorize tags, GitHub releases, appcast changes, Homebrew updates, or upstream writes.

## Required local gates

Before handing off code or packaging an in-scope runtime build:

```bash
make test
make check
git diff --check
```

Use fixtures, stubs, and test stores. Do not add live provider or Keychain probes to release validation unless Nico
explicitly requests that live check.

## Package a local bundle

```bash
./Scripts/package_app.sh
codesign --verify --deep --strict --verbose=2 CodexBar.app
```

For a UI/runtime development loop, use:

```bash
./Scripts/compile_and_run.sh
```

The script packages and launches the repo-local bundle. It does not update `/Applications/CodexBar.app`.

## Install a validated local build

Replacing `/Applications/CodexBar.app` changes the app used by Login Items and must be in the approved task scope.
Keep a recoverable copy of the existing app before replacement.

After an approved install, verify:

```bash
defaults read /Applications/CodexBar.app/Contents/Info.plist CFBundleShortVersionString
defaults read /Applications/CodexBar.app/Contents/Info.plist CFBundleVersion
codesign --verify --deep --strict --verbose=2 /Applications/CodexBar.app
pgrep -fl '/Applications/CodexBar.app/Contents/MacOS/CodexBar'
```

When login-at-startup or widgets are in scope, also verify the login item points at `/Applications/CodexBar.app` and
that the app-group `widget-snapshot.json` refreshes after launch. Use `/usr/bin/log` for runtime log queries to avoid a
zsh `log` function collision.

## Official upstream release path

The repository retains upstream packaging, signing, notarization, Sparkle, and appcast scripts because the source is
based on the official project. They are only for an authorized official-upstream release context.

Main entry points:

- `Scripts/sign-and-notarize.sh`: universal build, Developer ID signing, notarization, staple, and zip.
- `Scripts/make_appcast.sh`: Sparkle signature and appcast entry.
- `Scripts/release.sh`: end-to-end external release orchestration.
- `Scripts/mac-release`: resolves the shared release helper.

The official flow requires Xcode 26+, SwiftFormat, SwiftLint, Swift, Sparkle tools, `gh`, Python, zip/curl, the official
Developer ID certificate, App Store Connect credentials, and the matching Sparkle private key.

The CodexBar Sparkle public key is the legacy AGCY key configured in `.mac-release.env`. Do not substitute
`sparkle-private-key-KEEP-SECURE.txt`; that file belongs to another app and does not match CodexBar's public key.

For an authorized official release, the definition of done remains:

- Version and changelog are finalized and sequential.
- `make test`, `make check`, and release prechecks pass.
- Universal app and dSYM archives are signed, notarized, stapled, and uploaded.
- Appcast signature, size, notes, and enclosure URL are verified.
- The enclosure responds successfully after publication.
- GitHub release assets and any required CLI assets are complete.
- Homebrew/Appcast update behavior is proved from a previous signed build.

The current fork cannot satisfy that definition without restoring and reviewing its publication configuration and
external workflows.

## Enabling a future fork release

Before any fork publication:

1. Choose the fork's bundle ID, signing team, release repository, feed URL, download prefix, Sparkle key pair, and
   Homebrew policy.
2. Update `.mac-release.env` without reusing the official private credentials.
3. Decide whether fork releases should update the official bundle in place or install as a separate app.
4. Restore only the required workflows and review their permissions.
5. Test the complete release flow against a non-production prerelease.
6. Document rollback, key custody, and asset verification.

Do not infer these choices from the current upstream values.
