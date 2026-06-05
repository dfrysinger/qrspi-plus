---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

## F04 — Partial-crash and complete re-run behavioral assertions miss required outcomes

Spec requires:
- Partial-crash recovery should dispatch only missing files, preserve existing matching files (no rewrite), and pass exact-set once complete — task-34.md line 52.
- Complete re-run with all matching hashes should dispatch zero and proceed to approval completion — line 53.

Implemented tests:
- Partial-crash test (lines 556-601): asserts only one missing dispatch count, no explicit no-rewrite check (mtime/content preservation) and no "exact-set passes once completed" check.
- Complete re-run test (lines 607-650): asserts only `dispatch_count=0`, no approval-state completion assertion tied to this scenario.
