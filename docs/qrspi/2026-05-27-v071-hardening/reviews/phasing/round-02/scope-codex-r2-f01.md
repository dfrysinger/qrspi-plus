---
finding_id: R2-F01
severity: medium
change_type: boundary-drift
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 2
reviewer: scope-codex
defers_to: [parallelize]
disposition: APPLIED (partial; persistent residual recorded as R3-F01 then dismissed)
---

## Original finding

Residual boundary drift remains in Slice 4 and its matching replan gate: the artifact still specifies Branch Map/Wave presentation details plus parallelize-reviewer pinning/lint mechanics. Under the Phasing OWNS/DEFERS contract, Wave/Branch Map decisions are deferred to Parallelize, while Phasing should stay at slice/phase outcome level.

Fix by rewriting this slice and gate to outcome-only language (e.g., "parallelization guidance is reorganized and validated") without prescribing Wave/Branch Map shape or reviewer-rule/lint implementation details.

## Disposition: APPLIED (partial)

R3 applied a partial tightening to Slice 4 + replan criterion 8:
- Removed "parallelize-reviewer's pinning rule" specifics
- Removed "Worked Example pair" artifact-naming
- Removed "structural lint test" test-mechanism
- Reframed criterion 8 from "renders ... per-Wave sub-sections with ... pinning rule and the Worked Example pair updated to match, and the structural lint test passes" to "presents its Branch Map grouped per Wave, with reviewer-side guidance and worked-example artifacts updated to match"
- Retained G4's canonical Wave / Branch Map vocabulary (sourced from goals.md G4 title)

Codex scope re-flagged in R3 (R3-F01) asserting the canonical vocabulary itself crosses the boundary. That follow-up finding was dismissed -- see `round-03/scope-codex-r3-f01-DISMISSED.md`.

(Materialized from inline subagent return; Codex inline-return convention.)
