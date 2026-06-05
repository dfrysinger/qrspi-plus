---
reviewer_tag: code-quality-claude
round: 4
finding_id: R4-F01
severity: low
change_type: style
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F01 — R4/F01 tokens in new test comments (ID hygiene)

R4 added 5 comment lines embedding QRSPI run-specific tokens (`R4`, `F01 sec-claude`, `F01 sec-codex`):
- L275, L351, L387: "Updated in R4"
- L362: "F01 sec-claude"
- L370: "F01 sec-codex"

Distinct from pre-existing test-name [G15-sweep] pattern. These are NEW R4-introduced violations in COMMENTS.

**Fix:** Rewrite each comment in terms of WHY (threat/behavior) rather than review-artifact reference. ~6 line edit. Surgical.
