---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F03
change_type: clarity
---

# G7 Acceptance bats fixture named "two-commit-per-round repo" uses obsolete shape terminology

## Location

design.md L451 (G7 Acceptance bullet — bats coverage).

## Finding

Round 10 updated the G7 narrative from "two-commit-per-round" to "one-commit-per-round" (L431, citing research Q13/Q14). But the bats fixture name in the Acceptance block was not updated:

> - Fixture two-commit-per-round repo: anchor-file-based diff returns the correct content (round N's fix commit's diff), `HEAD~1`-based diff returns empty (regression-guard against the v0.7.2 shape).

Two issues:

1. **Fixture name carries shape terminology that contradicts the design**: The design now asserts (L431) that the existing shape is one-commit-per-round per Q13/Q14. A fixture named "two-commit-per-round repo" then either contradicts that assertion OR is intentionally constructing a regression-guard against the v0.7.2 shape. The latter reading is consistent with the trailing parenthetical "regression-guard against the v0.7.2 shape" — but the fixture name and intent should be made explicit to avoid the impression of contradiction.
2. **Intent ambiguity**: If the fixture's job is to reproduce the v0.7.2 shape as a regression-guard, the fixture name should make that explicit (e.g., "v0.7.2-shape two-commit-per-round repo" or "multi-commit-between-rounds fixture"). As written, an implementer might reasonably ask "is this the current shape or a constructed bad shape?"

This finding is downstream of F01 — if F01 is resolved by reframing the bug premise (e.g., "ANY unrelated commit between rounds breaks `HEAD~1`"), the fixture might be better named for that more general failure mode.

## Expected fix

Rename the fixture in L451 to something like:

> - Fixture with an unrelated commit between rounds (reproduces the v0.7.2 two-commit-per-round shape as a regression-guard): anchor-file-based diff returns the correct content (round N's per-round commit diff), `HEAD~1`-based diff returns empty.

Or, after F01 is resolved, align the fixture name with the corrected bug-premise framing.
