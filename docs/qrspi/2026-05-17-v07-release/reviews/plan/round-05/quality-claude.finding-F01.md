---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1118]
artifact: plan
round: 5
reviewer: quality-claude
---

T36's Description paragraph at line 1118 still contains the phrase "cache_control markers are inserted at the Anthropic SDK boundary first" as part of the Path B add-then-verify description.

This is the same "Anthropic SDK boundary" characterization that R3-F04 and R4-F01 identified as incorrect. R4-F01 correctly updated the target-file bullet (now at line 1111) to use dual-flag-gate language, but the corresponding phrase in the Description body at line 1118 was not updated. The sentence reads:

> "path-conditional and reads the T33 spike-report deliverable to choose between Path A verification-only fixtures (...) and Path B add-then-verify fixtures (cache_control markers are inserted at the Anthropic SDK boundary first; the test then asserts both marker presence and the same hit-rate condition)"

The characterization is incorrect for the same reason flagged in prior rounds: the dual-flag gate (`supports_prompt_cache: true` AND `emit_cache_control_markers: true`) governs `cache_control` emission for any provider entry in `config.md`, not specifically at an "Anthropic SDK boundary." The T03 dispatcher gates emission on the two config flags regardless of which provider is being called. The corrected language used in the test expectations section (line 1120) — "under the dual-flag gate" and "ONLY for providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true`" — is the authoritative framing.

Fix: in the Description paragraph at line 1118, replace "cache_control markers are inserted at the Anthropic SDK boundary first; the test then asserts both marker presence and the same hit-rate condition" with language consistent with the test expectations section, such as: "cache_control markers are activated at providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` (the dual-flag gate); the test then asserts both marker presence in the assembled JSON request body and the same hit-rate condition."
