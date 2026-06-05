---
artifact: structure
reviewer_tag: quality-claude
finding_id: R3-F01
round: 3
severity: medium
change_type: correctness
line_range: [556, 566]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## G25 absent from T1 (Unit tests) Feeds list despite having a unit test in the file map

### Location

`## Test Architecture` → `### T1 — Unit tests`, line 560:

```
Feeds: G6, G7, G8, G11, G13, G14, G16, G17, G19, G20, G21, G22, G23, G24, G26, G27, G28, G31, G32, G34, G35.
```

### Problem

G25 is absent from T1's Feeds list, but Slice 1.4's file map (line 93) assigns `tests/unit/test-config-model-routing.bats` to **G22, G23, G25** — all three goals together. G22 and G23 appear in the T1 feed list; G25 does not. This creates an asymmetry: two goals sharing the same unit test file are included, while the third is silently dropped from the test-type coverage taxonomy.

G25's design block (design.md lines 2091–2127) confirms that G25's executable enforcement is "a single bats smoke test invoking `dispatch-agent.sh` against a `config.md` fixture" — the same test pattern as `test-config-model-routing.bats`. The smoke test is classified as a CD-1 acceptance criterion but rides in the `tests/unit/` bucket per the file map assignment.

### Impact

An implementer constructing the T1 test gate will see G22 and G23 as required T1 coverage targets but will have no signal that G25 also belongs to T1. G25 is covered by T6 ("G1–G35") but T6 is the self-host run — losing the T1-level traceability means the goal's unit-gate coverage goes unverified before T6.

### Fix

Add `G25` to the T1 Feeds list at line 560, between `G24` and `G26` (to preserve numeric order):

```
Feeds: G6, G7, G8, G11, G13, G14, G16, G17, G19, G20, G21, G22, G23, G24, G25, G26, G27, G28, G31, G32, G34, G35.
```
