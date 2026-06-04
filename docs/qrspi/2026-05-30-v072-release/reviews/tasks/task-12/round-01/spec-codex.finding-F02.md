---
finding_id: R1-F02
severity: high
change_type: correctness
referenced_files:
  - scripts/round-prepare.sh
reviewer_tag: spec-codex
---

Convergence logic does not implement explicit full-artifact scope-set ⇒ broaden rule.

Spec (tasks/task-12.md:40, 53): broaden on missing/empty/full-artifact/superset/overlap/disjoint; narrow only equal or proper-subset-with-safety-margin.

Observed (scripts/round-prepare.sh:232-254, 268-270): decide_narrow() only checks file presence/emptiness and set relations; no explicit full-artifact sentinel handling before allowing equal/proper-subset narrowing.

Impact: interpretation/completeness risk for full-artifact case.
