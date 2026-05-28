---
finding_id: R1-F09
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T33's test expectation for byte-identical system-prompt prefix is not defined precisely enough to produce a deterministic test.

T33's second expectation: "Invoking scripts/g4-cache-probe.sh --report-out <path> dispatches exactly three reviewer prompts whose system-prompt prefix is byte-identical across the three calls."

This expectation requires defining what constitutes the "system-prompt prefix" vs. the "per-dispatch varying tail." Without this boundary being named, a test writer cannot assert byte-identity: they don't know where to split the prompt to check that the stable portion is identical and the varying portion differs.

Additionally, the design's spike contract (design.md lines 200–204) specifies: "Measurement criterion: across 3 reviewer dispatches with an identical system prefix, the response usage metadata is inspected for Anthropic cache-hit fields (cache_creation_input_tokens / cache_read_input_tokens)." But it doesn't say how the probe script constructs an "identical system prefix" — is it a fixed string, the reviewer-protocol SKILL.md body, or something else?

The expectation "byte-identical prefix" is load-bearing for the spike's validity — if the prefix varies, the cache-hit measurement is invalid. But without specifying what "prefix" means, the test cannot verify prefix stability. Add to T33's test expectations: a definition of what content constitutes the stable system-prompt prefix (e.g., the reviewer-protocol SKILL.md body plus a fixed preamble) and what constitutes the varying per-dispatch tail (e.g., the specific reviewer task body that changes per call), so the byte-identity assertion is specific and falsifiable.
