---
finding_id: R3-F01
reviewer_tag: test-coverage-claude
round: 3
severity: low
change_type: correctness
referenced_files: [tests/unit/test-config-model-routing.bats]
---

# R3-F01 — TE-1 count grep matches `model_routing:` in any column, not just the field-name column

**Severity:** low · **Change type:** correctness (test robustness)
**Location:** `tests/unit/test-config-model-routing.bats` L734 (count grep); same any-column anchor reused at the TE-2/TE-3 row-extraction greps L744, L755, L767.

**Finding (from test-coverage-claude, round-03):** The "exactly one `model_routing:` row" assertion uses `grep -cE '^[[:space:]]*\|.*model_routing:'`, which matches `model_routing:` anywhere in a table-row line, not just the first (field-name) column. It is currently correct (count == 1) because no other row's value cell mentions `model_routing:`. But the `model_routing:` row's OWN value cell contains the literal `model_routing:` three times (it cross-references the schema heading), and if a future edit added `model_routing:` to another row's value cell, the count==1 assertion would silently become a false positive — weakening the exact invariant TE-1 exists to protect.

**Recommended fix (test-only, additive precision):** Anchor the four row-matching greps (L734 count + L744/L755/L767 extraction) to the first cell:
`^[[:space:]]*\|[[:space:]]*`?model_routing:`?[[:space:]]*\|`
(optional backticks + trailing first-cell pipe). Empirically verified: matches exactly the one production row (count == 1, non-vacuous) AND rejects a negative-control row whose value cell merely mentions `model_routing:` (count == 0). Extraction greps still return the full row line; downstream content assertions unchanged.

**Class:** same anchoring-robustness trajectory as the round-02 dual-Codex finding (bare → table-row-shape anchor); this is the next level (any-column → first-column). Adopted under blanket cap-bend-for-quality authority; surgical, no production-doc change.
