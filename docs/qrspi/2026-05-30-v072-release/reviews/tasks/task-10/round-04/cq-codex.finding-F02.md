---
finding_id: R4-F02
reviewer_tag: cq-codex
severity: medium
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1956
---

# cq-codex R4 F02: Acceptance file size — >2000 lines

T10 appends large G28 coverage block to test-phase1-acceptance.bats (>2000 lines). Suggests splitting G28 coverage into dedicated acceptance file or helper-backed subfile.

Disposition: ACCEPT-WITH-ISSUES, file backlog PI-V072-T10-010 (architectural; defer to v0.7.3 acceptance refactor or as part of release-wide test reorganization).
