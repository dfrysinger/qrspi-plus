---
finding_id: F01
severity: medium
change_type: silent_failure
referenced_files:
  - scripts/dispatch-agent.sh
---

Batch-mode --artifact path string skips reject_if_path_unsafe_for_emission.
The single-mode guard added in fix-cycle 10 covers PRIMARY_PATHS,
TASK_DEF, COMPANION_PATHS, DIFF_FILE — but BATCH_ARTIFACT (lines 713-717)
emits the raw path string into the prompt skeleton via
`<<<UNTRUSTED-ARTIFACT-START id=%s>>>` with only existence and
boundary checks. A repo-local file with a newline-bearing filename
remains exploitable through the batch surface.

Cross-references sec-codex R10 F01 (same root cause).
