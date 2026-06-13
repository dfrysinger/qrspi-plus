---
finding_id: R7-F01
severity: medium
change_type: clarity
referenced_files: ["plan.md:L1046"]
artifact: plan
round: 7
reviewer: test-coverage-claude
---

T19 atomic-write expectation says "a fixture that interrupts the script mid-write asserts the final report path either contains the complete report or does not exist." The observable is valid but the mechanism is not deterministically achievable in bats: timeout/SIGKILL approaches are scheduler-flaky; filesystem injection requires implementation-internal knowledge; process-pause hooks require modifying the production script.

The deterministic verification for a temp-file-rename pattern is structural: assert the script uses `mv <tmpfile> <final>` (or POSIX `rename` equivalent); POSIX rename(2) atomicity then provides the runtime guarantee.

Fix: replace "fixture that interrupts the script mid-write" with a structural-grep expectation locking the temp-file-rename pattern (greps the script body for the mv/rename call; the POSIX contract supplies atomicity).
