---
finding_id: R7-F02
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 7
reviewer: quality-claude
---

CD-2's solution description's generation table omits the plan step. G3 (change 3) depends on CD-2 extending review-prep "at the plan step" to deliver `absorption_map_path` to the plan-spec reviewer, but CD-2's own table never describes this.

CD-2 lists: Design, Goals, Research, Phasing, Structure, Parallelize, Replan, per-task implement. Plan is absent.

Risk: implementer building CD-2 independently would not handle plan step → G3's plan-spec-reviewer absorption-map delivery silently broken at integration time.

Fix: In CD-2's solution generation table, add the plan step — e.g., "Plan produces absorption-map (consuming `scripts/design-absorption-markers.sh` per G3.a) + diff with pipeline-mode-appropriate narrowing (per G4)" — or add explicit cross-reference. Also extend CD-2 acceptance to include a bats test for `review-prep.sh --step plan`.
