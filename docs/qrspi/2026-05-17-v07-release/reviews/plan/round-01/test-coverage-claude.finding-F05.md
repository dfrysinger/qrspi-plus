---
finding_id: R1-F05
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T36's test-cache-hit-rate.bats Path B expectations are too vague to produce a deterministic test.

The expectation reads: "on Path B it asserts both cache_control marker presence at the Anthropic SDK boundary and the same hit-rate assertion." The design (design.md lines 244–245) is similarly high-level about Path B: "add-cache-then-verify tests. Cache_control marker insertion at the Anthropic SDK boundary on stable prefixes, followed by the same hit-rate measurement as Path A after insertion."

"Cache_control marker presence at the Anthropic SDK boundary" is not specific:
- What constitutes "the Anthropic SDK boundary" in this shell-script project? The universal dispatcher script (T03) handles the HTTP call — is the "boundary" a specific JSON field in the request body?
- What is the expected value/structure of the cache_control field? The design says "Anthropic-style cache_control markers on stable prefixes" but doesn't give the field name, value type, or location in the request body that the test should assert.
- When Path B runs, which specific dispatch sites are expected to carry the cache_control field? "All sites" vs "flagged sites" is not defined.

Without these specifics, a test writer cannot produce a deterministic assertion. Two implementations — one that puts cache_control on the system message vs. one that puts it on the first user message — would both "pass" the vague expectation.

Add to T36's test expectations: the specific request-body field name and location the Path B test asserts (e.g., "the assembled JSON request body for the openai-chat-completions transport contains a cache_control field on the system message with value {type: ephemeral}"), and the specific dispatch sites or dispatch-site categories that are required to carry the field on Path B.
