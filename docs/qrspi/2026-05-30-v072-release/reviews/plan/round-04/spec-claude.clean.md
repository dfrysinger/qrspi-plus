---
reviewer: spec-claude
round: 4
findings: 0
verdict: clean
---

# Spec Review Round 04 — Clean

No findings. Round-03 surgical edits integrated cleanly; the plan continues to cover every goal with verifiable per-task Test Expectations, and every Phase 1 AC bullet maps to deliverables of surviving tasks.

## Verification highlights (round-04 focus per dispatch)

### Goal coverage unchanged

All 35 approved goals (G1–G35) still trace to at least one task. The slice tallies — 1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2, 1.7=3 = 38 — match the Overview's stated "38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43)". Absorbed-goal attribution (G24-F01/F02/F03/F04, G25, G26 standalone, G29) verified once more — no task carries an inappropriate absorbed ID.

### Phase 1 AC bullets → surviving tasks (round-04 required check)

Each AC bullet's load-bearing deliverable references map to non-deleted tasks:

| AC bullet | Cited deliverable | Owning task (surviving) |
|---|---|---|
| 1 (end-to-end) | `verifier_enabled` aggregate | T01/T02/T05/T06/T07/T24 |
| 1 (end-to-end) | `scope_tagger_enabled` per-round artifacts | T13 |
| 1 (end-to-end) | `second_reviewer` reliable persistence | T19, T03 |
| 1 (end-to-end) | per-finding sidecars with valid `change_type` | T03, T04, T05 |
| 2 (fail-loud) | splitter on adversarial Codex stdout | T20 |
| 2 (fail-loud) | dispatch on misrouted `model_routing` | T16 |
| 2 (fail-loud) | missing `model_routing:` validation table | T17 |
| 2 (fail-loud) | `_resolve-lib.sh` halt on `tier: none` against unknown vendor | T16 (DoD L1001, Test exp L1014) |
| 2 (fail-loud) | reviewer-protocol fabricated procedural-authority guard | T35 |
| 2 (fail-loud) | path-filter exfil guard in `dispatch-agent.sh` | T21 |
| 3 (apply-fix) | Sub-Threshold Observations block in dispositions | T10 (G28) |
| 3 (apply-fix) | wholesale-hallucination rubric on calibration seeds | T08 (G19) + T09 (G20) |
| 4 (build) | `node tools/build-plugin.mjs` reproducible artifact | T39 |
| 5 (bats) | `tests/lint/test-bats-body-assertion-guard.bats` body-less catch | T40 (DoD L2319) |
| 5 (bats) | T40 seeded G21 + BW02 violation → non-zero with `file:line` | T40 (DoD L2319–2320) |
| 5 (bats) | T44 regex pins on `dispatch-routing`/`config-validation` continue to fire | T44 (DoD L2380) |
| 6 (issue closure) | goal-backing issue closure / explicit deferral | goal-level rollup, no task ref |
| 7 (release PR) | green CI + canary smoke | goal-level rollup, no task ref |

No AC bullet references the deleted T18 (G25 → CD-1 absorbed), T22 (G24-F02 → G25 → CD-1), T23 (G24-F03 moot — duplication target never existed), T41 (G26 runtime concern already fixed pre-v0.7.2), T42 (G24-F01 moot), or T43 (G24-F04 moot per design.md L2064). The round-03 rewrite cleanly excised every reference to those task IDs.

### Cross-slice dependency chain (round-03 addition) still coherent

Overview dep-graph item 4 — "G20 `actual_model:` provenance (T09) + G3 dispatch-manifest provenance (T11) + G9 per-task round-prepare edits (T13) → G3 splitter rename (T20)" — is consistent with T20's `Dependencies: [Task 09, Task 11, Task 12, Task 13, Task 19]` line (plan.md L72) and with T11's `Blocks: T20` (L683) and T13's `Blocks: T20` (L802). The pre-rename surface (`scripts/run-codex-review.sh`, `scripts/round-prepare.sh`) is fully provisioned by T09/T11/T13 before T20 hard-renames.

### Per-gap disposition narrative (round-03 rewrite) is internally consistent

The Overview's per-gap breakdown (L17) — gap 18 (G25→CD-1), gap 22 (G24-F02→G25→CD-1), gap 23 (G24-F03 moot — duplication target never existed), gap 41 (G26 runtime concern already fixed pre-v0.7.2; BW02 prevention rides on G21 in T40), gap 42 (G24-F01 moot), gap 43 (G24-F04 moot per design.md L2064) — matches the Out-of-scope language in T44 (L2370: "F01/F03 helpers and target files do not exist in current tree; F02 auto-resolves via CD-1; F04 absorbed into the G3/CD-1 dispatch rewrite") and the T17 Out-of-scope (L1068: G25 absorbed by CD-1).

### Sizing exceptions unchanged

All tasks >200 LOC carry the explicit closed-set exception: T12 (~280, reusable primitives), T16 (~320, schema-migration), T19 (~210, reusable primitives), T20 (~260, reusable primitives), T25 (~340, reusable primitives), T39 (~360, CI scaffolding). No new bundling violation introduced.

### Test Expectations specificity

Sampled rounds 1–3 covered T01–T20, T24–T32, T37–T40, T44. Round-04 spot-checked the same surfaces after diff = entire-file (plan.md first commit to git) — no vague language regressions, no `TBD`/`TODO`/`see Task N` cross-references.

## Verdict

Round-03 surgery integrated cleanly. Phase 1 AC bullets and per-task specs fully cover the 35 approved goals with surviving tasks only. No spec-level findings.
