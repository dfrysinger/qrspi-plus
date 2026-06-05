---
finding_id: R1-F01
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: goals
round: 1
reviewer: quality-codex
---

In at least two goals, the **"What we know so far"** section states a solution as effectively pre-decided instead of framing it as candidate options for Design to weigh:

- **G23**: "Mechanical addition: one row in the validation table plus cross-link annotations…" (lines ~687–689)
- **G26**: "Mechanical fix per bats docs — replace shebang." (lines ~757–760)

This violates the goals-quality requirement that solution content in "What we know so far" be framed as candidate approaches, not commitments. Rewrite these to candidate framing (e.g., "Candidates Design should weigh…") even if one option is strongly preferred.
