---
finding_id: R11-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L2673, docs/qrspi/2026-05-30-v072-release/structure.md:L2691, docs/qrspi/2026-05-30-v072-release/structure.md:L2710]
artifact: structure
round: 11
reviewer: scope-claude
---

Per-task LOC estimates appear inside three Slice-1.7 per-file specification blocks. The Structure OWNS/DEFERS contract (`skills/structure/owns-defers.md`, DEFERS list) explicitly routes "Per-task LOC, full assertion text, per-task commit ranges, line-by-line logic" to Plan / Implement. These are unambiguous DEFERS-list items, not borderline cases.

The three citations:

1. **L2673** — `tests/lint/test-structure-altitude-boundary-include.bats` Responsibility paragraph ends with the literal sentence `~6 LOC.` This is a per-task LOC estimate on a single test file authored by Plan/Implement; it is not a structural commitment (no other file imports or depends on the test's line count) and not an interface contract.

2. **L2691** — `tests/unit/test-using-qrspi-vocab.bats` **Tests:** bullet contains: `Net diff ≤ 20 lines for the G24 rewrite (4 assertion sites × ~3-5 lines each including the G21 guard wrapper).` This combines a hard LOC ceiling per task (`≤ 20 lines`) with per-assertion-site line-count math (`~3-5 lines each`) — both are line-by-line logic that Plan partitions and Implement authors. The companion sentences `No new shared helper file. No new bats utility.` are scope-bounding statements (Structure-acceptable) and may stay; the LOC math is what drifts.

3. **L2710** — `tests/lint/test-bats-body-assertion-guard.bats` **Tests:** bullet contains the parenthetical `(parallel rule in the same lint file, ~30 additional lines)`. Same boundary class — per-task incremental LOC estimate for a sub-rule inside a single lint file. The structural commitment (one lint file holds both rules; no sibling file) is Structure-territory and may stay; the `~30 additional lines` figure is the drift.

Why this matters under the expanded scope. The user's R11 scope expansion authorizes per-file blocks, verbatim payloads lifted from design.md, and outline-only constraints — none of which require LOC estimates to function. A per-file block can name its responsibility, interface, test-coverage boundary, and !cat hook points without committing to a line-count budget. Plan's sizing rubric (LOC ceiling, files-in-scope count, sizing exceptions) operates against the realized task spec, not against structure.md's per-file row; pre-committing a LOC ceiling in structure.md duplicates plan-altitude judgment in an artifact whose readers (architect-mode review, structure-reviewer stitching audit) have no use for it.

Fix shape (Plan/Implement DEFERS the LOC math; Structure may keep the structural-commitment companion sentences):

- **L2673**: delete the trailing `~6 LOC.` sentence. The preceding sentence (`Drift-via-subtraction is the only failure surface — single source = no content drift possible …`) carries the structural commitment by itself.
- **L2691**: replace `Net diff ≤ 20 lines for the G24 rewrite (4 assertion sites × ~3-5 lines each including the G21 guard wrapper).` with a scope-bounding sentence that names the surface without sizing it — e.g., `Scope: the four contract sites at L132/L157/L183/L213 (already enumerated above), each rewritten in place; no other sites touched. No new shared helper file. No new bats utility.`
- **L2710**: change the parenthetical to a structural commitment without the LOC figure — e.g., `(parallel rule in the same lint file, separate `@test` blocks from the G21 rule)` or simply `(parallel rule in the same lint file)`.

This is a scope finding, not a quality finding — the boundary-drift surface is the rule contract in `skills/structure/owns-defers.md`, not the prose quality of the affected sentences.
