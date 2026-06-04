---
finding_id: F03
reviewer_tag: code-quality-codex
severity: high
change_type: scope
referenced_files:
  - tests/unit/test-routing-matrix-application.bats:477-507
  - tests/unit/test-routing-matrix-application.bats:652-663
  - tests/unit/test-dispatch-companion-availability.bats:56-63
  - tests/unit/test-dispatch-companion-availability.bats:131-136
  - tests/unit/test-dispatch-companion-availability.bats:178-189
  - tests/unit/test-second-reviewer-available.bats:204-263
---
ID-hygiene violation: design-decision/tracker IDs (D1, D3, D5, D6, CD-1) and task provenance
("(Task 19)") appear in test comments AND in @test names outside docs/qrspi/. Per ID-hygiene,
design-ID provenance is allowed only in skills/ prose; tests must use descriptive, non-tracker
wording. Affects @test names at test-routing-matrix-application.bats:497,505,513 and
test-second-reviewer-available.bats:261,269,277.
