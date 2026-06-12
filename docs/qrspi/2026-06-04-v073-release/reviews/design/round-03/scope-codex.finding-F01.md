---
finding_id: R3-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: scope-codex
---

Boundary drift: the design is prescribing **file architecture / implementation placement** (e.g., exact new script files, exact existing files to edit, and where logic must live). Under Design DEFERS, “which file holds which component” belongs to Structure/Plan/Implement.  
Fix: keep the behavioral contract and cross-goal decisions in design.md, but remove or generalize file-location ownership (move concrete file-placement decisions to structure.md / plan.md).

