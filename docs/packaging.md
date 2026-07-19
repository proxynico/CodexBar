---
summary: "Packaging, signing, and bundled CLI notes."
read_when:
  - Packaging/signing builds
  - Updating bundle layout or CLI bundling
---

# Packaging & signing

> [!WARNING]
> `package_app.sh` and `compile_and_run.sh` are local development tools. `sign-and-notarize.sh` and
> `make_appcast.sh` belong to the authorized official-upstream release path; this fork's `.mac-release.env` targets
> `steipete/CodexBar`. Do not run release signing, appcast, tag, or upload work for normal fork packaging. See
> [RELEASING.md](RELEASING.md).

## Scripts
- `Scripts/package_app.sh`: builds host arch with ad-hoc signing by default; set `ARCHES="arm64 x86_64"` for universal. Verifies slices. Stable-certificate packaging requires explicit `CODEXBAR_SIGNING=identity` plus `APP_IDENTITY`.
- `Scripts/compile_and_run.sh`: uses host arch; pass `--release-universal` or `--release-arches="arm64 x86_64"` for release packaging.
- `Scripts/sign-and-notarize.sh`: explicitly selects Developer ID signing, notarizes, staples, and zips (accepts `ARCHES` for universal).
- `Scripts/make_appcast.sh`: wrapper around the shared `mac-release make-appcast` helper; app metadata comes from `.mac-release.env`.
- `Scripts/changelog-to-html.sh`: converts the per-version changelog section to HTML for Sparkle.

## Bundle contents
- `CodexBarWidget.appex` is built by `WidgetExtension/CodexBarWidgetExtension.xcodeproj` as a real macOS app extension, then bundled with app-group entitlements.
- `CodexBarCLI` copied to `CodexBar.app/Contents/Helpers/` for symlinking.
- SwiftPM resource bundles (e.g. `KeyboardShortcuts_KeyboardShortcuts.bundle`) copied into `Contents/Resources` (required for `KeyboardShortcuts.Recorder`).

## Releases
- Fork release policy and the guarded official checklist are in [RELEASING.md](RELEASING.md).

See also: `docs/sparkle.md`.
