---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/g4-section-anchor-manifest.json
  - skills/using-qrspi/SKILL.anchors.json
  - skills/reviewer-protocol/SKILL.anchors.json
  - skills/plan/SKILL.anchors.json
reviewer_tag: spec-codex
---

Required anchor-manifest / per-skill anchor updates were not implemented.

Spec requirement (tasks/task-12.md:14, 27, 45): update scripts/g4-section-anchor-manifest.json, skills/using-qrspi/SKILL.anchors.json, skills/reviewer-protocol/SKILL.anchors.json, skills/plan/SKILL.anchors.json.

Observed: round-01.diff only shows scripts/await-round.sh, scripts/round-prepare.sh, tests/unit/test-await-round.bats, tests/unit/test-round-prepare.bats (round-01.diff:1, 249, 631, 777).

Impact: completeness failure — requested deliverables missing.
