---
finding_id: F01
reviewer_tag: code-quality-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:43-54
---
Host-aware validation is bypassed when a vendor override is provided. On an unknown host, passing
a recognized vendor (e.g. openai-codex) returns success because the check only validates
`vendor != none` and `second_reviewer_vendor_known`, not host compatibility. (Duplicate of
spec-codex.F01 under code-quality framing.)
