---
finding_id: F03
reviewer_tag: code-quality-codex
round: 3
severity: low
change_type: test-quality
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Temp-dir cleanup not failure-safe: `rm -rf "$tmpdir"` (lines ~353-384) runs only at test end; an earlier assertion failure skips cleanup. Use bats `teardown`/`trap` for deterministic cleanup.
