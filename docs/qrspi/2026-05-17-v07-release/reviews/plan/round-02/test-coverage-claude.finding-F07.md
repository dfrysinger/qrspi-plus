---
finding_id: R2-F07
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L946-L952]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T31 test expectations are entirely documentation-shape assertions about what `skills/plan/SKILL.md` "documents," "enumerates," "preserves," "states," and "reuses." None of the six T31 test expectations describes a behavioral test observable by any test harness.

The design.md G3 test strategy requires: a multi-task test, a single-task test, a boundary test (N=2), a transactional test (plan.md approved only when all task files exist), and a `phase_start_commit:` test. These behavioral tests are all assigned to T32's BATS pin. However, T31 and T32 are independent tasks — T31 authors the orchestration section, T32 authors the contract document and the pin. If T31's implementation is done without T32 passing (e.g., if T32's BATS pin is written but the pin fails to observe T31's section because T31 authors a non-standard N-threshold), the defect lives in T31 but is only observable via T32.

T31 should carry at least one behavioral test expectation that is independently observable — not deferred entirely to T32. Acceptable addition: "A fixture approved `plan.md` with N=3 tasks, processed through the T31 orchestration section, produces exactly three `tasks/task-NN.md` files and an overview-only `plan.md` with `status: approved` and `phase_start_commit:` set" — this can be verified by T32's BATS pin but should be declared in T31's test expectations with a cross-reference to T32's pin as the observing test. As written, T31's test expectations are purely documentation assertions that would all pass if the orchestration section exists with the right words but contains a logic error in the N-threshold branching.
