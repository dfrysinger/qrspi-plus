---
finding_id: R4-F01
severity: low
change_type: clarity
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# AC5 block comment carries stale field name `score` — test body rejects it

**Locations:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` L1972 (G28 block comment), L2093–2100 (test body).

The G28 section block comment documents AC5 scope as `(summary, finding_paths, defect_class, score, threshold)` — but the test body asserts `representative_score:` is present and actively rejects bare `score:` (PI-V072-T10-005 Reading B / R2 Fix A). Comment/test divergence: reviewer reading the comment to understand the test will conclude the wrong thing.

**Recommended fix:** update AC5 block comment to say `representative_score` with parenthetical `(renamed from 'score:' in R2; see PI-V072-T10-005)`.
