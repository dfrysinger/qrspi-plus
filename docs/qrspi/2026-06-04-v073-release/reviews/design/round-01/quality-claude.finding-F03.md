---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 1
reviewer: quality-claude
---

The design introduces five new scripts and modifies two existing ones — `scripts/upstream-paths.sh` (CD-1), `scripts/review-prep.sh` (CD-2), `scripts/design-absorption-markers.sh` (G3.a), `scripts/orchestration-boundary-check.sh` (G5.b), high-level mode additions to `scripts/dispatch-agent.sh` (CD-2), and parent-validation additions to `scripts/wave-dispatch.sh` (G6) — with non-trivial call-chain interactions (review-prep.sh calls design-absorption-markers.sh; dispatch-agent.sh calls review-prep.sh; upstream-paths.sh feeds verifier dispatch across all steps; etc.). No Mermaid system diagram is present in design.md.

Per the design quality check, "a Mermaid system diagram is present in `design.md` and describes the system at a level that helps an implementer understand component relationships." Without a diagram, an implementer must piece together the script interaction topology from nine separate goal sections — including cross-goal sequencing dependencies (CD-1 before G1/G4, CD-2 before G3/G5, G6 before G5, G1 before G2) that are scattered throughout the text. The absence of a diagram is particularly costly here because the component relationships are not obvious from goal names alone.

Fix: Add a Mermaid diagram to a `## System Diagram` section (or `## Cross-Goal Component Relationships`) that shows the new scripts, their callers, and the key data flows (e.g., review-prep.sh → dispatch-agent.sh → reviewer dispatch; upstream-paths.sh → verifier dispatch; design-absorption-markers.sh → review-prep.sh → plan-spec-reviewer dispatch).

