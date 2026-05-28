---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1294-L1304
artifact: plan
round: 3
reviewer: spec-claude
---

T43's target files description and test expectations reference an "Anthropic SDK path" `transport_type:` value that does not exist in the plan's config schema. T01 defines exactly two legal `transport_type:` values: `openai-chat-completions` and `codex-broker`. No third value is defined anywhere in the plan.

The offending prose appears in T43's target files entry:

> when the configured provider's `transport_type:` is the Anthropic SDK path AND the provider's `supports_prompt_cache:` flag is true, insert a `cache_control: {"type": "ephemeral"}` marker

And in T43's test expectations:

> The marker insertion does not alter the request payload for providers using non-Anthropic transports (e.g., `openai-chat-completions` providers other than ones pinned to Anthropic-compatible endpoints)

Neither "Anthropic SDK path" nor any form like `transport_type: anthropic-sdk` is part of the schema T01 documents. An implementer reading T43 cannot resolve the condition "when `transport_type:` is the Anthropic SDK path" against the T01 schema because no such transport type exists.

The correct condition is already fully expressed in the plan: the `supports_prompt_cache:` flag in the provider's config entry is the capability gate for cache-control field emission (per T03's test expectations: "When `supports_prompt_cache: false`, the assembled request payload contains no `cache_control` fields; when `true`, the payload includes them"). T43's Path B contribution is specifically inserting the `cache_control` marker on the **stable-prefix message block** — a more precise placement than T03's general capability-gated emission — for providers whose `supports_prompt_cache:` is `true`.

**Resolution:** Replace the "Anthropic SDK path" transport-type language in T43's target files description and test expectations with the correct condition: `when the provider's `supports_prompt_cache:` flag is `true` (regardless of `transport_type:`). The test expectation that "non-Anthropic transports" are unaffected should instead read: "providers whose `supports_prompt_cache:` flag is `false` or absent are unaffected — no `cache_control` field appears in their request payloads." This aligns T43 with the T01-defined schema and eliminates the undefined transport-type reference that would block the implementer.
