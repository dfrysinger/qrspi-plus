---
verifier_status: passed
score: 10
actual_model: unknown
defect_class: altitude-mismatch
---

Finding asserts design.md is missing a "Mermaid system diagram." Per `skills/design/SKILL.md` lines 22–43:

- Design produces per-goal solution definitions; Mermaid diagrams are explicitly **optional per-goal** ("when the solution involves flow that benefits from visualization") and "zero or more per-solution diagrams" is permitted.
- Unified system architecture, file maps, module boundaries are explicitly **deferred to Structure** ("Unified system architecture, file maps, module boundaries, and the unified test architecture … are Structure's job").

A "system diagram" at Design altitude would be an altitude violation per the SKILL. The finding contradicts the documented Design owns/defers contract, and offers no specific citation or per-goal locus where a diagram would aid comprehension. It is a vague structural complaint that conflicts with the skill, not a real defect.
