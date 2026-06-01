---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L78-L93
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L115-L128
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L131-L165
  - skills/phasing/owns-defers.md:L15-L18
artifact: phasing
round: 2
reviewer: scope-codex
---

## Phasing boundary drift: phasing.md contains Structure/Plan-level file-path and task-spec detail

**Summary.** `phasing.md` crosses the Phasing DEFERS boundary by specifying
concrete file paths, script names, helper/function-level surfaces, and
procedural test/task specs inside slices and the phase acceptance gate.

**Evidence.**

- Slice 1.4 names concrete files/surfaces: `run-codex-review.sh`,
  `using-qrspi/SKILL.md`.
- Slice 1.7 names helper/module paths: `test_helpers/extract.bash`,
  `_extract_h4`, `_extract_routing_block`.
- Phase 1 gate names executable/script/path specifics:
  `scripts/build-plugin.sh`, `~/.copilot/installed-plugins/...`.
- Acceptance criteria include ordered procedural trip-tests and
  implementation-level checks, which are task-spec detail.

**Boundary rule (from `skills/phasing/owns-defers.md`).**

DEFERS:
- File paths, module boundaries, interface contracts, file maps → owned
  by Structure.
- Task specs, LOC estimates, ordered task lists, per-task test
  expectations → owned by Plan.

**Required fix.** Rewrite slices and acceptance gate at phasing level
only: keep phase/slice intent, goal-ID grouping, and outcome-level
demonstrability criteria; remove concrete file/module pathing and
stepwise task/test execution detail (delegate those specifics to
Structure/Plan).

**Re-raise note.** This finding is a re-raise of round-01's scope-codex
finding (score 55, dropped below correctness threshold) with sharper
evidence and a higher severity classification.
