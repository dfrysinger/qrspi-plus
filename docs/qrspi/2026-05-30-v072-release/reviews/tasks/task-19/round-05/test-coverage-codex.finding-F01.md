---
finding_id: R5-F01
reviewer_tag: test-coverage-codex
round: 5
severity: high
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: gpt-5.3-codex
---

Behavioral coverage gap: the UNKNOWN-VENDOR unavailable case is not asserted JOINTLY for the full contract (non-zero + exactly one [second-reviewer-unavailable] line + BOTH host= and vendor= in that same line). Evidence: L289-308 checks non-zero + tag + one-line + host= but NOT vendor=; L311-320 checks vendor separately with weak OR semantics `grep -qE 'nonexistent-vendor-xyz|vendor='` (passes if either token appears). DoD task-19.md:42,52 requires joint per-case assertion. Converges with code-quality-codex R5-F01, silent-failure-codex R5-F01, silent-failure-claude R5-F02 (4-reviewer convergence). Fix (test-only additive): in the single-execution unknown-vendor test, assert all of non-zero + line_count==1 + tag-prefix + host= + vendor= (prefer exact vendor=nonexistent-vendor-xyz).
