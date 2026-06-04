---
finding_id: F03
severity: HIGH
change_type: correctness
referenced_files:
  - scripts/dispatch-companion.sh:640-647
disposition: ACT (closed in fix-cycle 7, commit cdf252d)
reviewer_tag: sec-codex
round: 7
---

R6 fix-cycle 6 introduced mkdir-before-assert to satisfy BSD realpath existence requirement, but this created out-of-repo filesystem state on rejected --round-dir inputs (partial-state DoS / unauthorized directory creation). Closed in fix-cycle 7 via two-stage guard: assert_ancestor_under_repo_root (pre-mkdir) + assert_path_under_repo_root (post-mkdir).
