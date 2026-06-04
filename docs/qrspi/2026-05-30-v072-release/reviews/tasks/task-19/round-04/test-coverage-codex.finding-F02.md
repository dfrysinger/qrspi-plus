---
finding_id: F02
reviewer_tag: test-coverage-codex
round: 4
severity: medium
change_type: test_quality
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:42
  - tests/unit/test-second-reviewer-available.bats:288-311
status: open
---

# test-coverage-codex — round 4 — F02 (medium / test_quality)

Unknown-vendor assertions are not fully specific to the contract. Test 288
(`unknown vendor override exits non-zero with [second-reviewer-unavailable]`)
checks non-zero exit + tagged stderr, but does NOT assert stderr is exactly one
line. Per DoD L42 ("exactly one `[second-reviewer-unavailable]` stderr line" for
all four fail cases), a multiline/error-chatter regression on the unknown-vendor
path would currently pass. Only the unknown-host path (test 248) pins the
single-line property. Add a `wc -l == 1` assertion to the unknown-vendor path.

Positive note (carried from reviewer): test `empty-default-vendor-guard`
(lines 453-497) is meaningful and would fail if `[ -z "$_default_vendor" ]` were
removed — it genuinely exercises the new guard.

Disposition: test-only additive (strengthen an assertion); no production change.
Eligible under the user's additive/test-only fix envelope.
