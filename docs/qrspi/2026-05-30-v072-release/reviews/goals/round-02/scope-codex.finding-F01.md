---
finding_id: R2-F01
artifact: goals
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
round: 2
reviewer: scope-codex
---

## MUST / MUST NOT directives in G15 and G19 cross implementation-prescription boundary

### Location
`goals.md` § G15 (~lines 344-348) and § G19 (~lines 557-558).

### Observation
Two passages contain absolute MUST / MUST NOT directives that prescribe implementation behavior rather than capture goals or constraints:

1. **G15 "Fail-loud assertions: script refuses to run when..."** — directive language about script behavior shape.
2. **G19 "All cite-checking work MUST happen inside a subagent... The main chat / orchestrator MUST NOT take on cite-checking work directly"** — architectural prescription on where capability resides.

Both are wrapped within "What we know so far" rather than the Constraints section, and neither is framed as a candidate.

### Rule violated
`owns-defers.md` → **Goals DEFERS: Detailed solution definitions → Design**, **Implementation patterns → Plan/Implement**.

MUST / MUST NOT in non-Constraint sections, without candidate framing, signals an implementation commitment authored at Goals stage.

### Expected correction
- G15: soften "script refuses to run when..." to outcome-level constraint or reframe as a candidate ("Candidate Design should weigh: fail-loud assertion at probe time...").
- G19: either lift the cite-checking rule to a top-level Constraint (if user-confirmed environmental rule) or reframe as a candidate.
