---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-claude
---

The design lacks a Mermaid system diagram, which the design-quality checks require ("a Mermaid system diagram is present in `design.md` and describes the system at a level that helps an implementer understand component relationships"). The design introduces four new scripts (`scripts/upstream-paths.sh`, `scripts/review-prep.sh`, `scripts/design-absorption-markers.sh`, `scripts/orchestration-boundary-check.sh`), a modified `scripts/dispatch-agent.sh`, modifications to five agents/skill files in G3 alone, and a new build-tool path (G8). The component dependencies are non-trivial: CD-1 → G1, G4; CD-2 → G3, G5; G6 → G5 (phase-base anchor); G1 → G2. An implementer reading the design cannot quickly form a mental map of how the new script chain (review-prep → dispatch-agent → reviewer prompts), the absorption-map flow (design-absorption-markers.sh → plan-author → plan-spec-reviewer → design-reviewer), and the boundary-check hook (orchestration-boundary-check.sh → integrate/test batch gate) interrelate before diving into individual goal sections. A Mermaid diagram covering at minimum the new script-to-agent call relationships and the G3 absorption-map data-flow would satisfy the check.

