---
finding_id: R2-F03
artifact: goals
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
round: 2
reviewer: scope-claude
---

## G19 "Iron rule for any candidate" block is an architectural design commitment, not a Goals-level constraint or candidate

### Location
`goals.md` § G19 — Wholesale-hallucination findings, "What we know so far" block (lines ~557–558 of current file).

### Observation
The section contains a paragraph headed **"Iron rule for any candidate (user direction)."** It uses absolute directives with no candidate framing:

> "All cite-checking work MUST happen inside a subagent (the verifier itself, or a dedicated pre-verifier subagent dispatched in parallel). The main chat / orchestrator MUST NOT take on cite-checking work directly…"

This is not placed in the `## Constraints` section (environmental constraints) and is not prefaced with "Candidates Design should weigh:" — it reads as a binding architectural decision made at the Goals stage.

### Rule violated
`owns-defers.md` → **Goals DEFERS: Detailed solution definitions → Design.**

Specifying where in the system a capability must reside (subagent only, never orchestrator) is an architectural design decision. Goals may surface that this is a concern to carry forward, but the "MUST / MUST NOT" architectural commitment belongs in Design.

### Expected correction
Two options:
1. If this is a genuine project-wide constraint (not specific to G19), move it to `## Constraints` with appropriate framing as an environmental/architectural boundary.
2. If it is a design-level preference for G19 candidates, reframe it within "Candidates Design should weigh:" as: "Any cite-checking mechanism should be implemented inside a subagent rather than the orchestrator, to avoid pulling cited file contents into orchestrator context (same motivation as the cross-cutting context-reduction goal)." Design decides whether to adopt this as a hard constraint.
