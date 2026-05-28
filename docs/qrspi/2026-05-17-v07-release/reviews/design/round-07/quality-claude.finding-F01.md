---
finding_id: R7-F01
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L280-L284, docs/qrspi/2026-05-17-v07-release/design.md:L921-L927, docs/qrspi/2026-05-17-v07-release/design.md:L1084-L1088]
artifact: design
round: 7
reviewer: quality-claude
---

The G6 § Recommendation step 4 introduces a substantive new orchestrator-side responsibility — the **Pre-implementer RED-verification gate**:

> "Implement (the orchestrator) runs the test-writer's tests once before dispatching `qrspi-implementer`. If any pre-implementation test passes (vacuous or accidentally already satisfied), the orchestrator pauses with a load-bearing diagnostic; the user inspects and either fixes the test via a fix-task or skips. This is the load-bearing pre-implementer gate that closes the protocol boundary between the two agents."

This is a meaningful protocol addition (an orchestrator-run pause distinct from the per-agent dispatches), and G6's own per-goal test strategy correctly includes a "Pre-implementer RED-verification test". However, two downstream summary surfaces that Phasing/Plan/Structure readers will rely on for quick scanning fail to mention it:

1. **Decision 3** (key architectural decisions section, L921–L927) summarizes G6 as "the split runs only for TDD tasks … reuses the existing `qrspi-test-writer` agent with a per-task signal so the agent can run in both Test phase mode and Implement phase mode. A new agent is not needed." Decision 3 omits the orchestrator-side RED-verification gate entirely, even though it is arguably the load-bearing element ("closes the protocol boundary between the two agents") that prevents vacuous-assertion confirmation bias from sneaking back in via accidentally-satisfied tests.

2. **Cross-cutting test strategy** § "TDD test-writer split" (L1084–L1088) lists three bullets:
   - test-writer dispatched before implementer
   - test-writer writes failing tests before implementer runs
   - lightweight bypass

   It does not surface the pause-on-pre-passing-test behavior. The closest bullet ("The test-writer writes failing tests before the implementer runs") covers ordering but not the orchestrator pause that fires when those tests *don't* fail.

The omission is a clarity defect, not a correctness one — G6's body is correct and self-consistent. The risk is that Phasing or Plan readers who scan Decisions + cross-cutting strategy (as the design's own framing invites — "Downstream agents should follow these even when the reasoning is not repeated in each goal") will design tasks and acceptance tests without budgeting for the orchestrator-side gate, then rediscover it during Plan or Implement.

Suggested fix: add one sentence to Decision 3 naming the pre-implementer RED-verification gate as part of the split contract, and add a bullet to the cross-cutting "TDD test-writer split" section asserting that the orchestrator pauses if any pre-implementation test passes. Both are small additions that bring the summary surfaces into alignment with G6's body and own test strategy.
