# v0.7.3 Phase 1 — Plan-level Test Coverage Report

Author: qrspi-test-writer (Test-phase mode)
Date: 2026-06-14
Repo branch: `qrspi/v0.7.3/stage-W7`
Output dir: `tests/acceptance/v07-phase1-test-phase/`

## Scope

This report enumerates the v0.7.3 Phase 1 acceptance criteria (from
`docs/qrspi/2026-06-04-v073-release/plan.md` § Phase 1 Acceptance Criteria
and `design.md` per-goal/per-CD **Acceptance.** subsections) and maps each
to the plan-level test it is covered by under
`tests/acceptance/v07-phase1-test-phase/`. Per-task `## Test Expectations`
bullets that map to specific component contracts continue to be covered by
the ~127 unit / lint tests under `tests/unit/` and `tests/lint/`; the
plan-level tests here verify end-to-end observable behaviour at the phase
boundary.

The Iron Law applies: the orchestrator runs these tests; this report does
NOT record execution results.

## Test files written

| File | @test count |
|------|-------------|
| `tests/acceptance/v07-phase1-test-phase/test-cd1-upstream-paths.bats` | 6 |
| `tests/acceptance/v07-phase1-test-phase/test-cd2-dispatch-agent-highlevel.bats` | 5 |
| `tests/acceptance/v07-phase1-test-phase/test-cd3-r8-rule.bats` | 7 |
| `tests/acceptance/v07-phase1-test-phase/test-g1-verifier-grounded.bats` | 5 |
| `tests/acceptance/v07-phase1-test-phase/test-g2-bats-id-hygiene.bats` | 5 |
| `tests/acceptance/v07-phase1-test-phase/test-g3-absorption-pipeline.bats` | 7 |
| `tests/acceptance/v07-phase1-test-phase/test-g4-plan-step-upstream.bats` | 4 |
| `tests/acceptance/v07-phase1-test-phase/test-g5-orchestration-boundary.bats` | 12 |
| `tests/acceptance/v07-phase1-test-phase/test-g6-stage-commit-parents.bats` | 4 |
| `tests/acceptance/v07-phase1-test-phase/test-g7-anchor-file-lookup.bats` | 5 |
| `tests/acceptance/v07-phase1-test-phase/test-g8-version-source.bats` | 9 |
| `tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats` | 7 |
| `tests/acceptance/v07-phase1-test-phase/test-integration-dispatch-chain.bats` | 4 |
| `tests/acceptance/v07-phase1-test-phase/test-regressions-integration-round01.bats` | 9 |
| **Total** | **89** |

## Coverage Analysis

### Cross-Goal Decisions

| Criterion (source) | Acceptance criterion | Test type | Test file:line(s) | Status |
|--------------------|----------------------|-----------|-------------------|--------|
| design.md § CD-1 Acceptance #1 | `upstream-paths.sh` prints documented set for every supported step | Acceptance | `test-cd1-upstream-paths.bats:33-46` | Covered |
| design.md § CD-1 Acceptance #2 | Unknown `--step` returns always-appended SKILL paths + exit 0 (fail-soft) | Acceptance | `test-cd1-upstream-paths.bats:55-65` | Covered |
| plan.md PA #2 (always-append) | Always-appended array contains `skills/implementer-protocol/SKILL.md` | Acceptance | `test-cd1-upstream-paths.bats:48-53`; `test-g1-verifier-grounded.bats:47-59` | Covered |
| plan.md PA #2 (Plan-step diagnostics) | Plan-step missing/malformed `config.md` halts named diagnostic | Boundary | `test-cd1-upstream-paths.bats:67-79`; `test-g4-plan-step-upstream.bats:64-71` | Covered |
| design.md § CD-2 Acceptance #1 | `review-prep.sh` produces documented input set per step; absorption-map at plan path | Acceptance / Integration | `test-cd2-dispatch-agent-highlevel.bats:26-31`; `test-integration-dispatch-chain.bats:79-103` | Covered |
| design.md § CD-2 Acceptance #2 | `dispatch-agent.sh` high-level mode = low-level with pre-computed paths | Acceptance | `test-cd2-dispatch-agent-highlevel.bats:33-44` | Wiring covered (per-prompt side-by-side equality is covered by `tests/unit/test-dispatch-agent-highlevel-mode.bats`) |
| design.md § CD-2 Acceptance #3 | Zero `git diff > round-NN.diff` blocks remain in 8 artifact-step SKILLs | Acceptance | `test-cd2-dispatch-agent-highlevel.bats:46-63` | Covered |
| design.md § CD-2 Acceptance #4 / plan.md PA #4 | Pre-dispatch redirect-prose shrinkage ≥ 80 lines vs v0.7.2 | Acceptance (proxy) | `test-cd2-dispatch-agent-highlevel.bats:46-63` | Covered indirectly (zero-redirect assertion is the upper bound) |
| design.md § CD-3 Acceptance / plan.md PA #5 | R8 heading + table header + What-NOT-to-tighten + reviewer-test sentence | Acceptance | `test-cd3-r8-rule.bats:18-37` | Covered |
| design.md § CD-3 Acceptance #2 / plan.md PA #5 | `rule-violation` finding-type gate cites `R1-R8` | Acceptance | `test-cd3-r8-rule.bats:39-42` | Covered |
| design.md § CD-3 Acceptance #4 | No duplicated R-headings; all cited R-IDs R1..R8 exist | Acceptance | `test-cd3-r8-rule.bats:44-52` | Covered |

### Goals

| Criterion (source) | Acceptance criterion | Test type | Test file:line(s) | Status |
|--------------------|----------------------|-----------|-------------------|--------|
| **G1** design.md #1 / plan.md PA #6 | `qrspi-finding-verifier.md` carries new rubric clause verbatim | Acceptance | `test-g1-verifier-grounded.bats:25-31` | Covered |
| **G1** design.md #2 | upstream-paths always-appended array contains implementer-protocol | Acceptance / Integration | `test-g1-verifier-grounded.bats:47-59`; `test-cd1-upstream-paths.bats:48-53` | Covered |
| **G1** design.md #3 / plan.md PA #6 | Synthetic verifier dispatch on `[Tnn]` finding scores ≥ 70 | Acceptance (delegated) | `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` | Pre-existing; this file asserts the wiring preconditions |
| **G1** design.md #4 | Same fixture under v0.7.2 verifier scores < 70 (regression-direction) | Acceptance (delegated) | `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` | Pre-existing |
| **G2** plan.md PA #7 (gate 1) | `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` returns zero matches | Acceptance | `test-g2-bats-id-hygiene.bats:18-26` | Covered (verbatim grep) |
| **G2** plan.md PA #7 (gate 2) | `grep -rE '@test "[^"]*R[0-9]+-F[0-9]+' tests/**/*.bats` returns zero matches | Acceptance | `test-g2-bats-id-hygiene.bats:28-36` | Covered (verbatim grep) |
| **G2** design.md #2 / plan.md PA #7 | Permanent CI lint rejects regression PR re-introducing `[T99]` / `R99-F99` | Boundary | `test-g2-bats-id-hygiene.bats:38-49` | Covered |
| **G2** design.md #2 | implementer-protocol Pre-DONE Halt-DONE blocking anchor for `@test "..."` hits | Acceptance | `test-g2-bats-id-hygiene.bats:51-55` | Covered |
| **G3** design.md #1 | `design-absorption-markers.sh` against fixture returns expected map | Acceptance / Integration | `test-g3-absorption-pipeline.bats:33-35,66-79` | Covered |
| **G3** design.md #2 | G3.d marker-set lint passes on real design.md, fails on non-enumerated marker | Acceptance (delegated) | `tests/lint/test-design-absorption-marker-set.bats` | Pre-existing |
| **G3** design.md #3 | plan SKILL § pre-fanout anchor sentence verbatim | Acceptance | `test-g3-absorption-pipeline.bats:37-42` | Covered |
| **G3** design.md #4 | plan-spec reviewer rubric clause verbatim; synthetic absorbed-ID task → `change_type: scope` finding | Acceptance | `test-g3-absorption-pipeline.bats:44-49`; `tests/unit/test-plan-spec-reviewer-absorption.bats` | Covered + delegated |
| **G3** design.md #5 | design reviewer fidelity-check clause verbatim | Acceptance | `test-g3-absorption-pipeline.bats:55-58`; `tests/unit/test-design-reviewer-fidelity.bats` | Covered + delegated |
| **G3** design.md (fail-loud) / plan.md PA #8 | Plan-step + Design-step dispatch-defect halt on absent absorption_map_path | Acceptance / Boundary | `test-g3-absorption-pipeline.bats:51-53,60-63`; `tests/unit/test-design-reviewer-dispatch-defect.bats` | Covered |
| **G3** plan.md PA #8 (meta) | v0.7.3 self-host Plan round-01 zero plan-spec-reviewer absorption findings | Meta-acceptance | Observed in `docs/qrspi/2026-06-04-v073-release/reviews/plan/round-01-results.md` (orchestrator-attested; cannot be self-tested by bats) | Out-of-band attestation |
| **G4** design.md #1 / plan.md PA #9 | Plan step `pipeline: full` → goals.md, research/summary.md, design.md, phasing.md, structure.md + SKILL trio | Acceptance | `test-g4-plan-step-upstream.bats:20-33` | Covered |
| **G4** design.md #2 | Plan step `pipeline: quick` → goals.md, research/summary.md + SKILL trio | Acceptance | `test-g4-plan-step-upstream.bats:35-50` | Covered |
| **G4** design.md #3 | Plan step missing/malformed config halts named diagnostic | Boundary | `test-g4-plan-step-upstream.bats:52-58,64-71`; `test-cd1-upstream-paths.bats:67-79` | Covered |
| **G4** design.md #4 / plan.md PA #9 | Plan-step verifier dispatch carries deterministic `upstream_paths` | Acceptance (determinism) | `test-g4-plan-step-upstream.bats:60-71` | Covered (determinism direction); equivalence to fixture-expected set covered above |
| **G5** design.md #1 / plan.md PA #10 | integrate SKILL contains HARD-RULE verbatim | Acceptance | `test-g5-orchestration-boundary.bats:46-50` | Covered |
| **G5** design.md #2 | test SKILL contains HARD-RULE verbatim | Acceptance | `test-g5-orchestration-boundary.bats:52-55` | Covered |
| **G5** design.md #3 | using-qrspi SKILL contains cross-cutting note | Acceptance | — | **GAP** — see Gaps below |
| **G5** design.md #4 / plan.md PA #10 | OBC clean → byte-empty report + exit 0 | E2E | `test-g5-orchestration-boundary.bats:80-89` | Covered |
| **G5** design.md #4 (variants) | Section-header-emitted-only-when-populated invariant on clean run | E2E | `test-g5-orchestration-boundary.bats:111-119` | Covered |
| **G5** design.md #4 (commit-violation) | Non-subagent commit → entry under `## Boundary violations`, exit 0 (fail-soft) | E2E | `test-g5-orchestration-boundary.bats:121-133` | Covered |
| **G5** design.md #4 (dispatch defect) / plan.md PA #10 | phase-base missing / malformed surfaces under `## Dispatch defects` + non-zero exit | E2E / Boundary | `test-g5-orchestration-boundary.bats:91-109`; `test-integration-dispatch-chain.bats:131-138` | Covered |
| **G5** design.md #5 / plan.md PA #10 | dispatch-agent wraps subagent git commands with `GIT_AUTHOR_NAME=qrspi-<agent>` | Acceptance | `test-g5-orchestration-boundary.bats:74-77` | Covered |
| **G5** design.md #5 (round-trip) | qrspi-marker commit excluded from non-subagent filter | E2E | `test-g5-orchestration-boundary.bats:135-148` | Covered |
| **G5** design.md #6 | Step N OBC block ordered before batch gate in implement/integrate/test | Acceptance | `test-g5-orchestration-boundary.bats:46-65` | Covered |
| **G5** plan.md PA #11 | Implement-phase autopilot terminates wave loop + writes `HALT-orchestration-boundary-undeterminable.md` on dispatch defect | Acceptance (delegated to SKILL prose) | `tests/lint/test-obc-script-absent-anchor.bats`; behaviour covered indirectly by `test-g5-orchestration-boundary.bats:91-109` non-zero-exit assertion | Partial — see Gaps |
| **G5** integrate phase-base.txt write | First-orchestrator-action phase-base.txt bare-SHA write | Acceptance | `test-g5-orchestration-boundary.bats:67-77`; `tests/lint/test-integrate-test-skill-phase-base-write.bats` | Covered |
| **G6** design.md #1 (positive) / plan.md PA #12 | Stage commit with correct parents passes silently | E2E | `test-g6-stage-commit-parents.bats:55-69` | Covered |
| **G6** design.md #1 (extra parent) | Extra parent halts named `stage-commit-parent-mismatch:` | Boundary | `test-g6-stage-commit-parents.bats:71-86` | Covered |
| **G6** design.md #1 (missing tip / wrong first-parent / single-task) | Additional fixture directions | Boundary (delegated) | `tests/unit/test-validate-stage-commit-parents.bats` | Pre-existing |
| **G6** design.md #2 / plan.md PA #12 | v0.7.3 self-host Implement waves all pass validation silently | Meta-acceptance | orchestrator-attested via wave-state sidecars | Out-of-band attestation |
| **G6** design.md #3 / plan.md PA #12 | Capture step writes integration-base + task-tip SHAs to runtime sidecar; `parallelization.md` unchanged | E2E | `test-g6-stage-commit-parents.bats:55-69` (sidecar write); `parallelization.md` immutability is repo invariant | Covered |
| **G6** implement SKILL wraps Wave Dispatch with capture + validate | Acceptance | `test-g6-stage-commit-parents.bats:49-53` | Covered |
| **G7** design.md #1 / plan.md PA #13 | using-qrspi step 12 carries `git diff "$(cat reviews/` substring | Acceptance | `test-g7-anchor-file-lookup.bats:23-28` | Covered |
| **G7** design.md #1 (negative) | No `git diff HEAD~1 --` survives in step-12 prose | Acceptance | `test-g7-anchor-file-lookup.bats:30-35` | Covered |
| **G7** design.md #2 | Sweep: no other skill inlines deprecated HEAD~1 narrow incantation | Acceptance | `test-g7-anchor-file-lookup.bats:50-60` | Covered |
| **G7** design.md #3 (bats fixtures) | anchor-file-missing / sha-format-invalid / narrow-round-empty-diff diagnostics | Acceptance (delegated) | `test-g7-anchor-file-lookup.bats:37-47`; `tests/unit/test-narrow-round-anchor-lookup.bats` | Covered + delegated |
| **G8** design.md #1 / plan.md PA #15 | VERSION at repo root, exactly one version string | Acceptance | `test-g8-version-source.bats:21-31` | Covered |
| **G8** design.md #2 / plan.md PA #15 | `node tools/build-plugin.mjs` writes version into all five consumer files | Acceptance | `test-g8-version-source.bats:43-58` | Covered (lockstep + per-file stamp present) |
| **G8** design.md #3 | CI step `node tools/build-plugin.mjs && git diff --exit-code` fails on hand-edit drift | Acceptance | `test-g8-version-source.bats:74-79` | Covered (workflow file present + commands wired) |
| **G8** design.md #4 | Build script halts named diagnostic on missing/malformed VERSION | Acceptance | `test-g8-version-source.bats:69-72`; `tests/unit/test-version-stamping.bats` | Covered + delegated |
| **G8** design.md #5 | Release runbook documents new flow (VERSION as sole authoring path) | Acceptance | `test-g8-version-source.bats:81-86` | Covered |
| **G8** design.md #6 / plan.md PA #15 | v0.7.3 shipped via the new flow (VERSION = 0.7.3, single build run) | Acceptance | `test-g8-version-source.bats:33-37` | Covered (VERSION asserted = 0.7.3) |
| **G8** plan.md PA #14 | Plugin installs cleanly from published manifests on fresh Copilot CLI session | Smoke (out-of-band) | — | **GAP** — requires live CLI install attempt; not bats-automatable |
| **G8** plan.md PA #15 (lockstep) | `.github/plugin/*` in lockstep with `.claude-plugin/*` | Acceptance | `test-g8-version-source.bats:60-67` | Covered |
| **G9** design.md (structural trim) | using-qrspi < 350, implement < 500, plan < 400, artifact-step < 300 each | Acceptance (guidepost) | line counts not asserted (guideposts per design.md) | Intentionally not gated — design.md says targets are guideposts; the **footprint** below is the real gate |
| **G9** design.md (three-tier placement) / bullet 8 | Grep audit: zero matches for jobId / tmpfile / HEAD~1 narrative / etc. | Acceptance | `test-g9-footprint.bats:69-79`; `tests/lint/test-skill-trim-audit.bats` | Covered + delegated |
| **G9** design.md (`_shared/` populated) | Six new snippets exist and are `!cat`-referenced | Acceptance | `test-g9-footprint.bats:51-60` | Covered (existence); `!cat` reference graph covered by `tests/unit/test-measure-active-footprint.bats` |
| **G9** design.md (R8 tightening) | G9 task spec cites R8 as authority | Acceptance (delegated to plan reviewer) | n/a (meta-acceptance; not test-automatable) | Out-of-band attestation |
| **G9** design.md (regression guard) / plan.md PA #16 | v0.7.2 phase-1 acceptance suite passes against trimmed skill set | Regression | orchestrator runs `tests/acceptance/v07-phase1/` at Test gate; `test-g9-footprint.bats:62-67` asserts the suite still exists | Orchestrator-executed |
| **G9** design.md (footprint) / plan.md PA #17 | `measure-active-footprint.sh` reports < 30K tokens; captured at g9-footprint-report.md | Acceptance | `test-g9-footprint.bats:36-49` | Covered (report exists + total_tokens < 30000) |

## Gaps

| Gap | Reason | Recommendation |
|-----|--------|----------------|
| G5 design.md Acceptance #3 (`using-qrspi/SKILL.md` cross-cutting note anchor-phrase grep) | The "### Orchestration Boundary applies to every phase" cross-cutting note was relocated to `skills/using-qrspi/references/state-and-pipeline-ordering.md` during G9 trim; no anchor-phrase residue is detectable in `using-qrspi/SKILL.md` itself. design.md explicitly contracts the anchor lives in `using-qrspi/SKILL.md`. | Orchestrator should dispatch a fix-task to either (a) restore a one-line pointer in `skills/using-qrspi/SKILL.md` citing `references/state-and-pipeline-ordering.md`, or (b) update design.md Acceptance #3 to name the reference path as the legitimate post-trim home. Pending resolution, no bats test is authored — writing it would lock in a contract that has already drifted. |
| G5 plan.md PA #11 (autopilot writes `HALT-orchestration-boundary-undeterminable.md` on dispatch-defect) | The autopilot loop is a SKILL-prose contract (`skills/implement/SKILL.md` § Batch Gate autopilot branched default) rather than an executable script; the named-file write is performed by main-chat-mode prose, not by any standalone binary. Bats can lint the prose anchor (already done by `tests/lint/test-obc-script-absent-anchor.bats`), but cannot exercise the autopilot loop end-to-end. | Coverage is via SKILL-prose anchor lint + the OBC non-zero exit assertion (`test-g5-orchestration-boundary.bats:91-109`) that drives the autopilot branch. Orchestrator may add a synthetic autopilot-mode harness in a future round if desired. |
| G8 plan.md PA #14 (plugin installs cleanly on fresh Copilot CLI session) | Requires invoking the Copilot CLI against the published marketplace; out of bats scope and requires an isolated host. | Manual smoke step in `docs/release-runbook.md` (already referenced by `test-g8-version-source.bats:81-86`); record verification in the release commit message. |
| G3 plan.md PA #8 (meta: zero plan-spec-reviewer absorption findings) | Meta-acceptance: only verifiable by inspecting the live `reviews/plan/round-01-results.md` output produced by the v0.7.3 self-host; cannot be self-tested. | Orchestrator-attested at the Plan-step review gate. |
| G6 plan.md PA #12 (meta: every wave's stage commit passes validation silently) | Meta-acceptance: only verifiable post-hoc by replaying `git log --format='%P'` against the integration branch's stage commits. | Orchestrator-attested at the Integrate phase gate. |
| G9 R8 tightening applied (G9 task spec cites R8) | Meta-acceptance against plan authoring artifact, not a runtime contract. | Orchestrator-attested at the Plan-step review gate. |
| G9 structural line-count guideposts | design.md explicitly contracts these as guideposts, not hard caps; the footprint measurement is the real gate. | None — intentionally not gated. |

## Regression coverage

Each in-pipeline fix from `docs/qrspi/2026-06-04-v073-release/fixes/integration-round-01/`
has dedicated regression tests so the original failure mode is mechanically
blocked from re-emergence.

| Fix | Behaviour locked | Regression test file:lines |
|-----|------------------|----------------------------|
| `fix-F01-phase-base-format.md` | integrate SKILL `printf '%s\n'` (NOT `printf 'integration_base_sha=%s\n'`) for `reviews/integration/phase-base.txt` | `test-regressions-integration-round01.bats:60-66` |
| `fix-F01-phase-base-format.md` | test SKILL `printf '%s\n'` (NOT key=value form) for `reviews/test/phase-base.txt` | `test-regressions-integration-round01.bats:68-72` |
| `fix-F01-phase-base-format.md` | OBC accepts bare-SHA phase-base.txt and produces clean report | `test-regressions-integration-round01.bats:74-80`; `test-integration-dispatch-chain.bats:121-129` |
| `fix-F01-phase-base-format.md` | OBC REJECTS pre-fix key=value phase-base.txt as dispatch defect | `test-integration-dispatch-chain.bats:131-138` |
| `fix-F02-wave-sidecar-bridge.md` | `--capture --wave-id W1` dual-writes `wave-1.txt` (YAML colon) alongside `W1.sidecar` | `test-regressions-integration-round01.bats:86-99` |
| `fix-F02-wave-sidecar-bridge.md` | `--seed-wave-1-obc` writes `wave-1.txt` only (no `W1.sidecar`) — fan-out-only Wave 1 bridge | `test-regressions-integration-round01.bats:101-107` |
| `fix-F02-wave-sidecar-bridge.md` | End-to-end: `--capture W1` followed by OBC `--phase implement` produces empty `## Dispatch defects` | `test-regressions-integration-round01.bats:109-122` |
| `fix-CI-baseline-pins.md` (#A) | `agents/qrspi-*.md` count ≥ 42 and `qrspi-plan-apply-fix.md` exists | `test-regressions-integration-round01.bats:135-141` |
| `fix-CI-baseline-pins.md` (#B) | `.github/workflows/` carries both `ci.yml` AND `build-then-diff.yml` | `test-regressions-integration-round01.bats:143-148` |
| `fix-CI-baseline-pins.md` (#C) | `VERSION = 0.7.3` and `.claude-plugin/marketplace.json` carries `"0.7.3"` | `test-regressions-integration-round01.bats:128-133`; `test-g8-version-source.bats:33-37` |

## Notes on test design

- Every test maps to a specific acceptance criterion or regression bug; no
  vacuous assertions; no implementation-detail coupling.
- All scripts are exercised against the real committed tree
  (`scripts/upstream-paths.sh`, `scripts/orchestration-boundary-check.sh`,
  `scripts/validate-stage-commit-parents.sh`, `scripts/review-prep.sh`,
  `scripts/design-absorption-markers.sh`, `tools/build-plugin.mjs`).
- E2E tests build self-contained throwaway git repos under
  `$REPO_ROOT/.bats-tmp-*.XXXXXX/` (not `/tmp`, matching the existing
  `tests/unit/test-orchestration-boundary-check.bats` pattern); each test
  teardown removes its fixture.
- The G5 e2e test exercises the subagent-author-marker filter by
  performing real `git commit`s under both human and `qrspi-test-writer`
  author names, proving the round-trip via the live OBC script.
- SKILL-prose assertions use anchor-phrase grep against load-bearing
  substrings; minor wording variation does not break the tests.
- The G2 boundary fixture assembles the `[T99]` forbidden token at runtime
  via string concatenation so this test file's own source does not trip
  the corpus-wide sweep gate.
