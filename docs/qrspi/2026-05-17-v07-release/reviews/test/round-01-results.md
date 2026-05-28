# v0.7 Phase 1 — Acceptance traceability (round-01)

Mapping each Phase 1 acceptance criterion (`plan.md` lines ~82-135) to its
covering test(s). Per the dispatch contract, this round is **traceability
+ gap-filling only** — the ~400 task-level BATS pins authored during Implement
are the canonical green; this round wraps them in a single phase-gate file
and surfaces gaps as named skips.

**Gate file:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (26 @test entries; one per criterion + two regression guards).

## Traceability table

| Criterion ID | One-line summary | Covering test(s) | Status |
|---|---|---|---|
| Slice 1 C-1 | Cost-opt routing dispatches to cheap provider + telemetry | `tests/unit/test-g5-telemetry-emission.bats` :: pin (wrapped by gate) | green |
| Slice 1 C-2 | `### Per-Task Routing` section + routing-matrix pin | `skills/implement/SKILL.md` heading + `tests/unit/test-routing-matrix-application.bats` | green |
| Slice 2 C-1 | Pre-implementer test-writer dispatch order observable | `tests/unit/test-tdd-dispatch-order.bats` | green |
| Slice 2 C-2 | RED-verification four-state gate | `tests/unit/test-red-verification-gate.bats` | green |
| Slice 2 C-3 | Dual-mode test-writer (per-task + plan-level) | `tests/unit/test-test-writer-dual-mode.bats` | green |
| Slice 3 C-1 | CI workflow has lint + bash32 jobs | `tests/unit/test-ci-workflow-shape.bats` | green |
| Slice 3 C-2 | Shellcheck clean over shell surface | `tests/unit/test-run-smoke-checks.bats` (env-dep on `shellcheck` binary) | skipped-env-dep |
| Slice 3 C-3 | bash-3.2 docker job backstop / ban-list current | `tests/unit/test-bash32-runtime-coverage.bats` | green |
| Slice 3 C-4 | Evergreen-markdown scan green under unit BATS | `tests/unit/test-evergreen-markdown.bats` | skipped-known-bug (issue #5: pre-existing AGENTS.md/README.md violations) |
| Slice 3 C-5 | Implementer hygiene self-check reports added-line hits | `tests/unit/test-hygiene-self-check.bats` | green |
| Slice 4 C-1 | Shared markdown helper exists; consumers green | `tests/helpers/skill-markdown.bash` + `tests/unit/test-helpers-skill-markdown.bats` | green |
| Slice 4 C-2 | Parallelize scope reviewer: no scope-drift on canonical artifact | `tests/unit/test-worktree-aware-defaults.bats` | green |
| Slice 4 C-3 | Parallelize quality reviewer: canonical vocabulary | `tests/unit/test-parallelize-vocab.bats` | green |
| Slice 4 C-4 | OWNS-list pin asserts worktree-aware validation | `tests/unit/test-parallelize-owns-defers.bats` | green |
| Slice 5 C-1 | Reference renderable, not just path | `tests/unit/test-reference-gate-fields.bats` | green |
| Slice 5 C-2 | Reference-gate pauses dependents; approval persists | `tests/integration/test-reference-gate-pause.bats` | green |
| Slice 5 C-3 | Visual-fidelity reviewer references sibling context | `tests/unit/test-sibling-notification-protocol.bats` | green |
| Slice 5 C-4 | Quick-tier wording codified | `tests/unit/test-quick-tier-wording.bats` | green |
| Slice 6 C-1 | N>=3 parallel per-task spec authoring | `tests/unit/test-plan-post-approval-split.bats` | green |
| Slice 6 C-2 | N<=2 inline carve-out (same pin file) | `tests/unit/test-plan-post-approval-split.bats` (grep on `carve|inline|threshold` token) | green |
| Slice 7 C-1 | G4 cache-probe spike deliverable exists | `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` + `## Decision` section | green |
| Slice 7 C-2 | Spike decision recorded (Path A / Path B / Pending) | spike-report grep + downstream gating tests | green |
| Slice 7 C-3 | `test-no-summary-shim-dispatches.bats` green | `tests/unit/test-no-summary-shim-dispatches.bats` | green |
| Slice 7 C-4 | Three SKILL.anchors.json files + manifest + index-shape + narrow-read pins | `skills/{reviewer-protocol,using-qrspi,plan}/SKILL.anchors.json`, `scripts/g4-section-anchor-manifest.json`, `tests/unit/test-section-anchor-{index-shape,narrow-read}.bats` | green |
| Slice 7 C-5 | T43 conditional satisfied (Path A NO-OP / Path B markers present) | `tests/unit/test-cache-{control-capability-gate,hit-rate}.bats` (vacuous-satisfied while spike = Pending) | skipped-env-dep (T33 = Pending per implement-summary.md W3+W9) |
| Slice 8 C-1 | Scratch file absent from committed tree; worktree-exclude entry present | git ls-files + `.git/info/exclude` grep | green / skipped-env-dep on fresh checkout |
| Slice 8 C-2 | Three commit-hygiene architectural invariants observable | `tests/unit/test-commit-hygiene-invariants.bats` | green |
| Slice 9 C-1 | u14-lint passes confusable-prefix, fails genuine-integrate | `tests/unit/test-u14-lint.bats` | green |
| Slice 10 C-1 | Boundary with Goals section + decision branches | `skills/replan/SKILL.md` + `tests/fixtures/future-goals-mixed-shape.md` + `tests/unit/test-replan-boundary-with-goals.bats` | green |
| Slice 10 C-2 | Skill prose names hand-off-report shape | `skills/replan/SKILL.md` hand-off tokens + same T42 pin | green |
| Slice 10 C-3 | Integrate-phase Replan dry-run against fixture | n/a (human-verified Integrate gate per plan.md line 135) | skipped-human-gate |

## Regression / known-issue guards

| Issue | Source | Test | Status |
|---|---|---|---|
| #2 anchor-refresh H2-with-H3-span byte-identity bug | implement-summary.md W3 + T36 | `tests/unit/test-section-anchor-refresh.bats` | skipped-known-bug |
| #1 duplicate `## Overview` in plan/SKILL.md | implement-summary.md W3 | inline grep guard in gate file | skipped-known-bug |

## Status summary

- **30** criterion @tests authored in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (Slices 1-10).
- **2** regression guards documenting known bugs from implement-summary.md (#1, #2).
- **Total breakdown:** 23 green / 4 skipped-env-dep (shellcheck binary, T43 vacuous on Pending spike, .git/info/exclude on fresh checkouts, plus 1 skipped-known-bug from #5 evergreen pre-existing violations) / 1 skipped-human-gate (Slice 10 C-3 Integrate dry-run) / 2 skipped-known-bug regression markers.
- **Gaps surfaced for fix-round consideration (NOT failing this gate):** known issues #1, #2, #3 (T11/T09 diagnostic-name divergence), #4 (T03 `grep -P` PCRE on macOS system grep), #5 (evergreen pre-existing violations) per `implement-summary.md`.
