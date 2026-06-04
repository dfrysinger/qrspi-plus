---
finding_id: R6-F01
reviewer: spec-codex
severity: med
change_type: scope
referenced_files:
  - tests/unit/test-verified-file-shape.bats
  - agents/qrspi-finding-verifier.md
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md
---

# F01 — Fixture-backed unit assertion for sidecar `defect_class` token still missing

**Spec requirement:** task-10.md lines 27, 45, 51 require fixture-backed unit coverage in `tests/unit/test-verified-file-shape.bats` asserting verifier sidecars carry a non-empty, well-formed `defect_class` token and accept `unspecified`.

**What's implemented instead:** Unit file at lines 152-197, 211-227 adds/keeps doc-prose/shape grep pins against `agents/qrspi-finding-verifier.md`, but does NOT assert sidecar fixture content for non-empty/well-formed `defect_class` tokens. Fixture-backed tests at lines 68-106 validate counts/markers only (scored/kept/dropped/failed/clean, @@FINDING/@@SCORE/@@CLEAN), with no `defect_class` assertion on fixture sidecars.

**Disposition (orchestrator):** This is a re-raise of the same gap surfaced by spec-codex at R4 (accepted-with-issues there) and tracked as PI-V072-T10-007 in the v0.7.3 backlog. Out of scope for v0.7.2 per user-confirmed deferral. R5 did not promise to close this gap; the R5 scope was explicitly the 13 in-scope groups A-F + the new AC6 fan-in invariance pin. Recording for traceability; not blocking T10 terminal acceptance.
