---
verifier_status: passed
score: 10
actual_model: unknown
defect_class: altitude-mismatch
---

The Design SKILL (`skills/design/SKILL.md` lines 27-43) explicitly states that
diagrams are optional ("Design may include zero or more per-solution diagrams...
when they aid comprehension") and that "Unified system architecture, file maps,
module boundaries... are Structure's job." The finding asserts a non-existent
"design-quality contract" requirement for a system Mermaid diagram, contradicting
the SKILL's owns/defers contract. This is an altitude-mismatch false positive —
system-level diagramming belongs to Structure, not Design.
