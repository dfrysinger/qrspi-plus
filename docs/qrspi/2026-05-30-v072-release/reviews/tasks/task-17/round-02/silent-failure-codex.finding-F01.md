---
finding_id: F01
reviewer_tag: silent-failure-codex
round: 2
severity: medium
change_type: test-quality
referenced_files: [tests/unit/test-config-model-routing.bats]
---

# silent-failure-codex round-02 SF-01 — vacuous-row-count risk in validation-table assertions

(persisted by orchestrator; gpt-5.3-codex returned chat-only)

**Location:** tests/unit/test-config-model-routing.bats:734,744,755,767 (TE-1/TE-2/TE-3 row tests).

**Silent-failure risk:** The row-content tests extract the "row" via `grep "model_routing:"` over the entire H3 section (`extract_section ... "Fields that affect pipeline behavior (must be validated)"`), not an anchored markdown-table-row pattern. If the actual table row were removed/reformatted but a single non-table line in that section still contained `model_routing:`, the assertions could still pass and mask loss of the required table-row contract.

**Fix (additive test-only):** Anchor to the markdown table-row shape — e.g. grep for a leading `|` (`^[[:space:]]*\|`) so the row-count and row-content assertions run against table rows only, not post-table prose.

**Disposition:** KEEP — dual-Codex corroborated (cq-codex F01 identical, same lines).
