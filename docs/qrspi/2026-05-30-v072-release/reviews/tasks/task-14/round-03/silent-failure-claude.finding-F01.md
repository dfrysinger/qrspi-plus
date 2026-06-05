---
reviewer_tag: silent-failure-claude
round: 3
finding_id: R3-F01
severity: low
change_type: correctness
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F01 — metachar pin only asserts word presence, not list completeness

**Location:** `tests/integration/test-reference-gate-pause.bats:347-352`

**Issue:** The R3 `metachar` pin test passes when the word "metachar" appears anywhere in the rubric prose — it does NOT assert that the rejected-character enumeration contains any specific character. Drift could remove individual chars from the list (or fail to add new ones like `'`) without failing this test.

**Severity:** low (shape check is the primary injection guard; metachar list is defense-in-depth — but absence of `'` enables sec-claude F01).

**Fix:** Tighten the pin to require at least 2-3 specific named characters (e.g., `;`, `|`, `&`) AND add a separate pin asserting `'` (single quote) appears in the list. Companion to sec-claude F01.
