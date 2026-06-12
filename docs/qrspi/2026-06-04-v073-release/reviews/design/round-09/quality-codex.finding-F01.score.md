---
verifier_status: passed
score: 10
actual_model: unknown
defect_class: spurious-requirement
---
Finding asserts a Mermaid system diagram is "required" in design.md. The Design SKILL (skills/design/SKILL.md lines 27–43) states the opposite: per-goal Mermaid diagrams are explicitly *optional* ("Optional per-goal Mermaid diagram when the solution involves flow that benefits from visualization"), and unified system architecture / module boundaries are explicitly deferred to Structure ("Unified system architecture, file maps, module boundaries... are Structure's job"). No "required Mermaid system diagram" rule exists at the Design altitude. Finding fabricates a requirement and is a false positive; also an altitude mismatch (system-diagram concern belongs to Structure review, not Design).
