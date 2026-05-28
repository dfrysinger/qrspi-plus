---
finding_id: R3-F02
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/parallelization.md:L170
artifact: parallelize
round: 3
reviewer: quality-claude
---

The Stage Commits table row for `stage-after-W5` (line 170) describes its composition as "Merge of stage-after-W2 + Wave 3 + Wave 4 (task-11) + Wave 5 (task-12, task-27) task branches". This departs from the consistent incremental pattern used by every other row in the same table, which always builds on the immediately preceding named stage:

- `stage-after-W2`: "Merge of stage-after-W1 + all Wave 2 task branches"
- `stage-after-W3`: "Merge of stage-after-W2 + all Wave 3 task branches"
- `stage-after-W6`: "Merge of stage-after-W5 + Wave 6 task branches"
- `stage-after-W8`: "Merge of stage-after-W6 + Wave 7 (all 10 tasks) + Wave 8 (task-07, task-36) task branches"

The `stage-after-W5` row skips `stage-after-W3` and restates the full expansion from `stage-after-W2` forward, which is mathematically equivalent but harder to scan and inconsistent with the table's pattern. A reader expecting the pattern will need to re-read the row to confirm it is not an error.

Proposed fix: replace the `stage-after-W5` Composition value with "Merge of stage-after-W3 + Wave 4 (task-11) + Wave 5 (task-12, task-27) task branches" to restore the incremental pattern.
