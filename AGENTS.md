# Repository Guidelines

## Project Structure & Modules
- `Sources/CodexBar`: Swift 6 menu bar app (usage/credits probes, icon renderer, settings). Keep changes small and reuse existing helpers.
- `Tests/CodexBarTests`: XCTest coverage for usage parsing, status probes, icon patterns; mirror new logic with focused tests.
- `Scripts`: build/package helpers (`package_app.sh`, `sign-and-notarize.sh`, `make_appcast.sh`, `build_icon.sh`, `compile_and_run.sh`).
- `docs`: release notes and process (`docs/RELEASING.md`, screenshots). Root-level zips/appcast are generated artifacts—avoid editing except during releases.

## Build, Test, Run
- Dev loop: `./Scripts/compile_and_run.sh --test --wait` serializes with other agents, kills old instances, runs tests, packages, relaunches `CodexBar.app`, and confirms it stays running. Without `--test`, it skips `swift test`.
- Quick build/test: `swift build` (debug) or `swift build -c release`; `make test` for the sharded full suite, or `swift test` for direct SwiftPM runs.
- Package locally: `./Scripts/package_app.sh` refreshes repo-local `CodexBar.app`; restart it with `pkill -x CodexBar || pkill -f CodexBar.app || true; open -n /Users/nicolasmontero/Developer/tools/codexbar/CodexBar.app`.
- Install to `/Applications` only after validating the repo-local bundle: `rm -rf /Applications/CodexBar.app && ditto CodexBar.app /Applications/CodexBar.app && open /Applications/CodexBar.app`.
- Release flow: `./Scripts/release.sh` for upstream-style releases, or `./Scripts/sign-and-notarize.sh` plus `./Scripts/make_appcast.sh <zip> <feed-url>` for the local notarized path; follow validation steps in `docs/RELEASING.md`.

## Coding Style & Naming
- Enforce SwiftFormat/SwiftLint: run `swiftformat Sources Tests` and `swiftlint --strict`. 4-space indent, 120-char lines, explicit `self` is intentional—do not remove.
- Favor small, typed structs/enums; maintain existing `MARK` organization. Use descriptive symbols; match current commit tone.

## Testing Guidelines
- Add/extend XCTest cases under `Tests/CodexBarTests/*Tests.swift` (`FeatureNameTests` with `test_caseDescription` methods).
- Swift Testing: prefer backticked sentence names; no camelCase.
- Model names in tests/code: released models or clearly fictitious names only; never expose unreleased names.
- Always run `swift test` (or preferably `./Scripts/compile_and_run.sh --test --wait`) before handoff; add focused `swift test --filter ...` runs and fixtures for parser/provider fixes when possible.
- After any code change, run `make check` and fix all reported format/lint issues before handoff.
- Prefer CLI/focused tests over app-bundle live tests when behavior can be verified without relaunching CodexBar.
- Never run tests/checks or ad-hoc validation that can display macOS Keychain prompts. Live provider probes, browser-cookie imports, `codexbar usage` against real accounts, and real SecItem reads must be explicitly requested; otherwise use parser tests, stubs, test stores, or `KeychainNoUIQuery`.
- macOS CI is brittle around headless AppKit status/menu tests. Prefer covering menu behavior through stable state/model seams (`MenuDescriptor`, `ProvidersPane`, `CodexAccountsSectionState`, etc.) instead of constructing live `NSStatusBar`/`NSMenu` flows unless the AppKit wiring itself is the thing under test.

## Commit & PR Guidelines
- Commit messages: short imperative clauses (e.g., “Improve usage probe”, “Fix icon dimming”); keep commits scoped.
- PRs/patches should list summary, commands run, screenshots/GIFs for UI changes, and linked issue/reference when relevant.

## Agent Notes
- Use the provided scripts and package manager (SwiftPM); avoid adding dependencies or tooling without confirmation.
- Validate behavior against the freshly built bundle; restart via the pkill+open command above to avoid running stale binaries.
- To guarantee the right repo-local bundle is running after a rebuild, use: `pkill -x CodexBar || pkill -f CodexBar.app || true; open -n /Users/nicolasmontero/Developer/tools/codexbar/CodexBar.app`.
- After any code change that affects the app, always rebuild with `./Scripts/package_app.sh` and restart the app using the command above before validating behavior.
- If you edited code, run `./Scripts/compile_and_run.sh --test --wait` before handoff; it kills old instances, tests, packages, relaunches, and verifies the app stays running.
- Per user request: after every edit (code or docs), rebuild and restart using `./Scripts/compile_and_run.sh --wait` so the running app reflects the latest changes.
- If `/Applications/CodexBar.app` is the target install, do not assume repo-local launch success means the installed app is good; copy with `ditto`, launch `/Applications/CodexBar.app`, verify its PID path, version/build, and codesign. If `open` claims success but no process stays up, run `/Applications/CodexBar.app/Contents/MacOS/CodexBar` directly and inspect stderr.
- Menu bar automation: capture the target screen first and verify the CodexBar icon is visibly onscreen. Reject `click-extra` success when coordinates fall outside display bounds; hidden menu extras are not click proof.
- For CLI-testable provider/parser/settings behavior, use CLI/focused tests instead of app-bundle live tests.
- Release script: keep it in the foreground; do not background it—wait until it finishes.
- Local signing: do not use `APP_IDENTITY=CodexBar Development` for bundled app validation; it can produce Sparkle framework library-validation failures (`different Team IDs`) even when `codesign --verify --deep --strict` passes. Prefer adhoc signing for local builds unless a real Developer ID identity is installed. If the app does not launch, run the binary directly and check stderr for `dyld` framework/signing errors.
- Full Disk Access/TCC: adhoc-signed local builds can invalidate existing Full Disk Access grants after rebuild/reinstall because the code identity changes. If Safari cookie reads fail despite Full Disk Access, reset/re-add the exact running app (`/Applications/CodexBar.app` or repo-local `CodexBar.app`) in System Settings, relaunch, and verify the PID path. Do not trust `codesign --verify` alone for TCC health.
- Release keys: find in `~/.profile` if missing (Sparkle + App Store Connect).
- Sparkle release key: use `.mac-release.env` `MAC_RELEASE_SIGNING_KEY_FILE`, the legacy `AGCY8w5vHirVfGGDGc8Szc5iuOqupZSh9pMj/Qs67XI=` key. Do not use `sparkle-private-key-KEEP-SECURE.txt`; that is VibeTunnel's mismatched key.
- Swift concurrency: treat sibling `async let` tasks as a review red flag when one child is required and another is optional/best-effort. Prefer sequential awaits or a drained `withThrowingTaskGroup` that surfaces required failures and explicitly contains optional failures; crash stacks mentioning `swift_task_dealloc` or `asyncLet_finish_after_task_completion` should trigger an audit of nearby `async let` usage.
- Prefer modern SwiftUI/Observation macros: use `@Observable` models with `@State` ownership and `@Bindable` in views; avoid `ObservableObject`, `@ObservedObject`, and `@StateObject`.
- Favor modern macOS 15+ APIs over legacy/deprecated counterparts when refactoring (Observation, new display link APIs, updated menu item styling, etc.).
- Keep provider data siloed: when rendering usage or account info for a provider (Claude vs Codex), never display identity/plan fields sourced from a different provider.
- Claude CLI status line is custom + user-configurable; never rely on it for usage parsing.
- Cookie imports: default Chrome-only when possible to avoid other browser prompts; override via browser list when needed.
