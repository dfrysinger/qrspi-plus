---
finding_id: R2-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L820-L826]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T26 test expectations are all documentation-shape assertions with no behavioral test and no error-case test for the wave-termination rule. The five bullets for T26 check that the SKILL.md "documents," shows, "documents the canonical…note shape," and fires Red Flags entries. None of these is a behavioral test observable to a BATS harness.

T26 introduces a wave-termination rule — a reference-gated task ends its wave — whose behavioral effect is that no dependent task dispatches until the gate releases. The T30 pin bundle is supposed to cover "reference-gate-pause integration" as pin five, but T30's test expectations for the reference-gate-pause pin focus on the Implement-skill's pause behavior (T27's contract), not on Parallelize's wave-termination enforcement (T26's contract). The distinction matters: T26 is about Parallelize correctly computing the wave grouping such that reference-gated tasks terminate their wave, while T30 pin five is about Implement correctly blocking dependent dispatch until the approval file exists.

Missing from T26's test expectations: a behavioral test that a fixture `parallelization.md` produced by Parallelize for a plan containing a reference-gated task actually shows the gated task as the wave boundary (i.e., its dependents appear in the next wave, not the same wave). The Red Flags entries in T26's test expectations are prose checks, not behavioral assertions. The T30 reference-gate-pause pin could be cited here as the behavioral coverage — but T26's test expectations do not cross-reference T30 or name any BATS pin for behavioral coverage. Add an explicit cross-reference to T30 pin five as the behavioral test for T26, OR add a standalone behavioral expectation here (e.g., "A fixture plan with a reference-gated task T05 whose dependent is T06 produces a `parallelization.md` placing T05 in Wave 2 and T06 in Wave 3, with the canonical note on T05's wave boundary entry").
