---
reviewer: code-quality-claude
phase: test
round: 01
severity: minor
change_type: defect
finding_id: F05
title: test-integration-dispatch-chain (B) makes its load-bearing assertion conditional on file existence — passes silently when review-prep skips writing the absorption map
files:
  - tests/acceptance/v07-phase1-test-phase/test-integration-dispatch-chain.bats
---

## What

The "(B) design-absorption-markers.sh → review-prep.sh" integration test (lines 79-111) ends with:

```bash
map="$TMP_DIR/docs/release/reviews/plan/round-01.absorption-map.tsv"
if [ -f "$map" ]; then
  grep -qE '^G7[[:space:]]+CD-1$' "$map" || {
    echo "absorption-map written but missing expected G7→CD-1 row" >&2
    cat "$map" >&2
    false
  }
fi
```

The comment immediately above acknowledges the gap: *"Allow exit 0 (silent-on-no-input) or exit 0 with files written; either way, if the absorption-map is written it MUST land at the documented path shape."*

## Why it matters

The test name (`integration: review-prep.sh --step plan writes the absorption-map TSV at the documented path`) and the comment header (*"CD-2 contract: design's and plan's review-prep run produces an absorption-map.tsv consumed by the plan-spec reviewer"*) both promise to verify **that the map is written**. The body verifies only **that IF the map is written, its content is correct**.

Failure modes the test will silently pass under:

- `review-prep.sh` regresses and stops calling `design-absorption-markers.sh` entirely — map file absent → test passes.
- The output-path contract changes (e.g. `round-01.absorption-map.tsv` → `round-01-absorption-map.tsv`) — map written elsewhere → test passes.
- `review-prep.sh` exits 0 but writes nothing on the given fixture — test passes.

This is exactly the chain the test was created to defend (G3 + CD-2 cross-slice), and the assertion shape leaves all three regressions undetected.

## Recommended fix

Either commit to "this fixture MUST produce the map" (the test sets up a marker-bearing design.md specifically to trigger it) and make the assertion unconditional:

```bash
[ -f "$map" ] || {
  echo "expected absorption-map at $map, not found; ls of dir:" >&2
  ls -la "$TMP_DIR/docs/release/reviews/plan/" >&2 || true
  false
}
grep -qE '^G7[[:space:]]+CD-1$' "$map"
```

Or, if `review-prep.sh`'s silent-on-no-input branch is the intended behaviour for this fixture shape, **split into two tests**: one for the positive direction with an input shape that mandates the map, and one for the silent-skip branch with an explicit empty-design fixture and an assertion that `[ ! -f "$map" ]`. Either way, the conditional `if [ -f ]; then ... fi` shape must go.

## Verification

After the fix, stubbing out the absorption-map write path in `review-prep.sh` (or running against an empty `design.md`) MUST fail the positive-direction test with a clear "expected absorption-map not found" diagnostic.
