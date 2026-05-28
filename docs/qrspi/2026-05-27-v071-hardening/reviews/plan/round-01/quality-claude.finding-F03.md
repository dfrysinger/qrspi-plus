---
finding_id: R1-F03
severity: medium
change_type: modified
artifact: plan
round: 1
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
  - docs/qrspi/2026-05-27-v071-hardening/research/summary.md
---

# R1-F03: Task 10 omits concrete model identifiers for the `model_routing` table — Plan is the designated owner

## Location

`plan.md` → Task 10, Description paragraph and Test Expectations.

## Observation

`design.md` DKR9 states:

> Per-host concrete-model resolution lives in `config.md`'s existing `model_routing:` table.

And in the same DKR:

> the concrete model identifiers Plan writes into the `model_routing:` table are owned downstream.

"Owned downstream" is design's terminology for responsibility delegated to Plan — it means Plan is the artifact that should specify the actual values.

Task 10's description uses only qualitative language:

> The copilot-cli entries use fully-versioned Copilot-native model identifiers that do not trigger "model not available" warnings; the claude-code entries use the corresponding Anthropic versioned identifiers.

And similarly in DKR7:

> The concrete Copilot-CLI model identifier (`gpt-5.3-codex`) is the one named in `goals.md` G6 (per `research/q12-web.md`'s scan of the Copilot agents corpus); the exact value Plan writes into `config.md`'s `model_routing:` table is owned downstream.

The task description never states which model IDs to write. The implementer reading Task 10 must independently research what "fully-versioned Copilot-native model identifiers" to use for `haiku`, `sonnet`, and `opus` tiers — exactly the work the design designated as Plan's responsibility to complete.

The research provides sufficient information to anchor these values:
- `research/summary.md` Q12 shows `gentle-ai`'s mapping: `haiku → claude-haiku-4.5`, `sonnet → claude-sonnet-4.6`, `opus → claude-opus-4.6` for claude-code-compatible tiers
- `goals.md` G6 names `gpt-5.3-codex` for Copilot CLI Codex dispatches (though this is for the Codex slot, not the tier-vocabulary mapping)
- For the Copilot CLI `haiku`/`sonnet`/`opus` tier entries, the research does not specify a definitive mapping — this is precisely the gap the plan should fill but doesn't

## Why it matters

An implementer executing Task 10 without specific model IDs will make an arbitrary choice or guess, producing entries that may or may not avoid the "model not available" warnings that G7b exists to fix. If the wrong identifiers are used, the phase acceptance criterion ("zero 'model not available' warnings across a full pipeline run") will fail.

The test expectation "No entry in the copilot-cli column of the model_routing: table is a bare Claude tier short-form" does constrain the wrong values but does not guide the implementer toward the correct values. A test that rules out bad values is not a substitute for a spec that names the right values.

## Suggested resolution

Task 10 description should name the specific concrete model IDs for each of the six `model_routing` cells (3 tiers × 2 hosts). Based on the research available at design time:

- **claude-code:** `haiku → claude-haiku-4.5`, `sonnet → claude-sonnet-4.6`, `opus → claude-opus-4.6` (per Q12 `gentle-ai` mapping, the closest multi-host precedent)
- **copilot-cli:** specific versioned Copilot-native model identifiers for each tier should be named or, if not determinable from the research, a research gap should be called out explicitly (e.g., "implementer must verify current Copilot CLI model availability before populating these entries")

If the correct copilot-cli tier mappings are unknown at plan time, Task 10 should include an explicit pre-implementation probe step rather than leaving the gap implicit.
