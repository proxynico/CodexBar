---
summary: "Current Claude runtime, source planning, Keychain, token-account, and enrichment behavior."
read_when:
  - Changing Claude runtime/source selection
  - Changing Claude OAuth prompt or cooldown behavior
  - Changing Claude token-account routing
  - Reviewing Claude web enrichment
---

# Claude current baseline

Current code and characterization tests are authoritative. This file is the human-readable parity contract for the
active implementation.

## Behavior owners

- `ClaudeSourcePlanner.swift` owns ordered source selection and plausible-availability diagnostics.
- `ClaudeProviderDescriptor.swift` converts the plan into the generic provider pipeline and controls strategy
  fallback.
- `ClaudeUsageFetcher.swift` executes planned steps, maps snapshots, applies cost/model enrichment, and promotes an
  exhausted spend cap.
- `ClaudeOAuth/*` owns credential loading, refresh ownership, prompt policy, and cooldown behavior.
- `ClaudeSettingsStore.swift` and `TokenAccountCLI.swift` route app and CLI token-account inputs.

## Runtime and source selection

| Runtime | Selected mode | Ordered attempts | Fallback |
| --- | --- | --- | --- |
| app | auto | `oauth -> web -> cli` | OAuth and ordinary web errors may continue; cancellation is terminal; CLI is final. |
| app | oauth | `oauth` | None. |
| app | web | `web` | None. |
| app | cli | `cli` | None. |
| cli | auto | `web -> cli` | Web may continue to CLI; CLI is final. |
| cli | oauth | `oauth` | None. |
| cli | web | `web` | None. |
| cli | cli | `cli` | None. |

Explicit modes execute their selected strategy even when the planner's availability probe cannot prove that source is
available. Auto records every planned step for diagnostics and lets each strategy decide actual availability.

App Auto separates two web concepts:

- A **plausible web session** can include the web step without importing cookies during planning.
- A **reusable web session** allows CLI result enrichment. In Auto mode this is limited to an already configured
  manual session, so reaching CLI does not trigger browser-cookie discovery merely to add model limits.

## Prompt and cooldown behavior

- Default Claude Keychain prompt mode is `onlyOnUserAction`.
- Passive availability, background refresh, and cache reads use non-interactive Security.framework queries.
- `never` blocks prompt-capable delegated refresh.
- `onlyOnUserAction` reserves interactive repair for an explicit user action, except the narrowly defined startup
  bootstrap path retained by upstream 0.45.
- User interaction can clear a prior denial cooldown before a requested retry.
- Background delegated refresh is blocked when the active prompt policy does not allow it.
- Claude CLI-owned expired credentials use delegated refresh; CodexBar-owned credentials use direct refresh;
  environment-owned credentials do not auto-refresh.

Task-local prompt and Security CLI overrides must propagate into detached delegated-refresh work in tests. Tests must
never depend on the machine's stored prompt preference or real Keychain.

## Token-account routing

Accepted inputs:

- OAuth access token with `sk-ant-oat...`, with or without `Bearer`.
- Raw `sessionKey` value.
- Full Cookie header.

OAuth-shaped values route to OAuth and are never treated as cookies. Session-key and Cookie values route to manual
web mode. CLI token-account OAuth input changes effective Auto source to OAuth and injects
`CODEXBAR_CLAUDE_OAUTH_TOKEN`; cookie-shaped input stays manual-web scoped.

## Web fallback and enrichment

- Normal web fetch errors in Auto mode may reach CLI in app and CLI runtimes.
- Cancellation never falls through.
- Web enrichment must not replace primary `accountEmail`, `accountOrganization`, or `loginMethod`.
- An existing manual web session can add model-scoped windows that the CLI does not expose.
- The Claude routines row remains in snapshot data but is hidden from this fork's menu card.
- If extra-usage spend is at or above its cap, the spend-limit window becomes primary and blocking for OAuth, web,
  and enriched CLI results.

## Characterization coverage

The main contract is covered by:

- `ClaudeBaselineCharacterizationTests.swift`
- `ClaudeSourcePlannerTests.swift`
- `ClaudeUsageTests.swift`
- `ClaudeWebFetchDeadlineTests.swift`
- `ClaudeOAuthDelegatedRefreshRecoveryTests.swift`
- `ClaudeOAuthCredentialsStoreTests.swift`
- `CLIWebFallbackTests.swift`

All tests must use stubs, isolated credential files, task overrides, and test Keychain stores.

## Related docs

- [Claude provider](../claude.md)
- [Keychain current state](../KEYCHAIN_FIX.md)
- [0.45 integration design](../superpowers/specs/2026-07-18-upstream-0.45-fork-integration-design.md)
- [Claude provider vNext historical plan](claude-provider-vnext-locked.md)
