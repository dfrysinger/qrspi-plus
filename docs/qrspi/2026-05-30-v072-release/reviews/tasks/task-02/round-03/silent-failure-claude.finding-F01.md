---
finding_id: R3-F01
severity: low
change_type: correctness
referenced_files:
  - tests/unit/test-verifier-fan-in-script.bats
reviewer_tag: silent-failure-claude
round: 3
task: 02
---

R2-fix-1 overflow test asserts JSON halt cause but never asserts stderr diagnostic.

`@test "R2 fix 1: score with > 3 digits is rejected as score_unparseable"` (lines 402-411) verifies exit non-zero and JSON `.halts[0].cause == "score_unparseable"` but does NOT assert the script's stderr `"verifier-fan-in: halt: score_unparseable"` message (script line 300).

Compare with R2 fixes 2 and 3: each has TWO tests — one for JSON cause AND a paired stderr-message test. Fix 1 has only one. A future regression where `echo "verifier-fan-in: halt: …" >&2` is suppressed for this code path would pass undetected.

**Fix:** add a paired stderr-assertion test mirroring tests 3 and 5 patterns:
```bats
@test "R2 fix 1: overflow score emits halt-cause diagnostic to stderr" {
  local f1; f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" "18446744073709551706"
  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$output" == *"score_unparseable"* || "$stderr" == *"score_unparseable"* ]]
}
```
