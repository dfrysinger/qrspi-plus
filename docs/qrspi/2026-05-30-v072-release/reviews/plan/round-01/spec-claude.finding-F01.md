---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: spec-claude
---

# Dependency graph misses ordering edges around T20 (G3 script-rename collapse)

## What's wrong

T20 renames three live scripts:

- `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`
- `scripts/run-third-party-llm.sh` → `scripts/dispatch-companion.sh`
- `scripts/codex-finding-splitter.sh` → `scripts/third-party-finding-splitter.sh`

with **no compatibility shim** ("no compatibility shim or live caller left on the old names" — T20 In-scope item 1).

The plan's dep graph encodes the rename's downstream consumers correctly (T20 blocks T21 / T39 via the explicit `G3 → G16 → G32` cluster in the "Dependency Graph" section). But three other tasks touch the same rename surface and carry **no edge to T20** in either direction:

1. **T09 (G20)** — `Target files: ..., scripts/run-codex-review.sh (modify), ...` (line 573). `Dependencies: Task 08` only. The task adds dispatch-manifest host/vendor/model persistence to the pre-rename script. T20 is not a dep, and T09 does not appear in T20's `Blocks:` list.

2. **T11 (G29)** — `Target files: skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), ...` (line 692). `Dependencies: none`. The task adds first-party / third-party manifest-provenance fields to the pre-rename script. T20 is not a dep, and T11 does not appear in T20's `Blocks:` list. T11's own References entry even cites "`structure.md ### scripts/run-codex-review.sh` — Slice 1.2 manifest-provenance persistence … and cross-slice rename note" — acknowledging the rename without ordering against it.

3. **T13 (G9)** — `skills/implement/SKILL.md (modify)` In-scope item: "Insert the G9 between-round checklist … `dispatch-agent.sh --implementer-commit` invocation, and exit-code branches…" (line 829). The SKILL prose names the **post-rename** script. `Dependencies: Task 12` only; T20 is not listed.

Whichever ordering the implementer runtime picks, at least one of these three tasks lands against a target-file path that does not exist or no longer exists:

- If T20 lands before T09 / T11, both list `scripts/run-codex-review.sh` as a target that has just been renamed away. The implementer agent then either fails the target-file existence check or silently re-targets to `scripts/dispatch-agent.sh` (no explicit guidance in the spec).
- If T09 / T11 land before T20, T20's "rename collapse" subsumes their diff and must re-apply it atomically to the renamed file, with no provenance edge documenting the absorption.
- If T13 lands before T20, the SKILL.md prose references a script name (`dispatch-agent.sh`) that does not yet exist on disk; the per-task gate would emit a SKILL whose load-bearing dispatch instruction names a non-existent path.

This is structurally the same defect class the release is trying to close in G18 (Plan-phase under-scopes cross-task consumer surface) — "the original spec scopes each task's own changes but does not systematically enumerate the downstream consumers of the contracts being changed" (goals.md G18). The rename in T20 is a contract change with three undeclared consumers in the same plan.

## Why it matters

Without explicit dep edges around T20:

- The implementer dep-graph executor has no ordering constraint and can interleave T09 / T11 / T20 in any order; whichever runs first wins, the others race.
- The Phase 1 acceptance criterion "End-to-end pipeline run … cleanly with `verifier_enabled: true` … codex_reviews: true … no orchestrator chat-parsing fallback fires" requires all three of T09 (actual_model audit), T11 (manifest provenance), and T20 (rename + universal dispatcher) to coexist in the final dispatch script. A merge order with implicit interleaving risks losing one of the three on conflict resolution.
- T13's SKILL.md prose referencing `dispatch-agent.sh` before T20 lands turns the per-task gate into a documentation-vs-code drift — the same failure class G17 (stale prose in implementer-protocol after T2 added committed gitignore) is fixing as a side effect of v0.7.1.

The dep graph is the plan's primary correctness artifact for sequencing — operating it with three known-missing edges defeats the purpose.

## Suggested fix

Add the missing edges in the existing dep-graph format. Two equivalent options:

**Option A — sequence T20 last among the run-codex-review consumers.** Update T20's `Dependencies:` line:

```
Dependencies: Task 09, Task 11, Task 12, Task 13, Task 19.
```

…with a short note in T20's Overview ("This rename collapses the script after T09 / T11 land their manifest-provenance fields and T13 wires the SKILL.md callsite, so the rename absorbs all three diffs atomically").

Update T09 and T11 to declare `Blocks: T20`. Update T13's `Blocks:` list to include T20.

**Option B — sequence T20 first and re-target T09 / T11 / T13.** Update T09 / T11 / T13 to declare `Dependencies: …, Task 20`, and rewrite their `Target files:` and prose to use the post-rename script names (`scripts/dispatch-agent.sh`). T20's task body already produces the renamed script; T09 / T11 / T13 then layer their changes onto it.

Either option also requires updating the "Dependency Graph" prose section near the top of plan.md (currently enumerates 3 cross-slice clusters; this rename-consumer cluster is implicit there and should be named explicitly so reviewers can audit it without re-deriving the surface). The current dep-graph text describes the renamed-file cluster as `G3 → G16 → G32` only; the actual cluster is wider.

Either resolution also fixes the implicit assumption that "global task numbering ≈ implementation order." The plan's Overview explicitly says "Cross-slice dependency (Slice 1.4 G4 → Slice 1.3 G9) forces Task 12 (G4 cumulative diff helper) to land before the Slice 1.3 block" — proving the project does encode numbering-vs-deps mismatches when they matter. The T20 rename cluster deserves the same explicit treatment.
