---
finding_id: R2-F02
severity: medium
change_type: intent
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
reviewer_tag: code-quality-codex
---
Lines 220, 241, 274 carry `# F02: ...` QRSPI-internal finding-ID tracker tokens in test
comments. Per ID-hygiene rules, internal finding IDs must not leak into code/test surfaces
outside docs/qrspi/. Rewrite the comments to describe the behavior without the F-id prefix.
