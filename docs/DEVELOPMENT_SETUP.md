---
summary: "Development setup: safe validation, stable signing, and bundle relaunch."
read_when:
  - Setting up local development
  - Choosing tests versus bundle validation
  - Reducing Keychain prompts during rebuilds
---

# Development setup

## Requirements

- macOS 14 or newer.
- Swift 6.2 or newer from Xcode.
- SwiftFormat and SwiftLint for `make check`.
- The existing SwiftPM checkout; do not add another package manager.

## Safe default workflow

Most provider, parser, settings, and storage changes do not need an app rebuild:

```bash
swift test --filter ClaudeSourcePlannerTests
make test
make check
```

`make test` is the required full sharded suite before handoff. Run `make check` after every code change. Do not run
live provider probes, browser-cookie imports, `codexbar usage` against real accounts, or ad hoc real Keychain reads as
routine validation. Use fixtures, stubs, test stores, and `KeychainNoUIQuery`.

## Bundle workflow

Run the bundle loop only when UI, AppKit wiring, packaging, signing, launch, widgets, or runtime behavior needs proof:

```bash
./Scripts/compile_and_run.sh
```

The script:

1. Prevents concurrent runs for the same checkout.
2. Quits every process named `CodexBar` or matching a CodexBar app/debug/release executable, including an installed
   `/Applications/CodexBar.app`, and cleans up orphaned Claude probe processes.
3. Builds and packages `CodexBar.app`.
4. Uses a valid installed code-signing identity when one is available, otherwise falls back to ad hoc signing.
5. Launches the repo-local app and confirms it stays running.

Pass `--test` only when the bundle-level check also needs the full sharded suite. Pass `--wait` when another
`compile_and_run.sh` process holds this checkout's wrapper lock. It does not coordinate arbitrary SwiftPM commands;
do not start competing `swift build` or `swift test` processes against the same `.build` directory.

## Signing

Do not configure `APP_IDENTITY='CodexBar Development'`. That old self-signed identity is not usable with the bundled
framework library-validation path. `compile_and_run.sh` deliberately ignores it and looks for a valid installed
Developer ID, Apple Development, or Apple Distribution identity.

Usually no environment override is needed. To use a specific installed identity:

```bash
security find-identity -p codesigning -v
export APP_IDENTITY='Apple Development: Your Name (TEAMID)'
./Scripts/compile_and_run.sh
```

If the named identity is missing, the script warns, continues identity discovery, and uses ad hoc signing only when
no valid identity exists.

An unbundled SwiftPM executable has Keychain access disabled by design. Use the packaged app only when an explicitly
approved runtime check needs browser cookies or stored credentials.

## Relaunch the correct local bundle

```bash
./Scripts/package_app.sh
pkill -x CodexBar || pkill -f CodexBar.app || true
cd /Users/nicolasmontero/Developer/tools/codexbar
open -n /Users/nicolasmontero/Developer/tools/codexbar/CodexBar.app
```

This launches the repo-local bundle. It does not replace `/Applications/CodexBar.app`. When installed-app behavior is
in scope, verify the running executable path and installed Info.plist separately.

## Ad hoc signing and Keychain state

Ad hoc builds have an unstable app identity and can cause macOS authorization churn. The build script preserves
CodexBar-owned Keychain state by default; it does not promise that third-party Keychain items will remain prompt-free.

Use the destructive reset flag only when intentionally testing a clean CodexBar-owned cache:

```bash
./Scripts/compile_and_run.sh --clear-adhoc-keychain
```

Do not use that flag during ordinary validation.

## Common commands

```bash
swift build                         # debug build
swift build -c release              # release build
swift test --filter ClaudeSourcePlannerTests  # focused test example
make test                           # full sharded suite
make check                          # format and lint gate
./Scripts/package_app.sh            # package without relaunch
./Scripts/launch.sh                 # launch existing repo-local bundle
```

## Troubleshooting

### The app is already running

```bash
pkill -x CodexBar || pkill -f CodexBar.app || true
```

Then rerun `./Scripts/compile_and_run.sh`.

### The app does not reflect the latest code

Confirm the active process path:

```bash
pgrep -fl 'CodexBar.app/Contents/MacOS/CodexBar'
```

Quit all copies, package again, and launch the absolute repo-local path above.

### Keychain prompts appear

Stop the live probe first. Confirm which app or binary the macOS prompt names, then follow
[Keychain prompt troubleshooting](keychain-prompts.md). Routine tests should not display a Keychain prompt.

### A build is already in progress

Do not start a second SwiftPM test/build against the same `.build` directory. Wait for a standalone `swift build` or
`swift test` command to finish. Use `./Scripts/compile_and_run.sh --wait` only when another instance of that wrapper
holds its checkout-specific lock.

### Reset the legacy migration flag

Only for a targeted migration test:

```bash
defaults delete com.steipete.codexbar KeychainMigrationV1Completed
```

This can change runtime behavior on the next launch. It is not a routine repair step.
