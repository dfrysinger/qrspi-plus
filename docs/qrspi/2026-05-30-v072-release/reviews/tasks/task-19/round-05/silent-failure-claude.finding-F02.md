---
finding_id: R5-F02
reviewer_tag: silent-failure-claude
round: 5
severity: low
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: claude-sonnet-4.6
---

Strengthened unknown-vendor test adds host= pin but omits vendor= pin; a vendor= field-name rename goes undetected.
test-second-reviewer-available.bats:307 — the round-04 fix added line_count==1 + `grep -q 'host='` to the unknown-vendor-override test, but did NOT add a vendor= pin. DoD L52 requires the diagnostic to name host PLUS requested/default vendor. The only vendor= coverage for this path is the adjacent test (L319) `grep -qE 'nonexistent-vendor-xyz|vendor='` — OR semantics: a rename of vendor= → vendor_name= still passes via the value branch (nonexistent-vendor-xyz remains present), so the renamed field is undetected. Converges with code-quality-codex R5-F01 + silent-failure-codex R5-F01 (3-reviewer convergence). Fix (test-only additive): add `grep -q 'vendor='` (or tighter `grep -q 'vendor=nonexistent-vendor-xyz'`) to the single-line unknown-vendor test.
