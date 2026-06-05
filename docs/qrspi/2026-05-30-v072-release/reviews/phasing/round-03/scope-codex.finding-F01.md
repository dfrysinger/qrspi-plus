---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L47-L130
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L144-L167
artifact: phasing
round: 3
reviewer: scope-codex
---

## Residual phasing boundary drift after R2 fix

Residual boundary drift remains: several slice surfaces and
acceptance-gate checks still specify implementation/task-detail internals
(e.g., named scripts/helpers, config keys, H4-paragraph edit surfaces,
and detailed instrumentation mechanics). Under Phasing DEFERS, these
details belong to Structure/Plan/Implement/Test. Keep phasing at
phase/slice outcome boundaries (what is demonstrably delivered), and
move mechanism-level specifics to downstream artifacts.
