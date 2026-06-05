---
finding_id: R1-F01
reviewer_tag: silent-failure-codex
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F01 — `extract_frontmatter_field ... || true` swallows real read/parse errors

Lines 157, 190, 218. If awk fails for operational reasons (unreadable file, permission, transient FS), failure is suppressed and treated as missing/unparseable data (`missing_change_type`, `score_unparseable`), masking root cause.

Fix: distinguish "field absent in parseable file" from "read failure" — propagate the latter as a halt, only the former as missing.
