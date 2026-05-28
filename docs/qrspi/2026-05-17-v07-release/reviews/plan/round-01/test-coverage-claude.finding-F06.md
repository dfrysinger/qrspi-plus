---
finding_id: R1-F06
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T20 and T21 include test expectations that describe live reviewer dispatch outcomes — not deterministic BATS-level assertions — making those expectations unverifiable in the test harness.

T20's fifth test expectation: "Re-dispatching the Parallelize scope reviewer against a worktree-aware parallelization artifact produces no scope-drift finding on the Worktree-Aware Setup Validation section."

T21's sixth test expectation: "Re-dispatching the Parallelize quality reviewer against a parallelization artifact that uses the canonical multi-stage suffix grammar produces no style finding; an artificially-introduced unconventional form (e.g., stageAfterWave4) still produces a style finding."

These expectations describe the behavior of a live LLM reviewer dispatch. They are not testable in a BATS unit test — they require running an actual LLM agent (qrspi-parallelize-reviewer, qrspi-quality-reviewer) against a fixture parallelization.md and observing the output. Such tests are:
- Non-deterministic (LLM output varies across runs)
- Not runnable in the bash32 CI job
- Not runnable in the unit BATS suite without mocking the entire reviewer dispatch stack

The BATS pin in T23 (test-parallelize-vocab.bats and test-parallelize-owns-defers.bats) covers the deterministic parts of these behaviors — asserting canonical tokens are present in skill files. The live-reviewer-dispatch expectations should either be dropped from T20/T21's test expectations (as they belong to a phase-level acceptance criterion, not a unit pin) or reworded as phase-acceptance criteria that apply at the Integrate step rather than in the unit BATS surface.

Retaining these expectations as written causes T20 and T21 to have test expectations that cannot be verified by the Test skill's BATS pin authoring process.
