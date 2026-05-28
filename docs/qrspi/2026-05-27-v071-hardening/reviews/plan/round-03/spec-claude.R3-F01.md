---
finding_id: R3-F01
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: spec-claude
---

detect_host empty-string case falls between two bullets

Bullet 2 covers "unset"; bullet 3 says "any non-empty value other than 1" but then lists `COPILOT_CLI=""` as a covered example. `COPILOT_CLI=""` is set-but-empty, not non-empty. A test writer reading literally will skip `""` as contradicting "non-empty".

This is the edge that distinguishes `if [ "$COPILOT_CLI" = "1" ]` (correct) from `if [ -n "$COPILOT_CLI" ] && [ "$COPILOT_CLI" = "1" ]` (subtle misimplementation).

Fix: replace "non-empty value other than 1" with "value other than 1" and explicitly list empty string as a covered example.
