---
finding_id: R4-F03
reviewer_tag: cq-codex
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1973
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2088
---

# cq-codex R4 F03: Stale comment — AC5 header says "score" but test enforces representative_score

AC5 coverage header says "pins score", but the test intentionally enforces `representative_score` and rejects bare `score:`. Stale comment should be updated to match the actual asserted schema.

Convergent with cs-codex F03 (terminology indirection) and tc-codex F03 / gt-codex F01 (schema mismatch with spec).

Disposition: ACCEPT-WITH-ISSUES. Trivial fix folded into PI-V072-T10-005 disambiguation work in v0.7.3 (when spec ambiguity is resolved, comment updates with it).
