---
finding_id: R1-F03
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L93-L111]
artifact: goals
round: 1
reviewer: quality-claude
---

G5 bundles two distinct investigations into one goal: (1) the dispatcher-tolerance research that produces the populated matrix filling G1's schema, and (2) the open process-design question of whether Implement should split test-writing into its own subagent. The goal title acknowledges the bundling ("Dispatcher tolerance research and test-writer subagent investigation"), and the "Why we care" paragraph justifies it on the grounds that both questions share the same investigative shape.

The shape-similarity argument is reasonable but the consequences for downstream phases are non-trivial. Design, Phasing, and Structure will need to treat G5 as either a single research surface (one set of acceptance criteria, one set of artifacts, one Wave slot) or two effectively-parallel research surfaces sharing a goal ID. The first reading risks under-scoping the test-writer-split investigation, whose answer space ("yes split / yes route cheap," "yes split / keep on trusted path," "do not split") is more decision-shaped than tolerance research and may produce a process change that has implications well beyond cost-opt. The second reading effectively makes G5 a two-goal bundle under one ID, which complicates goal-traceability and approval gates.

Two reasonable resolutions: (a) split G5 into G5a (dispatcher tolerance matrix) and G5b (test-writer subagent investigation), keeping the cross-cutting note that both leverage the same A/B replay methodology; or (b) keep G5 as one goal but explicitly tighten the Problem statement to state that the test-writer question is a sub-investigation whose deliverable is a recommendation feeding the same matrix, not a separate process-design proposal. Either resolution is consistent with the user's intent; the current framing leaves the choice ambiguous and pushes it into Design.

Tagged `scope` because resolving this changes how many distinct deliverables P1 commits to, not how the existing deliverable is described.
