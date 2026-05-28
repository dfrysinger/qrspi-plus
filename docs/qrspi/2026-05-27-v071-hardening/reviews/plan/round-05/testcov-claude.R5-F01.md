---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 5
reviewer: testcov-claude
---

Task 8 SKILL.md grep over-specifies cache_control without description requirement

R4 fix extended SKILL.md grep to 3 strings (cache_control, supports_prompt_cache, emit_cache_control_markers) per silent-failure-claude R4-F02. But Task 8 description and first prose expectation only require supports_prompt_cache + emit_cache_control_markers absent from SKILL.md. cache_control may legitimately appear in SKILL.md documentation prose. Self-contradictory: implementer follows description (removes 2 strings), test asserts 3, CI red.

Fix options:
(a) Add cache_control to description + first prose bullet as required-absent from SKILL.md (matches the assertion)
(b) Remove cache_control from SKILL.md grep, keep only in scripts/run-third-party-llm.sh grep where it's separately required

DISPOSITION: ACCEPT — option (a). Quality-claude also flagged this as a "minor observation". The cleanest resolution is to require cache_control absent from SKILL.md too (operator-visible documentation should not document a dead feature). Note: quality-claude said this is "slightly under-specified relative to the automated assertion" and not blocking, but testcov-claude correctly identifies it as a self-contradiction that would block CI. Apply fix (a).
