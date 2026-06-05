---
finding_id: R1-F01
severity: high
change_type: test-coverage
artifact: code
round: 1
reviewer: spec-claude
model: claude-sonnet-4-5
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
  - docs/qrspi/2026-05-30-v072-release/tasks/task-08.md#L46
---

# TC4–TC7 fixture findings carry no fabricated citations — spec test expectation not satisfied

**Spec requirement** (`task-08.md:46`):
> "Acceptance fixture audit confirms fabricated reviewer findings cover missing files, out-of-range lines, quoted-content mismatches, and missing named anchors **that are actually cited by the finding**."

**Observed implementation:**

The shared helper `_t8_write_finding_pair` (introduced in the bats file) always writes:

```yaml
referenced_files: []
```

with body text `"Fixture finding body."` — regardless of which citation-failure type (TC4 = file-existence, TC5 = line-range, TC6 = quoted-content, TC7 = named-anchor) the test claims to exercise.

TC4 fixture finding `referenced_files: []`, body: "Fixture finding body."
TC5 fixture finding `referenced_files: []`, body: "Fixture finding body."
TC6 fixture finding `referenced_files: []`, body: "Fixture finding body."
TC7 fixture finding `referenced_files: []`, body: "Fixture finding body."

The fabricated-citation information (e.g. the nonexistent path in TC4's case) exists only in the sidecar `reason:` field that the test itself writes. The sidecar is then immediately read back by the test to confirm `HALLUCINATED:` prefix — making those assertions entirely tautological (the test wrote the value, then checks it).

**Why this does not satisfy the requirement:**

The spec phrase "actually cited by the finding" unambiguously requires the *finding file* to contain the fabricated citation for the type under test:

| Test | Required finding content | Actual finding content |
|------|--------------------------|------------------------|
| TC4 (file-existence) | `referenced_files: [nonexistent/fabricated/path.md]` | `referenced_files: []` |
| TC5 (line-range) | `referenced_files: [agents/fake.md:9999-10000]` (or similar out-of-range entry) | `referenced_files: []` |
| TC6 (quoted-content) | prose body quoting a string attributed to a specific `path:line` | `"Fixture finding body."` |
| TC7 (named-anchor) | prose body or frontmatter naming an identifier attributed to a cited file | `"Fixture finding body."` |

Because the findings contain no citations, these tests would pass unchanged even if the verifier's Cite Check logic were entirely removed: a verifier with `referenced_files: []` has nothing to check, would score on the rubric alone, and the test pre-writes the sidecar anyway. The tests validate only that `verifier-fan-in.sh` drops score-0 findings (which they do correctly), not that the fixture represents a realistic hallucinated finding of its claimed type.

**Impact:**

This is a spec compliance gap against test expectation 2 at `task-08.md:46`. The DoD item at `task-08.md:41` ("The acceptance fixture proves hallucinated sidecars fall below both existing keep thresholds and are excluded from kept-findings.txt") is satisfied; but the fixture-audit expectation that each finding represents the claimed citation failure type is not.

**Fix direction:**

Update `_t8_write_finding_pair` (or add per-test fixture writers) so each finding contains the appropriate fabricated citation:

- TC4: `referenced_files: [nonexistent/fabricated/path.md]`
- TC5: `referenced_files: [agents/fake.md:9999-10000]` (line range that doesn't exist)
- TC6: finding prose body includes a back-tick quoted string attributed to a specific `path:line`
- TC7: finding prose body names a fabricated identifier attributed to a specific cited file

The pre-written sidecar approach for fan-in testing can remain; the requirement is that the *finding body* also faithfully represents the hallucinated citation type.
