---
reviewer: quality-claude
artifact: structure
change_type: correctness
severity: blocking
---

# G6 runtime sidecar at `<artifact-dir>/review-state/` will trigger false-positive G5 orchestration-boundary violations

## Where

- `structure.md` § File Map → G5 row for `scripts/orchestration-boundary-check.sh`
  > "Run `git status --porcelain` against the workspace (excluding the `reviews/` path tree)."
- `structure.md` § File Map → G6 row for `scripts/validate-stage-commit-parents.sh`
  > Sidecar path "`<artifact-dir>/review-state/waves/wave-W<N>-expected-parents.txt`"
- `structure.md` § Interfaces → `scripts/validate-stage-commit-parents.sh`
  > "Runtime sidecars are NOT committed (.gitignore-equivalent semantics — the file is recoverable by re-running --capture against the live git state)."

## What is wrong

G6 deliberately writes its per-wave sidecar to `<artifact-dir>/review-state/waves/wave-W<N>-expected-parents.txt`, justified as "out-of-band of both `reviews/` (which is the per-round review-output tree) and `parallelization.md`." The file is intentionally never committed.

G5's `scripts/orchestration-boundary-check.sh` runs `git status --porcelain` against the workspace and excludes **only the `reviews/` path tree** when filtering uncommitted edits. `review-state/` is a sibling directory of `reviews/`, not a child, so it is **not excluded** by G5's filter.

`<artifact-dir>` resolves under `docs/qrspi/<release-name>/`, which is itself tracked by git. Files written under that subtree are tracked-but-uncommitted by default. The Interfaces block hand-waves this with ".gitignore-equivalent semantics" — but no `.gitignore` (or other ignore) modification appears anywhere in the File Map, so the asserted semantics are not actually achieved by any structural change in this release.

End-state after a normal Implement phase: every wave-dispatch step (G6) writes a sidecar under `<artifact-dir>/review-state/waves/`. None are committed (correct, per G6 design). Then the phase-end Step N (G5) calls `orchestration-boundary-check.sh`. `git status --porcelain` reports every sidecar as an uncommitted workspace edit. None of them are under `reviews/`, so the exclusion does not catch them. The orchestration-boundary report becomes non-empty by construction every wave-bearing Implement phase, surfacing N false-positive violations in the batch-gate menu (interactive) or — worse — triggering autopilot's "uncommitted workspace changes → halt with HALT-orchestration-boundary.md" branch every run.

This is a hard coherence break between G5 and G6 that the File Map currently leaves unresolved.

## Why it matters

- **False-positive cascade.** Every Implement phase produces ≥1 wave → ≥1 sidecar → guaranteed non-empty G5 report. The signal G5 exists to surface (real orchestration drift) gets buried in noise the orchestrator can never distinguish from real violations without reading the report.
- **Autopilot halt by construction.** The autopilot branch on "uncommitted workspace changes" writes `HALT-orchestration-boundary.md` and exits the loop. An end-to-end autopilot self-host run of v0.7.3 against itself would halt at the first Implement-phase batch gate — defeating Phasing's replan-gate criterion that the run "converges without orchestration-boundary breaches."
- **Acceptance contradiction.** Structure's G6 acceptance asserts "`parallelization.md` is unchanged after the wave (symbolic-only invariant per research Q11/Q12)" and structure's G5 acceptance expects an empty `reviews/integration/orchestration-boundary.md` in the v0.7.3 self-host. Both cannot hold simultaneously under the current File Map.

## What to fix

Pick one resolution and reflect it in the File Map (and the Interfaces block for `orchestration-boundary-check.sh` and/or `validate-stage-commit-parents.sh`):

1. **Broaden G5's exclusion pattern.** Update G5's File Map row + the `orchestration-boundary-check.sh` interface (when adding it in subsequent rounds) to exclude both `reviews/` and `review-state/` from `git status --porcelain` post-processing. Minimal change; preserves G6's chosen sidecar location.
2. **Add a `.gitignore` entry as an explicit File Map row.** New row (action: Modify) for the repository-root `.gitignore` (or a per-artifact-dir `.gitignore` under `docs/qrspi/2026-06-04-v073-release/`) that ignores `review-state/`. Makes the ".gitignore-equivalent semantics" claim real instead of asserted.
3. **Relocate the sidecar under `reviews/`.** E.g., `<artifact-dir>/reviews/implement/wave-state/wave-W<N>-expected-parents.txt`. Keeps the sidecar inside the path tree G5 already excludes. Costs the "out-of-band of `reviews/`" rationale G6 gave for the current path; if that rationale is load-bearing (it reads as preference, not constraint), say so explicitly.

Option 1 or 2 is lowest-blast-radius; Option 3 collapses the two surfaces but rewrites G6's path choice. Pick deliberately; either way the File Map needs to carry the chosen change so a reader can predict what the implementer ships.
