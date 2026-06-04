---
finding_id: R1-F02
reviewer_tag: spec-codex
severity: medium
change_type: clarity
referenced_files:
  - skills/using-qrspi/SKILL.md#L995-L1018
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2015-L2024
---

The Sub-Threshold Observations YAML template does not match the spec's pinned field shape (`summary`, `finding_paths[]`, `defect_class`, `score`, `threshold`). Implementation uses `observation_summary` and adds an extra `contributing_findings` structure (`skills/using-qrspi/SKILL.md:995-1018`). Acceptance checks are permissive (regex allows either `observation_summary` or `summary`) and therefore do not verify the exact required template shape (`tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2015-2024`).
