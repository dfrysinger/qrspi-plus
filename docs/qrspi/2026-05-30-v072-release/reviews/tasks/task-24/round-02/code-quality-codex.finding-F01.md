---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
reviewer_tag: code-quality-codex
---
Line 309: `echo "$output" | grep -qv '^DETECTION_TYPE=llm-context$'` is an always-true
negative assertion — `grep -qv` exits 0 if ANY line fails to match, which is always the
case in multi-line output. It cannot detect DETECTION_TYPE=llm-context being present.
Fix: `! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'` or add a positive
assertion for DETECTION_TYPE=user-override-only.
