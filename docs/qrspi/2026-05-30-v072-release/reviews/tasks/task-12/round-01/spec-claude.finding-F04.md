---
finding: F04
reviewer: spec-claude
severity: fail
category: test-coverage
task: 12
round: 1
---

# F04 — No test asserts anchor JSON windows cover the sections changed by this release

## What the spec requires

**Test expectation** bullet 10:
> Grep or diff the refreshed anchor JSON windows to confirm they cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

This is a **content** assertion, distinct from a structural / validity assertion.

## What the tests provide

`tests/unit/test-round-prepare.bats` has three JSON-validity tests (lines 82–92) and one idempotency test (lines 94–104):

```bats
@test "g4-section-anchor-manifest.json is valid JSON with entries[]" {
  # Checks: entries is a list with ≥ 1 items, each has source + index strings.
  # Does NOT check: which sections appear, whether line windows are current.
}

@test "skills/using-qrspi/SKILL.anchors.json is valid JSON"  { … }
@test "skills/reviewer-protocol/SKILL.anchors.json is valid JSON" { … }
@test "skills/plan/SKILL.anchors.json is valid JSON" { … }

@test "anchor refresh is idempotent: rerun produces no diff against tracked indexes" {
  # Runs g4-section-anchor-refresh.sh and checks git diff exits 0.
  # Passes trivially when anchor files were NEVER refreshed (nothing to diff).
}
```

None of these tests verify that the anchor files contain entries for the specific sections that changed in this release:
- **dispatch** section (using-qrspi)
- **round-preparation** section (using-qrspi)
- **reviewer-protocol** section (reviewer-protocol)
- **plan-classification** section (plan)

The idempotency test (`g4-section-anchor-refresh.sh` produces no diff) would pass regardless of whether the files were refreshed or not, because running the refresher against unchanged SKILL.md files would simply reproduce the same anchors that are already committed.

## Impact

The test suite provides false confidence: four "valid JSON" tests pass even if the anchor files contain no entries for the sections changed by this release. The spec's test expectation is entirely unverified.

This finding is downstream of F01 (the anchor files were never refreshed), but it is also an independent test-coverage gap: even if the files had been refreshed, the test suite would not verify the right sections are covered.

## Required fix

After fixing F01 (refreshing the anchor files), add content-checking tests that:

1. Grep `skills/using-qrspi/SKILL.anchors.json` for the key `"Standard Review Loop"` (or the relevant dispatch / round-preparation section heading) and assert it exists with numeric `line_start`/`line_end`.
2. Grep `skills/reviewer-protocol/SKILL.anchors.json` for the `"Reviewer Dispatch Contract"` and/or `"Phase Routing"` section key.
3. Grep `skills/plan/SKILL.anchors.json` for the `"Change-Type Classifier"` or plan-classification section key.
4. Optionally: assert that the recorded line numbers are plausible (non-zero, `line_start < line_end`, within the actual line count of the SKILL.md file).

Example assertion pattern:
```bats
@test "using-qrspi anchors cover dispatch/round-preparation sections" {
  python3 -c "
import json
d = json.load(open('$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json'))
assert 'Standard Review Loop' in d, 'missing Standard Review Loop anchor'
assert d['Standard Review Loop']['line_start'] > 0
"
}
```
