---
finding_id: F01
reviewer_tag: silent-failure-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:43-59
---
second-reviewer-available.sh can return success on an unsupported host when a known vendor
override is passed. With no host signal (detect_host => unknown), `<vendor>=openai-codex` skips
the default-none path and passes second_reviewer_vendor_known, so it prints a vendor and exits 0
instead of failing with [second-reviewer-unavailable]. (Duplicate of spec-codex.F01 / cq-codex.F01.)
