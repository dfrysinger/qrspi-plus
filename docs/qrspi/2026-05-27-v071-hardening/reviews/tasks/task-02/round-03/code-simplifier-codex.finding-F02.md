---
reviewer: code-simplifier-codex
task: 2
round: 3
finding: F02
severity: suggestion
change_type: style
status: advisory-not-applied
model: gpt-5.3-codex
timestamp: 2026-05-28T16:50:00Z
agent_id: t02-r3-code-simplifier-codex
orchestrator_decision: noted, not applied — see F01 rationale; same reviewer-disagreement deferral applies.
---

# F02 — Suggestion: use grep -qxF instead of grep -E "^pattern$"

## Location

`tests/unit/test-commit-hygiene-invariants.bats` (lines 233 and 273-ish for the exact-line matches)

## Suggested simplification

Replace `grep -E "^\.qrspi-commit-msg\.txt$"` with `grep -qxF '.qrspi-commit-msg.txt'`. Avoids regex escaping while preserving exact-line semantics.

## Orchestrator decision

Not applied. The non-quiet final grep on line 283 is intentional per Claude code-simplifier round-03: aids failure diagnosis when the assertion fires. Replacing with `-qxF` would suppress diagnostic output. F01's rationale also applies.
