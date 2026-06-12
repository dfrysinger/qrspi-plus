---
verifier_status: passed
score: 10
actual_model: unknown
defect_class: altitude-mismatch
---

The Design SKILL explicitly states diagrams are optional ("zero or more per-solution diagrams ... when they aid comprehension") and that "Unified system architecture, file maps, module boundaries ... are Structure's job." Demanding a Mermaid system diagram covering orchestrator + scripts + dispatch params is both (a) not required by the SKILL and (b) an altitude mismatch — that's Structure-step content, not Design. The finding also cites no upstream rule mandating such a diagram. False positive.
