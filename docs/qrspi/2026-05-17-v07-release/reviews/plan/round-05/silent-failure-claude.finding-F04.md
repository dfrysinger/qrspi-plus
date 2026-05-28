---
finding_id: R5-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L557-L559
  - docs/qrspi/2026-05-17-v07-release/plan.md:L626-L634
artifact: plan
round: 5
reviewer: silent-failure-claude
---

T15's test expectation at L558 specifies: "the pre-DONE self-check subsection specifies the concrete reviewer-visibility mechanism for unacknowledged hits: the DONE-report body is passed as a companion parameter on every per-task reviewer dispatch (so the reviewer's pre-flight reads the DONE-report alongside the artifact under review), AND the per-task reviewer dispatch site explicitly lists the DONE-report file path so reviewers can re-Read it directly."

And T18's test expectation at L633 verifies: "the next per-task reviewer dispatch includes the DONE-report body as a companion parameter AND the DONE-report file path is listed in the dispatch payload."

However, no task in the plan modifies `skills/implement/SKILL.md`'s per-task reviewer dispatch procedure to actually pass the DONE-report companion. The tasks that modify `skills/implement/SKILL.md` are:
- T05 (routing chain + telemetry)
- T11 (pre-implementer TDD gate + RED-verification)
- T27 (reference-gate human pause + visual-fidelity reviewer dispatch)
- T39 (worktree-setup exclude append)

None of these tasks include a description of extending the per-task reviewer dispatch with the DONE-report companion parameter. T15 is a `skills/implementer-protocol/SKILL.md` change only — it can declare the contract in prose, but the actual `skills/implement/SKILL.md` per-task reviewer dispatch logic is a separate document that would need its own modification to actually route the DONE-report companion at dispatch time.

The silent failure design: `skills/implementer-protocol/SKILL.md` will declare "reviewer dispatches SHALL receive the DONE-report companion," but `skills/implement/SKILL.md`'s actual reviewer dispatch procedure is unchanged. Implement's per-task reviewer dispatch sites will emit DONE-report-less dispatch payloads. Reviewers will not receive unacknowledged hygiene hits. The T18 BATS pin only verifies the contract is stated in the protocol's prose — it cannot verify that the dispatch is wired.

This is the R1-F03 silent failure ("define the concrete reviewer-visibility mechanism") that was applied in round 1. The prose contract was added (T15 L558), and the T18 BATS pin verifies the prose exists (T18 L633). But the implementation in `skills/implement/SKILL.md` that would actually pass the DONE-report companion at dispatch time was never tasked.

**Fix:** Add a test expectation to T15 (or T18) that requires `skills/implement/SKILL.md` to document the DONE-report companion parameter in the per-task reviewer dispatch section, so the wiring is visible in the dispatch-facing skill body, not only in the protocol's prose. Alternatively, add a note to T05 or T27 (which both modify `skills/implement/SKILL.md`) specifying that the per-task reviewer dispatch extension to pass the DONE-report companion is part of that task's scope. Without a task that owns the `skills/implement/SKILL.md` dispatch-site wiring, the contract exists only in the protocol prose and is never connected to the actual dispatch path.
