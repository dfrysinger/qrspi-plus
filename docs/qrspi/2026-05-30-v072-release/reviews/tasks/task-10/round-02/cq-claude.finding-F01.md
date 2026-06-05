---
finding_id: R2-F01
reviewer_tag: cq-claude
severity: low
change_type: clarity
referenced_files:
  - skills/using-qrspi/SKILL.md#L995
---

# Prose says "each finding's score" but template shows a single scalar

The prose at line 995 reads: "…a `summary` one-liner, the contributing `finding_paths` …, **each finding's `defect_class` tag, each finding's `score`**, and the `threshold` that dropped them…"

The canonical YAML example immediately below (lines 997–1008) shows a single `score: 70` at the observation level — not a per-finding list.

The old R1 template had per-finding scores (68, 70, 72, 75) inside `contributing_findings`, which was explicit at the cost of nesting. The new flat shape lost that resolution and replaced it with a single `score: 70` whose semantics are undefined: minimum? maximum? exemplar? average? The prose phrase "each finding's score" implies per-finding data and directly contradicts the single-scalar template.

An orchestrator following the prose description would be uncertain whether to write one score or several, and which score to pick for a cluster with mixed scores.

**Fix:** Either (a) update the prose from "each finding's `score`" to "the representative (e.g., minimum) `score` in the cluster" to match the single-scalar template, or (b) annotate the example value with a comment like `score: 70  # minimum score in cluster` to make the semantic explicit.
