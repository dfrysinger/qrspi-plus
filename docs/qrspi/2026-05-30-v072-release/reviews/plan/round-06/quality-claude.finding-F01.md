---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
---

# Finding F01 — T19 missing `Dependencies: Task 16` after round-05 halt-move

## Location

- `plan.md` task list, **L65** — `Task 19 — G27 ... — deps: none`
- `plan.md` per-task spec, **L1103** — `**Dependencies:** none. **Blocks:** Task 20.`
- (symmetric) `plan.md` per-task spec, **L974** — `Task 16 ... **Blocks:** T17 (...)` (does not list T19)

## What's wrong

T19 declares `Dependencies: none`, but T19 cannot start independently of T16:

1. **File-creation ordering.** T16's target files include `create/modify scripts/_resolve-lib.sh` (L973) and T16's In-scope language is "Create/update `scripts/_resolve-lib.sh`" (L986). T19's target files include `scripts/_resolve-lib.sh` (L1102) and T19's In-scope language is "**Extend** `scripts/_resolve-lib.sh` with the host × vendor matrix and default-second-reviewer lookup helpers" (L1116). T19 cannot extend a file that T16 hasn't created yet. If an implementer picks up T19 before T16 lands, T19 either stubs `_resolve-lib.sh` (conflicting with T16's later creation) or fails entirely.

2. **Same-file-edit merge-conflict trap on the test surface.** Both T16 and T19 modify `tests/unit/test-routing-matrix-application.bats` (T16 L973; T19 L1102). T16's test coverage pins "per-tag tier overrides, `none`-tier halt behavior, and implementer/test-writer co-escalation" (L991). T19's test coverage at L1147–L1148 pins same-tier primary + second-reviewer dispatch coverage and the new `[second-reviewer-same-vendor]` halt — both in the same .bats file. Without an explicit edge, these can be queued for concurrent execution and produce conflicts on a shared test file.

3. **The round-05 halt-move deepens, not severs, the dependency.** Round-05 moved the `[second-reviewer-same-vendor]` halt from T16 to T19 with the rationale "T19 owns the host x vendor matrix lookup helpers". T19's new DoD bullet at **L1136** locates that halt inside "`_resolve-lib.sh`'s host × vendor matrix lookup" — i.e., the matrix-lookup helpers T19 adds to the file T16 creates. The halt now lives in T19's territory but on T16's structural foundation. Moving the halt without adding the dep edge is precisely the kind of cross-task-contract slip that the round-05 surgical edit was supposed to clean up.

4. **The implicit ordering via T20 is not load-bearing.** T20 deps on T19 but **not** on T16, so there is no transitive path forcing T16 → T19. T17 deps on T16 but T17 doesn't block anything T19 needs. The dep graph as currently written truly permits T19 to land before T16.

## Fix

Three coordinated edits:

- **L65** (task list): change `deps: none` → `deps: [Task 16]` for Task 19.
- **L1103** (T19 per-task spec): change `**Dependencies:** none. **Blocks:** Task 20.` → `**Dependencies:** Task 16. **Blocks:** Task 20.`
- **L974** (T16 per-task spec): change `**Blocks:** T17 (...)` → `**Blocks:** T17 (...); T19 (extends \`_resolve-lib.sh\` with the host × vendor matrix and default-second-reviewer lookup helpers and the matrix-lookup-time \`[second-reviewer-same-vendor]\` halt).`

Optional but consistent: add a one-sentence note to the Dependency Graph section (after L106, dep-graph item 4) calling out "T16 (G22 `_resolve-lib.sh` creation) → T19 (G27 host × vendor matrix extension + `[second-reviewer-same-vendor]` halt at matrix-lookup time)" so the file-edit ordering is documented at the same elevation as the T09/T11/T13 → T20 chain.

## Why medium, not high

T19's `Blocks: Task 20` (L1103) and T20's `deps: [..., Task 19]` (L66) mean that in the natural numeric implementation order T16 still lands before T20, and an implementer using numeric order will not hit the bug. But the deps field is the **authoritative ordering signal** for parallel/non-numeric implementer scheduling (see `tools/build-plugin.mjs`-style dep-graph consumers and the parallelize skill). A missing edge here is a load-bearing semantic gap, not a presentational nit.
