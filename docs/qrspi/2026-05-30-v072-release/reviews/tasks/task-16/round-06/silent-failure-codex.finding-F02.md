---
finding_id: R6-F02
reviewer_tag: silent-failure-codex
round: 6
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh:140]
---

# silent-failure-codex F02 — duplicate tier rows silently first-win

Tier row lookup uses `grep ... | head -1` (L140), so duplicate tier rows under
`model_routing:` are silently accepted and first-match wins. A misconfigured
`model_routing` block (two `medium:` rows) produces a mapping with no
diagnostic.

**Impact:** wrong mapping from a malformed config without any loud signal.

**Orchestrator adjudication: DEFER to v0.7.3 backlog (D4).** Duplicate-key
detection requires match-counting logic (new behavior, not an additive guard on
the existing path). First-wins is at least deterministic, and duplicate YAML
keys are operator error that most YAML parsers accept (last/first wins). Out of
scope for this G7b/#204 none-halt + injection hardening task; tracked as a
config-hygiene backlog item.

Chat-only return persisted by orchestrator.
