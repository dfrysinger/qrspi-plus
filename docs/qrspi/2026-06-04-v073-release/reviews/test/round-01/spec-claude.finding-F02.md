---
finding_id: F02
reviewer: qrspi-spec-reviewer (Test-phase)
reviewer_tag: claude
round: 1
severity: high
change_type: defect
phase: test-phase
artifacts:
  - tests/acceptance/v07-phase1-test-phase/test-g3-absorption-pipeline.bats
  - tests/acceptance/v07-phase1-test-phase/test-integration-dispatch-chain.bats
---

# F02 — G3 fixture design.md uses `### G7` (level-3); the script only matches `^## G\d+` (level-2) — chain test produces empty output and red-tests; integration test passes vacuously

## Where

- `tests/acceptance/v07-phase1-test-phase/test-g3-absorption-pipeline.bats:69-79`
- `tests/acceptance/v07-phase1-test-phase/test-integration-dispatch-chain.bats:83-110`

Both fixtures emit the goal heading as:

```
### G7 — Some goal — absorbed by CD-1
```

## What's wrong

`scripts/design-absorption-markers.sh:39-67` only recognises goal blocks under the
regex `^## G[0-9]+ —` (level-2 ATX heading). The fixture above is **level-3**
(`### G7`), which does not match — the awk action `/^## /` is anchored to exactly
two `#`-marks followed by a space. Confirmed by the script's own header comment:
"Heading-suffix: `^## G\d+ — .+: (moot|absorbed by CD-\d+|already fixed)`".

Consequences:

1. `test-g3-absorption-pipeline.bats:65-80` — script emits **empty stdout** against
   the fixture, so the `grep -qE '^G7[[:space:]]+CD-1$'` assertion on line 79
   FAILS. The test is a red-test: it does not verify the G3 acceptance contract it
   claims to verify (design.md G3 #1 + coverage-report row "G3 design.md #1").

2. `test-integration-dispatch-chain.bats:83-110` — for the same reason the
   absorption-map TSV is not produced; but the assertion is guarded by
   `if [ -f "$map" ]`, so the test **vacuously passes** without ever exercising
   the design-absorption-markers → review-prep chain it claims to integration-test
   (coverage-report row CD-2 "design-absorption-markers.sh → review-prep.sh chain").
   The conditional makes the test green even if review-prep.sh wrote nothing at
   all, which is the inverse of what an integration test should do.

## Why it matters

Two of the three load-bearing G3 chain assertions go red or vacuous, and the
integration-chain test loses its claimed end-to-end signal entirely. The structural
defect is one character (`###` → `##`) but it disables the actual acceptance gate
for `design-absorption-markers.sh`'s output shape.

## Fix direction

Change BOTH fixtures' goal heading to level-2:

```
## G7 — Some goal — absorbed by CD-1
```

(and the `### G8` line below it in the g3 fixture, if you want G8 to remain a
no-marker control). In the integration test, also remove the `if [ -f "$map" ]`
guard and assert unconditionally that the map file exists and carries the
expected `G7\tCD-1` row — otherwise the chain remains untested in the green path.
