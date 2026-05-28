---
round: 11
artifact: design
status: fixing
---

# Round 11 dispositions

## Findings inventory

- quality-claude: 1 finding (medium=1)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 1 finding (high=1)
- scope-codex: 0 findings (clean sentinel)

Total: 2 findings. Both accept.

## R11-F01 quality-codex (high) — accept

G4 says shell shims should put Anthropic `cache_control` markers into both Codex companion and future `scripts/run-third-party-llm.sh` request bodies. G2 defines `run-third-party-llm.sh` as generic OpenAI-compatible dispatcher across providers (DeepSeek, Mistral, Together, Fireworks, xAI, Groq, etc.). Anthropic `cache_control` is not portable; some OpenAI-compatible providers reject unknown fields.

**Fix:** Add provider capability flag in G1/G2/G4:
- `providers:` entries may carry `supports_prompt_cache: true|false` (default false).
- `run-third-party-llm.sh` omits cache metadata unless selected provider declares support.
- G4 shell-shim cache recommendation narrows explicit `cache_control` emission to provider transports that support it; otherwise stable-prefix composition still helps providers with automatic caching, but no provider-specific cache fields are emitted.
- Add a design-level test: provider with `supports_prompt_cache: false` produces no cache metadata; provider with true includes supported cache metadata.

## R11-F01 quality-claude (medium) — accept

Cross-cutting hygiene test strategy says G18 implementer self-check "rejects added lines" with release/stale tokens. G18 body says combined scan produces a report/hit; not clearly blocking. Align with advisory/reporting semantics, consistent with G7.

**Fix:** In cross-cutting "Hygiene contract (G7 + G18)", replace G18 "rejects added lines" wording with "reports added-line hits"; implementer must remove or acknowledge; BATS backstop enforces evergreen markdown in CI. This keeps self-check advisory, CI backstop blocking.

## Status

draft → fixing → re-review round 12.
