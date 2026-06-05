---
finding_id: R1-F01
severity: high
change_type: scope
artifact: code
round: 1
reviewer: spec-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1076-L1243
  - docs/qrspi/2026-05-30-v072-release/tasks/task-08.md#L27
  - docs/qrspi/2026-05-30-v072-release/tasks/task-08.md#L37-L49
---

# Acceptance tests do not exercise cited-shape findings through verifier path

**Type:** Test coverage / completeness

**Spec requirement:**
- `task-08.md` requires acceptance coverage that fabricated citations cover missing file / bad line range / quoted-content mismatch / missing anchor **as actually cited by the finding** (`docs/.../task-08.md:27`, `:46-49`).
- DoD also requires Cite Check behavior to be verified, not just fan-in thresholds (`:37-41`).

**Observed implementation:**
- The shared fixture writer hardcodes `referenced_files: []` and a generic body (`tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1076-1077`), so TC4–TC7 findings contain no real citations to validate.
- TC4–TC8 only run `scripts/verifier-fan-in.sh` on prebuilt sidecars (`:1114`, `:1149`, `:1182`, `:1215`, `:1243`) and assert keep/drop behavior, but do not run verifier Cite Check against fabricated citations.

**Why this is a defect:**
These tests can pass even if Cite Check citation-shape validation is broken, so they do not satisfy the task's explicit acceptance expectation for citation-shape coverage.

**Fix direction:**
Update TC4–TC7 fixtures so findings include real citation forms (path, path:line/range, quoted text at cited location, named anchor in cited file) and assert verifier-produced score/reason before (or as part of) fan-in assertions. TC8 should similarly prove no-op behavior via verifier output, not only fan-in on prewritten sidecars.

Overall gate result: **FAIL** (do not pass to downstream reviewers yet).
