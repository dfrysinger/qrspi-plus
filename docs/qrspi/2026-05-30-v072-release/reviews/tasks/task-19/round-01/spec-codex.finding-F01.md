---
finding_id: F01
reviewer_tag: spec-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-19.md:L42-L43
  - scripts/second-reviewer-available.sh:L43-L55
  - tests/unit/test-second-reviewer-available.bats:L287-L311
---
Task 19 requires unavailable vendor paths to fail with a `[second-reviewer-unavailable]`
diagnostic, but `second-reviewer-available.sh` only rejects `vendor=none` or unknown vendor
IDs. With a known override vendor, it never validates host+vendor availability, so unavailable
override cases can incorrectly pass. The tests also only cover unknown-vendor override, not a
distinct unavailable-vendor override path.
