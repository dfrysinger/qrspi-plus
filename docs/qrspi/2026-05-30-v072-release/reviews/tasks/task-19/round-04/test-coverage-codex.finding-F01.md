---
finding_id: F01
reviewer_tag: test-coverage-codex
round: 4
severity: medium
change_type: test_coverage
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:42
  - scripts/second-reviewer-available.sh:55
  - tests/unit/test-second-reviewer-available.bats:236-497
status: open
---

# test-coverage-codex — round 4 — F01 (medium / test_coverage)

The "unavailable vendor" path is not directly exercised by an explicit `none`
override. The production script has a dedicated fail branch for `[ "$_vendor" = "none" ]`
(line 55, clause 3), but current tests cover unknown host/default-none, unknown
vendor (`nonexistent-vendor-xyz`), and empty-default-vendor injection — never an
explicit `none` vendor argument on a known host. DoD L42 lists "unavailable vendor"
as a distinct required case. Add an additive test: `second-reviewer-available.sh none`
on a known host (e.g. COPILOT_CLI=1) exits non-zero with exactly one
`[second-reviewer-unavailable]` stderr line.

Disposition: test-only additive; no production change. Eligible under the user's
additive/test-only fix envelope.
