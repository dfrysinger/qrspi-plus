---
finding_id: R4-F03
reviewer_tag: gt-codex
severity: low
change_type: scope
referenced_files:
  - agents/qrspi-finding-verifier.md:124
  - tests/unit/test-verified-file-shape.bats:227
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:38
  - docs/qrspi/2026-05-30-v072-release/goals.md:802
---

# gt-codex R4 F03: Field-ordering invariant lacks explicit criterion linkage (YAGNI)

The sidecar field-ordering invariant (defect_class MUST be last, score MUST precede defect_class) is documented as a security invariant against duplicate-key YAML parser drift, but task-10 DoD and G28 do not call for field-order hardening. Backward trace fails.

Disposition: KEEP. The invariant has a defensible security rationale (duplicate-key parser drift is a real YAML attack class) and is cheap to maintain. File backlog PI-V072-T10-014 to add explicit task-10 / G28 spec hook for this invariant in v0.7.3.
