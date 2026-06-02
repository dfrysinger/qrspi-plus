---
finding_id: R5-F01
reviewer_tag: quality-codex
round: 5
artifact: plan.md
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# G32 dependency contract is internally inconsistent (T39 missing T21/T20 dependency edge)

## What

The plan's Dependency Graph item 3 (plan.md L104) explicitly states `G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7)`, but Task 39 is declared in both the task list (L92) and the per-task spec (L2211) with `Dependencies: Task 25` only.

Additionally, line 110 contradicts line 104 explicitly: "Slice 1.7 is otherwise independent of Slices 1.1–1.6 (only T39 depends on T25 for the defensive-copy site)."

This means the executable task spec allows T39 to run before T20/T21, contradicting both the graph narrative AND the task's own scope (which audits/updates renamed script paths and shipped script surfaces under `build/`).

## Why it matters

Implement uses task dependency metadata (the `deps:` field), not prose, to schedule work. With the current spec, T39 can be dispatched before the dispatch-script rename (T20) and the path-filter hardening (T21) land, producing:
- Stale path assertions in T39's `build/` allow-list (T20 renames `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`)
- Symlink-escape regression-test divergence (T39's symlink-escape test at L2269 explicitly mirrors T21's `assert_path_under_repo_root` — both must use the same diagnostic phrase, so T21 must land first)
- Build-gate noise during the transition

The artifact also has an internal-consistency defect: prose at L104 and L110 contradict each other on T39's dependencies.

## Suggested fix

Two options:
(a) **Align deps with the graph (preferred):** Update T39's `deps:` in both the task list (L92) and the per-task spec (L2211) to `[Task 21, Task 25]` (T21 transitively pulls in T20 via T21's own deps). Then either delete the contradictory clause at L110 or rewrite it as "Slice 1.7 is otherwise independent of Slices 1.1–1.6 (T39 depends on T25 for the defensive-copy site and on T21 for the renamed/hardened dispatch-agent surface)."
(b) **Retract the graph edge (worse):** Delete dependency-graph item 3 (L104) — but this is incorrect given T39's scope explicitly audits the renamed script surface and mirrors T21's path-guard.

Option (a) is correct.
