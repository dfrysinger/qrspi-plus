---
reviewer_tag: spec-codex
round: 4
finding_id: R4-F01
severity: high
change_type: correctness
status: adjudicated-spec-interpretation
---

# F01 — Canonical grep shape changed to add `--` separator

**Adjudication: ADJUDICATED-spec-interpretation.** spec-claude returned CLEAN characterizing `--` addition as in-scope narrowing of T14's grep-shape requirement. sec-codex R3 F01 HIGH mandated argument-injection hardening. The `--` separator preserves the spec invariant (zero-match grep against tests/) while closing the security gap. Backlog: v0.7.3 may update T14 spec text for literal-shape alignment.
