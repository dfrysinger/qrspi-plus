---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L28-L48, docs/qrspi/2026-05-17-v07-release/goals.md:L13-L19]
artifact: design
round: 3
reviewer: quality-codex
---

The design adds new `config.md` fields (`model_routing:` and `providers:`) but never specifies the runtime-backfill behavior required by the goals constraint for runs created before the fields existed. `goals.md` requires any new `config.md` field to support one-time runtime backfill plus warning for resumed runs, but the G1 recommendation and tests only cover schema validity, precedence, trusted paths, provider resolution, and predicates. As written, downstream Structure/Plan could implement these fields as hard-required config entries and break resumed artifact directories.

Fix: add an explicit compatibility/backfill subsection to G1 describing the default behavior for missing `model_routing:` and `providers:` in older resumed runs, including the warning behavior and whether absence means "trusted path only" or another safe default. Add a design-level test that exercises a legacy `config.md` without these fields and verifies the documented backfill/warning behavior.
