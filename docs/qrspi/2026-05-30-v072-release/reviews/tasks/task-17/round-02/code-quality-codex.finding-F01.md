---
finding_id: F01
reviewer_tag: code-quality-codex
round: 2
severity: medium
change_type: test-quality
referenced_files: [tests/unit/test-config-model-routing.bats]
---

# code-quality-codex round-02 F01 — row-uniqueness assertion not scoped to table rows

(persisted by orchestrator; gpt-5.3-codex returned chat-only)

**Location:** tests/unit/test-config-model-routing.bats:732-735 (TE-1 "exactly one `model_routing:` row").

**Message:** The "exactly one `model_routing:` row" assertion counts all matching lines in the entire H3 section, not table rows specifically. Because `extract_section(..., "H3", "Fields that affect pipeline behavior (must be validated)")` includes any post-table prose too, this is brittle and can fail (or pass) for unrelated mentions of `model_routing:`. Scope the grep to markdown table rows (e.g. `^\|`) and/or the Field column to validate row uniqueness reliably.

**Disposition:** KEEP — dual-Codex corroborated (silent-failure-codex SF-01 identical, same lines). Additive test-only fix.
