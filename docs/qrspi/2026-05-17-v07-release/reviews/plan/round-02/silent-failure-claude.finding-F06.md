---
finding_id: R2-F06
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L946-L980]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T31 and T32 describe the post-approval split verification step as: "verify the resulting `tasks/task-NN.md` file count matches the expected task count." T32's BATS pin asserts "produces exactly two `tasks/task-NN.md` files" (N=2 case) and "produces exactly three `tasks/task-NN.md` files" (N=3 case).

This is a count-only verification. It passes even when:
- Two sub-subagents both receive the same wrapped task section (dispatch bug) and both write `tasks/task-01.md`, overwriting each other, while `tasks/task-03.md` is never created — the task directory has N files but the wrong set.
- A sub-subagent writes `tasks/task-10.md` for task ID 01 (numbering mismatch) and another writes `tasks/task-01.md` for task ID 10 — both end up in the directory; count is N; but the files are inverted.

In both cases, the main-chat transactional step "verify file count matches expected task count" passes, `status: approved` is written, and the downstream Implement skill dispatches task specs from the wrong files without knowing the IDs are mismatched.

T32's contract document does declare "exactly one `tasks/task-NN.md` per dispatch with NN matching the wrapped task ID" as a per-sub-subagent output contract — but neither the T31 test expectations nor the T32 BATS pin test expectations require that the main-chat verification step checks task-ID coverage (i.e., that the set of files `{task-01.md, task-02.md, ..., task-N.md}` is exactly the expected set, not just that N files exist).

Resolution: Add a test expectation to T31 (or T32's BATS pin) requiring that the verification step checks the exact set of task-ID files present — specifically that the set `{task-01.md, ..., task-N.md}` is complete with no duplicates and no missing IDs — rather than only verifying the count. The T32 BATS pin should exercise a fixture where two sub-subagents receive the same task section and assert that the duplicate-ID condition is detected and surfaces a loud diagnostic, aborting the split.
