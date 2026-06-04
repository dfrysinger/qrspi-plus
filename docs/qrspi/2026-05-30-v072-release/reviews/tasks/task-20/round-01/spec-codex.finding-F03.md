---
finding_id: R1-F03
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-20.md:14
  - docs/qrspi/2026-05-30-v072-release/reviews/tasks/task-20/round-01.diff:2515-4209
---
Advisory (target-files deviation): the task spec's target list names two dispatch test files, but this diff modifies many additional test files outside that list (broad collateral suite rewrites/skips/renames). Some may be necessary fallout, but the volume is significant; recommend either (a) retroactively expanding task-20 target files/scope rationale, or (b) splitting collateral test rewrites into a separate task to keep scope traceability tight.
