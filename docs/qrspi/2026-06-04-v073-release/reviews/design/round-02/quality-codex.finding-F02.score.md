---
verifier_status: passed
score: 10
actual_model: unknown
defect_class: altitude-mismatch
---

The finding asserts a "quality bar" requiring a system-level Mermaid diagram in design.md. The Design SKILL.md contradicts this: it explicitly states diagrams are optional ("Design may include zero or more per-solution diagrams... when they aid comprehension", and "Optional per-goal Mermaid diagram"). Unified system architecture is explicitly deferred to Structure ("Unified system architecture, file maps, module boundaries... are Structure's job"). The finding invents a requirement that does not exist in the upstream skill and arguably asks Design to do Structure's job — an altitude mismatch. Score low.
