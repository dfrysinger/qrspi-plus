---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1105]
artifact: plan
round: 4
reviewer: quality-claude
---

T36's first target-file bullet (the description for `tests/unit/test-cache-hit-rate.bats`) at line 1105 still reads: "Path B produces add-then-verify assertions (cache_control markers are present **at the Anthropic SDK boundary** AND the hit-rate assertion holds after insertion)."

The phrase "at the Anthropic SDK boundary" is the residue the round-3 R3-F04 fix was meant to eliminate. R3-F04 correctly updated the T36 test expectations section (now at line 1114) to instead say "ONLY for providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true`" — that language is correct. However, the corresponding target-file bullet at line 1105 was not updated and still uses the rejected "Anthropic SDK boundary" characterization.

The characterization is wrong for the same reason R3-F04 flagged it: the dual-flag gate (`supports_prompt_cache: true` AND `emit_cache_control_markers: true`) governs `cache_control` emission for any provider, not only Anthropic-compatible endpoints. Characterizing the test as asserting "cache_control markers are present at the Anthropic SDK boundary" is misleading — the T03 dispatcher gates emission on the two config flags regardless of which provider is being called, as T43 explicitly states: "The marker insertion does not alter the request payload for providers using non-Anthropic transports."

Fix: replace "cache_control markers are present at the Anthropic SDK boundary AND the hit-rate assertion holds after insertion" in the line-1105 bullet with language consistent with the test expectations section: "cache_control markers are present in the assembled JSON request body for providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` (the dual-flag gate), AND the hit-rate assertion holds after the config flags are set."
