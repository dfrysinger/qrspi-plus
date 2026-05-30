---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: security-claude
---

Task 6 codex_reviews absent/empty case not specified for mismatch-diagnostic; potential fail-open on defense-in-depth signal

The mismatch-diagnostic is the operator-visible defense-in-depth signal per DKR6. It is only tested for the case where codex_reviews is present and conflicts with detected host. No expectation specifies behavior when codex_reviews is absent, empty, or unset.

In shell, unset compared against string typically equates to empty-string, which would silently suppress the diagnostic. An operator who forgets to set codex_reviews (or installs fresh) would receive no warning even with misdetected host.

Fix: Add expectation: "When codex_reviews is absent or empty in the config, the mismatch-diagnostic comparison does not silently evaluate as a match; either emit a diagnostic naming the missing key or fail-closed." Document whether absent codex_reviews is treated as fail-closed error or no-check pass.
