---
finding_id: F02
reviewer_tag: code-quality-codex
severity: medium
change_type: clarity
referenced_files:
  - tests/unit/test-second-reviewer-available.bats:207-260
  - tests/unit/test-dispatch-companion-availability.bats:61-109
  - tests/unit/test-second-reviewer-available.bats:372-404
  - tests/unit/test-dispatch-companion-availability.bats:118-124
---
Substantial duplicated test logic across two suites (host-availability checks and shared-source
guard patterns). Increases maintenance/drift risk; behavior checks could be centralized in one
suite with the other limited to its unique migration/audit assertions.
