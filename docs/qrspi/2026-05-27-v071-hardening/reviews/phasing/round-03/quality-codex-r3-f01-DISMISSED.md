---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 3
reviewer: quality-codex
disposition: DISMISS
protocol_note: emitted with malformed `<<<FINDING>>>` boundary marker instead of required `<<<FINDING-BOUNDARY>>>`; orchestrator surfaced content from agent response despite splitter non-compliance
---

## Original finding

Replan criterion 8 now says only that the Branch Map is "grouped per Wave" and that reviewer guidance/worked examples are "updated to match." This is weaker than the design decision it cites (`design.md` DKR4), which specifies a concrete target shape (`### Wave N` subsections with mini Branch Map tables) and associated structural-lint/test alignment.

Recommended fix (per reviewer): Tighten criterion 8 to explicit observable checks (required Wave-subsection structure, required table shape, structural lint/test pass signal).

## Disposition: DISMISS

Reasoning:

1. **Direct contradiction with sibling Codex reviewer.** Codex scope R3 (R3-F01) flagged the SAME criterion 8 as having too much Parallelize-internal mechanics vocabulary. Codex quality wants the inverse (more concrete mechanics). The two Codex reviewers' requested resolutions are mutually exclusive: any R4 fix satisfying one re-triggers the other. The Codex pair represents an oscillating contradictory pair, not actionable convergence.

2. **Claude quality R3 explicitly cleared the same surface.** Claude quality R3 wrote: "Criterion 8 remains observable and checkable; the dropped 'structural lint test passes' is already subsumed by criterion 1's CI-pass-with-no-regressions clause." That is, the verifiability concern Codex quality raises is satisfied by criterion 1's CI-pass requirement -- the structural lint test is part of the CI suite, so its pass is checkable through the existing gate.

3. **DKR4 binding is intact.** Criterion 8 cites `design.md` DKR4 explicitly. The Phasing OWNS contract authors gate criteria; Design owns the detailed structural specification. Replan reads BOTH artifacts when evaluating gate satisfaction. Replicating DKR4's full mechanic specification inside the phasing gate criterion is structural duplication that the Phasing skill's OWNS/DEFERS contract explicitly tries to avoid (boundary-drift in the opposite direction).

4. **Protocol non-compliance compounds the dismissal call.** The finding was emitted with `<<<FINDING>>>...<<<END_FINDING>>>` instead of the required `<<<FINDING-BOUNDARY>>>` marker per the reviewer protocol output-format constraint. A strict protocol read would discard this output as malformed; the orchestrator is surfacing it for completeness.

Conclusion: Criterion 8's observable-checkability flows through DKR4 binding + criterion 1 CI-pass. The Phasing gate criteria appropriately stay at the gate level and let downstream Design + CI specifications carry the mechanics. No further changes.

(Disposition added by orchestrator after R3 convergence analysis.)
