---
finding_id: R2-F02
reviewer: silent-failure-claude
task: 29
round: 2
severity: low
change_type: clarity
referenced_files:
  - tests/lint/test-design-altitude-boundary-include.bats
---

# F02 — LOW — Test 4 inline-body grep patterns under-detect paraphrased re-inlining

The patterns catch headings/intro lines (`^### Design OWNS`, `**Design OWNS:**` etc.) but not bullet bodies. The test's leading comment promises "drift that re-inlines OWNS/DEFERS bullets or headings" — implementation only checks heading/intro lines. A drift that re-inlines bullet bodies alongside the `!cat` would pass.

**Recommended fix:** either tighten the comment to "OWNS/DEFERS section markers", or add a positive-form check (post-`!cat`, the consumer should contain zero lines matching `^- ` markdown bullets, OR a `wc -l` upper bound).
