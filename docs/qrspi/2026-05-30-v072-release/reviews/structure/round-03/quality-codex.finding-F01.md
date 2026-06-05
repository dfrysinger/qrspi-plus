---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [structure.md]
line_range: 104-129
---
Slice 1.5's file map omits `agents/qrspi-design-scope-reviewer.md`, even though the same artifact later treats that file as an implementation surface for G34 include wiring (`Hook-Point Locations`, lines 704-706). This leaves one design-required component outside the slice map, which weakens vertical-slice completeness and can cause planning/execution gaps.
