---
finding_id: R2-F01
reviewer_tag: sf-claude
severity: medium
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md#L995-L1008
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2080
---

# Prose-template contradiction in Sub-Threshold Observations silently discards per-finding score precision

**SKILL.md L995 (prose):** "a `summary` one-liner, the contributing `finding_paths` … each finding's `defect_class` tag, **each finding's `score`**, and the `threshold` that dropped them"

**SKILL.md L997–L1008 (template):** flat shape with a single `score:` field and a single `defect_class:` field for the entire observation cluster — not one per contributing finding. Prior `contributing_findings` structure preserved per-finding scores (68, 70, 72, 75); replacement flat template records only one scalar.

**Silent failure mechanism:** Orchestrator following the example always produces a single `score:` value. Future cluster-analysis tooling reading `observations[*].score` expecting "each finding's score" receives only one data point per cluster — no way to detect precision loss; field present, value valid, omission invisible.

**AC5 test does not catch this** (line 2080): `grep -qE 'score:'` passes with a single `score: 70`. Confirms field exists but cannot verify per-finding scores preserved.

**Fix:** Either (a) restore per-finding scores via a `scores:` array or per-entry sub-list in `finding_paths`, OR (b) rename scalar to `representative_score:` and update prose to remove "each finding's score" so contract is unambiguous.

**Convergent with cq-claude R2-F01 (severity LOW there) — sf-claude promotes to MED because the precision-loss is observable in future tooling, not just a clarity issue.**
