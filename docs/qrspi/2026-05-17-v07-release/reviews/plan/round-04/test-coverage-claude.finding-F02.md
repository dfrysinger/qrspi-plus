---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L992-L1002]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T32 BATS pin test expectations cover that `plan.md` retains `status: draft` after a fan-out failure (line 999: "plan.md retains `status: draft`"), and that `phase_start_commit:` is present after a successful approval (line 1000). However, the test expectations do NOT specify what `phase_start_commit:` should be after a failed split.

The concern is the ordering of main-chat transactional steps: the T31 section (line 969) states the steps in order — (1) collect confirmations, (2) verify file count, (3) rewrite plan.md to overview-only, (4) capture `phase_start_commit:`, (5) write `status: approved`. If a failure occurs between step 3 and step 5 (after capturing `phase_start_commit:` but before writing `status: approved`), plan.md could end up in a state with a non-null `phase_start_commit:` but `status: draft`. The atomicity test at line 999 only asserts `status: draft`; it does not assert that `phase_start_commit:` is null/absent, which means the partial-state scenario is not caught.

The T32 BATS pin should add an assertion: after a simulated sub-subagent failure that leaves `plan.md` unapproved, `plan.md`'s frontmatter does NOT contain a non-null `phase_start_commit:` value (or equivalently, that if a `phase_start_commit:` was captured mid-transaction it is reverted along with the status rollback). This closes the observable ambiguity where a "draft" plan carries a commit SHA that was recorded mid-transaction.

Fix: Add to T32's test expectations: "The BATS pin asserts that after a simulated sub-subagent failure, `plan.md` frontmatter does not contain a non-null `phase_start_commit:` value — either the field is absent or its value is `null`, confirming the transactional rollback covers all approval-state fields, not only `status:`."
