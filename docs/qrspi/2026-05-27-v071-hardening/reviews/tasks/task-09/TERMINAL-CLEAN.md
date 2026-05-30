# T9 — TERMINAL CLEAN

**Head SHA:** cf52a40
**Tests:** 11/11
**Final round:** R11 (narrow-verify of R10 fix; tc.F01 verified to 35 → DROP)

## Round chain summary

- R1–R7: spec-gate + correctness fan-out + fix cycles for sf findings
- R8: sf narrow-verify → both findings DROP per Hotfix A pre-existing rule
- R9: thoroughness fan-out (gt + tc + cs) → 2 KEPT (tc.F01 folded-scalar gap, tc.F02 complete-output assertion gap), 3 DROP, 3 cs advisory
- R10: fix-cycle commit cf52a40 — folded `>` fixtures (tests 9, 10) + complete-output mutation assertion (test 11)
- R11: narrow-verify → 1 low clarity finding (test-comment inaccuracy) → DROP after verifier score 35

## Polish backlog (deferred)

- cs.F01: `in_scalar` is dead code; could be removed in v0.7.2 cleanup, BUT test 11 now functions as contract test locking in invariant that `in_scalar` SHOULDN'T gate print
- cs.F02: sweep stub comment mislabel (advisory)
- cs.F03: duplicate scalar-at-end tests (advisory)
- tc R11.F01: test 9 comment overstates mutation resistance (would benefit from rewording)
