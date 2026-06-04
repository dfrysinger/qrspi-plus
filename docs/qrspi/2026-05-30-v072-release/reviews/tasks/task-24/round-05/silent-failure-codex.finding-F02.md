---
finding_id: F02
severity: low
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
New no-file-write Claude test (lines 604-617) counts regular files at `-maxdepth 1` only; could miss nested writes or non-regular artifacts. Recommendation: check recursively and/or assert directory tree unchanged. NOTE (orchestrator): valid, additive. The script does no file I/O at all (sec-CLEAN x2), so risk is theoretical. Accepted-with-issue (cap already bent).
