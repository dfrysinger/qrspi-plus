---
finding_id: F01
severity: HIGH
change_type: correctness
referenced_files:
  - scripts/dispatch-companion.sh:640-647
disposition: ACT (closed in fix-cycle 7, commit cdf252d)
reviewer_tag: sf-codex
round: 7
---

Same as sec-codex F03 — duplicate flag (independent confirmation). Partial-state-on-failure: failed launch left out-of-repo directory creations behind. Fix-cycle 7 closes via two-stage ancestor+canonical guard.
