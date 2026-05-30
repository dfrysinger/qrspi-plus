---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: spec-claude
---

Task 6 mismatch-diagnostic test expectation: content pin removed without DKR6 justification

R3 changed "identifying both the detected host and the config value" to "identifying the disagreement". DKR6 intent is operator-actionable ("catches the misdetection that surfaced at config-time"). Without pinning that both detected-host value AND codex_reviews config value appear in message, implementer can satisfy with useless "[warn] host/config mismatch" and test still passes.

Fix: Restore message-content pin: "names both the detected host value and the codex_reviews config value (e.g., [warn] detected host=claude-code but codex_reviews=true)".

This is a legitimate test-coverage gap; DKR6's diagnostic intent IS about operator actionability, not just acknowledgment.
