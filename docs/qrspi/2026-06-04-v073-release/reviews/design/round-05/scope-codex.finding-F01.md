---
finding_id: R5-F01
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/design.md:L13-L55
  - docs/qrspi/2026-06-04-v073-release/design.md:L196-L219
  - docs/qrspi/2026-06-04-v073-release/design.md:L319-L385
  - docs/qrspi/2026-06-04-v073-release/design.md:L487-L563
artifact: design
round: 5
reviewer: scope-codex
---

This design artifact repeatedly crosses into Design DEFERS territory by prescribing file architecture and implementation-surface placement ("which file/script owns which behavior," exact new file paths under `scripts/`, `skills/_shared/`, `tests/lint/`, `docs/...`, and concrete per-file wiring). Under the OWNS/DEFERS contract, Design should keep these at outcome/component-purpose altitude; file-placement/module-boundary decisions belong to Structure, while detailed implementation wiring belongs downstream. Keep the decisions/invariants (what must happen, why, acceptance shape) in design.md, but move or defer exact file/directory assignment and concrete script placement mandates.
