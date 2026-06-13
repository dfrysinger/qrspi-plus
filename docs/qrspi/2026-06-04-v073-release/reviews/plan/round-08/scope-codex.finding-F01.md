---
finding_id: R8-F01
severity: high
change_type: scope
referenced_files:
  - plan.md:L11-L19
  - plan.md:L229-L251
  - plan.md:L430-L451
artifact: plan
round: 8
reviewer: scope-codex
---

Generic boundary-drift claim that task specs include implementation-level control flow / git mechanics that should be deferred to Implement/Structure. NOTE: The cited regions are spec-required content (script-internal mechanics per the plan-spec contract). Low confidence — reviewer cites no specific over-detailed lines, and the QRSPI Plan SKILL explicitly mandates this level of detail in Test Expectations and Description blocks for tdd tasks (per § Required-section presence + § Verbatim contract blocks).

