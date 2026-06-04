---
finding_id: R3-F02
reviewer: cq-codex
severity: med
change_type: style
referenced_files:
  - scripts/run-codex-review.sh
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F02 — ID hygiene violations: QRSPI-internal tokens in code outside docs/qrspi/

**Spec rule:** QRSPI internal IDs (task numbers, AC labels, goal IDs) MUST NOT appear in code or test names outside `docs/qrspi/` per the ID hygiene rules in implementer-protocol.

**Violations:**
- scripts/run-codex-review.sh lines 275-276, 804: contain `T11`, `T20`, `T7` tokens in comments
- tests/acceptance/v07-phase1/test-phase1-acceptance.bats lines 2192-2203, 2293, 2361, 2441, 2490, 2497: test names contain `AC1`, `T11` tokens

**Fix:** rename test cases to describe the behavior rather than reference the AC label (e.g., `@test "first-party dispatch writes DISPATCH_FILE marker"` instead of `@test "T11 AC1: ..."`). Remove QRSPI ID references from code comments.
