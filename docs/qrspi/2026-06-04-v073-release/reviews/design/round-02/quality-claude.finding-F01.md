---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 2
reviewer: quality-claude
---

No Mermaid system diagram is present anywhere in `design.md`. The design quality check requires: "a Mermaid system diagram is present in `design.md` and describes the system at a level that helps an implementer understand component relationships." The design introduces two new scripts (`scripts/upstream-paths.sh`, `scripts/review-prep.sh`), extends `scripts/dispatch-agent.sh` with a high-level mode, modifies multiple agent files and skills, and adds `scripts/orchestration-boundary-check.sh` — but no diagram shows how these components relate to each other or to the orchestrator call chain. An implementer reading the design cannot quickly orient themselves on the component topology before diving into the per-goal decision blocks.

Fix: add a Mermaid diagram (flowchart or C4-style component diagram) that shows at minimum: orchestrator → dispatch-agent.sh → review-prep.sh → scripts/upstream-paths.sh, the reviewer fan-out, the absorption-map flow (design.md → design-absorption-markers.sh → plan-spec-reviewer), and the orchestration-boundary-check.sh hook at phase boundaries.

