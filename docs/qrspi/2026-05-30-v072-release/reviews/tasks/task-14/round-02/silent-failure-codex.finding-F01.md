---
finding_id: R2-F01
severity: medium
change_type: clarity
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---
title: Grep pin shape is loose; could mask spec regressions via incidental matches
evidence:
  - severity/change_type matcher at lines 303-308 is file-wide grep, not anchored to sweep-task rule block
  - malformed-variant pin at lines 310-316 uses broad alternation that could match incidental wording
  - backstop pin at lines 318-327 unanchored to specific subsection
disposition: DISMISSED-spec-prescribed
disposition_reason: |
  T14 spec § Test expectations literally begins each bullet with "Inspect..." — grep-based pinning IS the spec's stated test shape. Existing [T30-rg-pause] pins in the same file follow the same loose-grep convention. Tightening to anchored block matchers would be a substantive test-shape refactor.
backlog: v0.7.3 — consider tightening grep pin shape across QRSPI bats tests to anchored/block-scoped matchers.
