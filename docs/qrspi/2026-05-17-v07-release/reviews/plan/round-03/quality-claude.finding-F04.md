---
finding_id: R3-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1102-L1113]
artifact: plan
round: 3
reviewer: quality-claude
---

T36's `test-cache-hit-rate.bats` test expectation at the Slice 7 pin section states: "Path B asserts the `cache_control` field appears on the system message of the assembled JSON request body for the `openai-chat-completions` transport." However, design.md's G4 section makes clear that cache_control markers are specifically for the Anthropic SDK path, NOT for generic openai-chat-completions providers. T43's description explicitly states "The marker insertion does not alter the request payload for providers using non-Anthropic transports (e.g., `openai-chat-completions` providers other than ones pinned to Anthropic-compatible endpoints)." This is a contradiction: T36 says the Path B fixture asserts cache_control on the `openai-chat-completions` transport, but T43 says cache_control must NOT appear on non-Anthropic openai-chat-completions providers. The T36 test expectation bullet should reference the Anthropic-SDK-path transport (i.e., providers with `supports_prompt_cache: true` that are using the Anthropic-native path), not the generic `openai-chat-completions` transport label, since many openai-chat-completions providers explicitly reject cache_control fields. The fix is to replace "openai-chat-completions transport" with "Anthropic-compatible provider with `supports_prompt_cache: true`" (or equivalent language matching T43's description) in the T36 test expectation bullet.
