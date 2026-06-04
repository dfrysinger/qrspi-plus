---
finding_id: F01
reviewer_tag: code-quality-codex
round: 3
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-change-type-partition.bats:253-276
artifact: tests/unit/test-change-type-partition.bats
---

# Test is tightly coupled to implementation details (brittle under safe refactors)

Materialized from chat-only response by gpt-5.3-codex.

The test overrides `pwd()` and then requires exact helper return code `95`. This validates a specific internal mechanism (`cd && pwd -P`) and internal code mapping, not just the observable safety behavior. A refactor that preserves behavior (still safely handling path-resolution failure) but uses a different mechanism or different rc would fail this test unnecessarily.

**Counter (defensible trade-off):** the implementer's R2 commit message explicitly documents this choice: "asserts helper returns the **named** code 95 (specificity guards against future regressions that fail-non-zero at a different step)." Codifying the specific rc is intentional — it ensures the guard fires at the pwd-P step rather than some other unrelated non-zero exit.

Recommendation: defer. The implementation-detail coupling is by design; the alternative (assert non-zero + named diagnostic) trades regression specificity for refactor flexibility. Current call is defensible.
