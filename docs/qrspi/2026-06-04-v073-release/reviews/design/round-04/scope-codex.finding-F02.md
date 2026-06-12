---
finding_id: R4-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L281-L385]
artifact: design
round: 4
reviewer: scope-codex
---

Boundary drift into **Implement-owned executable procedure detail**: the design includes long executable shell/procedural blocks (multi-step command sequences and branching behavior), exceeding the allowed "few illustrative lines" at design altitude. Replace these with concise outcome-level flow descriptions and constraints; defer full command/procedure bodies to plan/implement artifacts.
