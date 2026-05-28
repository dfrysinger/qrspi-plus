---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1301-L1304]
artifact: plan
round: 3
reviewer: test-coverage-claude
---

T43's primary happy-path test expectation (bullet 1) and its non-Anthropic exclusion (bullet 4) both use the phrase "Anthropic SDK path" and "Anthropic-compatible endpoints" as if these name a concrete `transport_type:` value in `config.md`, but neither term is defined anywhere in the plan or design.

**What the plan defines.** The plan (via T01/T03/design.md G2) defines exactly two `transport_type:` values: `codex-broker` and `openai-chat-completions`. There is no `transport_type: anthropic-sdk` or equivalent. The design's G2 section describes reaching Anthropic's API via the `openai-chat-completions` transport with a `base_url` pointing to Anthropic's endpoint — the same transport type used for DeepSeek, Mistral, and all other OpenAI-compatible providers.

**Why this matters for test authorship.** The Test skill generating acceptance tests for T43 cannot write a deterministic fixture because:

- Bullet 1 says `cache_control` markers are inserted for "any provider whose `transport_type:` is the Anthropic SDK path." No such `transport_type:` value exists. The implementer cannot construct a fixture `config.md` entry that exercises this condition.
- Bullet 4 says the insertion does NOT apply to "non-Anthropic transports (e.g., `openai-chat-completions` providers other than ones pinned to Anthropic-compatible endpoints)." This implies `openai-chat-completions` can be either Anthropic-path or non-Anthropic-path, suggesting the discriminator is NOT the `transport_type:` value but something else (perhaps a flag, perhaps the `base_url`, perhaps a new config field). That discriminator is never named.

**The vagueness produces two mutually-exclusive interpretations:**

1. T43 adds a NEW `transport_type:` value (e.g., `anthropic-sdk`) that the implementer must invent. If so, the plan needs to name it, the T01 schema documentation needs to list it, and the T03 dispatcher needs to handle a third branch.
2. T43 uses an observable property of `openai-chat-completions` providers (such as a `supports_prompt_cache: true` flag on an Anthropic-specific endpoint) as the discriminator, and the `transport_type:` is still `openai-chat-completions`. If so, the "Anthropic SDK path" phrase in bullet 1 is misleading — the actual test condition is `transport_type: openai-chat-completions AND supports_prompt_cache: true`, which is ALREADY covered by the capability-gate test in bullet 2. Under this reading, bullet 1 and bullet 2 together mean: `openai-chat-completions` + `supports_prompt_cache: true` → cache_control inserted; `openai-chat-completions` + `supports_prompt_cache: false` → not inserted. That is fully deterministic and testable, but bullet 1 would then be redundant with bullet 2.

**What the fix should accomplish.** The test expectation for bullet 1 should either:
- Name the concrete `transport_type:` value that identifies "the Anthropic SDK path" (if it is a new value), OR
- Replace "any provider whose `transport_type:` is the Anthropic SDK path" with the observable conditions that actually gate marker insertion — concretely, `transport_type: openai-chat-completions` + `supports_prompt_cache: true` is the most consistent reading of the T03 dispatcher contract. Bullet 4's "non-Anthropic transports" exclusion should be rewritten as "providers using `transport_type: codex-broker`" (the only other defined transport) or "providers using `openai-chat-completions` transport where `supports_prompt_cache:` is false or absent" — both are falsifiable conditions the test harness can set up deterministically.

The current language leaves the test writer unable to select the right fixture, because "Anthropic SDK path" maps to no observable property in the config schema the plan defines.
