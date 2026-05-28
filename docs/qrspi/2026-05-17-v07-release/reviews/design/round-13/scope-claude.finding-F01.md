---
finding_id: R13-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L594-L603]
artifact: design
round: 13
reviewer: scope-claude
---

The G12 "Commit sequence (defense in depth)" block at lines 594–603 enumerates a 6-step ordered procedure with specific git commands and explicit conditional branching logic ("On empty, branch to `BLOCKED` or `DONE_WITH_CONCERNS`..."). The OWNS/DEFERS rule for Design explicitly defers "Line-by-line logic (procedural pseudocode, control-flow detail)" to Plan / Implement.

The *decision* that staging must occur before the scratch write (the reorder) is an architectural choice that Design rightfully owns. The *procedure* — an enumerated, numbered sequence with specific git command text, state-machine transitions, and per-step rationale explaining exactly how each step interacts with the others — is procedural detail that belongs in the implementer-protocol edit (Plan/Implement territory), not in the design artifact.

The finding is medium severity rather than high because the correct ordering sequence is the load-bearing design decision and is already described in the surrounding prose; the enumerated procedure is restating and elaborating it at implementation granularity.

To resolve: replace the 6-step enumerated procedure with a prose description of the architectural contract — e.g., "staging runs before the scratch file is written; the scratch file is removed after commit and before any subsequent staging cycle." Leave the step-by-step git command sequence and branching details for `skills/implementer-protocol/SKILL.md` (which G12's recommendation already identifies as the target edit site).
