---
finding_id: F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
New Claude output-shape test (lines 546-557) is vacuous if stdout is empty: the `while read` loop executes zero iterations and passes, so a regression where the script exits 0 but emits no lines would go undetected. Recommendation: assert a required field (e.g. `PLATFORM=`, `DETECTION_TYPE=`) is present, or line count > 0, before the loop. NOTE (orchestrator): valid, additive one-line assertion. Risk partially mitigated — sibling tests already assert specific Claude-branch field content, so an empty-output regression would be caught elsewhere. Accepted-with-issue (cap already bent; see review log).
