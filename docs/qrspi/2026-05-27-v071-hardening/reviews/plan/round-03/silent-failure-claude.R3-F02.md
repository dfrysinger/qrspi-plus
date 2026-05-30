---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: silent-failure-claude
---

PARTIAL_STATE_ON_FAILURE: Task 8 skills/using-qrspi/SKILL.md cache-field retirement has no grep-backed test assertion

Three of four modified files have grep-based absence assertions. SKILL.md does not. The plan description specifies removing both YAML examples and description bullets for each cache field (4+ distinct removal locations). Any partial retirement is undetectable.

If implementer removes YAML examples but forgets description bullets, or removes supports_prompt_cache but not emit_cache_control_markers, full CI passes with no indication that retirement is incomplete.

Fix direction: (a) add grep-based absence @test block to an existing test file (e.g. test-run-third-party-llm.bats) that greps SKILL.md for supports_prompt_cache and emit_cache_control_markers and fails if either is found; or (b) add a structural lint test that sweeps SKILL.md for retired-mechanism identifiers.
