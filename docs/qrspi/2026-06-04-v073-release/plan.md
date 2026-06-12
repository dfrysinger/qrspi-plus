---
status: draft
phase_start_commit: null
test_writer_tier: null
---

# Implementation Plan

## Overview

v0.7.3 ships pipeline-correctness fixes for the eight P0 defects surfaced by the v0.7.2 self-host run plus a release-wide active-skill-prompt footprint reduction, in a single phase with a single end-to-end slice. The slice extends the v0.7.2 universal dispatch chain with two new orchestration-facing scripts (`upstream-paths.sh`, `review-prep.sh`) and two new observability/validation scripts (`orchestration-boundary-check.sh`, `validate-stage-commit-parents.sh`); adds rubric clauses to four reviewer/verifier agent bodies; promotes the implementer Pre-DONE self-check from advisory to blocking; sweeps `[Tnn]` / `R\d+-F\d+` tokens from `@test` descriptions across the test corpus and pins them out with a permanent CI lint; centralises plugin version stamping behind a repo-root `VERSION` file; lands the R8 prose-density rule in `prompt-design-rules.md`; and applies a 4-pass trim (three-tier placement → delete script-mechanic restatements → R8 tightening → regression-guard execution) to all 14 active skills against six new `_shared/` snippets `!cat`-resolved at skill-load time.

Per `phasing.md`, all nine goals (G1–G9) and all three cross-goal design decisions (CD-1, CD-2, CD-3) ship together in Phase 1; there is no Phase 2, no replan gate between phases, and no content deferred to `future-*.md`.

## Phase 1: v0.7.3 release

Tasks are enumerated below. Each task carries `goal_id(s)`, `task_type`, `tier`, an LOC estimate, dependencies, and a one-sentence behavior claim. Per-task spec bodies follow the partition table below as `### Txx:` blocks in this document.

Sizing notes: `task_type: lightweight` is used where the deliverable is prompt prose only (SKILL.md / `agents/*.md` edits) — Test Expectations on those tasks will use the rules-application clause from Plan SKILL § Prompt-prose Test-Expectations clause. `task_type: tdd` is used for any task that ships or modifies a bash script, a bats fixture, or a JS build script. `sizing_exception` is named (per the closed exception set, whose canonical field values are exactly `schema-migration`, `ci-scaffolding`, `reusable-primitives` — the lowercased-hyphenated forms; prose references to the class names use the human forms "schema migration", "CI scaffolding", "reusable primitives") on tasks expected to exceed the 200-LOC ceiling. The hyphenated form is the single source of truth used in every `sizing_exception:` field across this plan; downstream consumers grep for the literal hyphenated values.

### Task partition (43 tasks) — overview

| ID | Title | goal_id(s) | task_type | tier | LOC | Deps | One-sentence behavior |
|----|-------|------------|-----------|------|-----|------|-----------------------|
| T01 | Create scripts/upstream-paths.sh with always-appended hygiene path, fail-soft unknown-step, and Plan-step branch | CD-1, G1, G4 | tdd | high | ~150 | none | Per-step upstream-artifact path list is emitted by a context-free script that honours the always-appended SKILL paths (including the canonical ID-hygiene authority) and reads `pipeline:` from `<artifact-dir>/config.md` only for the Plan branch; an unknown `--step` value returns the always-appended SKILL paths and exits 0 (per design.md CD-1 Acceptance bullet 2). |
| T02 | Create scripts/design-absorption-markers.sh | G3 | tdd | medium | ~80 | none | Grep `design.md` for the 4 enumerated absorption markers and print a tab-separated `<absorbed-ID> <absorbing-ID|"no-task">` redirect map to stdout. |
| T03 | Create scripts/review-prep.sh for per-step pre-dispatch input generation | CD-2, G3, G7 | tdd | high | ~180 (sizing_exception: reusable-primitives) | T02 | Per-step diff (narrowed via the anchor-file `cat` of `reviews/<step>/round-<NN-1>-commit.txt`, not `HEAD~1`) and per-step absorption-map (at Design and Plan) are written to known paths under `<artifact-dir>/reviews/<step>/round-NN.*`. |
| T04a | Add high-level entry mode to scripts/dispatch-agent.sh | CD-2 | tdd | high | ~80 | T03 | When `--step --round --artifact-dir` accompany the existing flags, dispatch-agent invokes `review-prep.sh` first and threads `diff_file_path` / `absorption_map_path` into reviewer prompts. |
| T04b | Add subagent author-marker env wrap to scripts/dispatch-agent.sh | G5 | tdd | high | ~50 | none | Every dispatched subagent git command is wrapped with the subagent author-marker scheme (a `GIT_AUTHOR_NAME=qrspi-<agent>` env composition validated against the agent-name charset) so subagent commits carry the marker the G5 boundary check filters on. |
| T05 | Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs | CD-2, G9 | lightweight | medium | ~80 (sizing_exception: schema-migration) | T04a | Each of `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` § Review Round replaces the pre-dispatch Bash diff-redirect prose with one `dispatch-agent.sh --step <step> --round NN --artifact-dir <ABS>` invocation; the mechanical-sweep structural lint proves the diff is documented-removal patterns plus the dispatch-agent invocation addition only. |
| T06 | Create tests/lint/test-no-diff-redirect-prose.bats | CD-2, G9 | tdd | low | ~25 | T05 | Grep audit asserts zero `git diff > round-NN.diff` Bash redirect blocks remain in the eight artifact-step skills. |
| T07 | Insert R8 prose-density rule in skills/_shared/prompt-design-rules.md | CD-3 | lightweight | medium | ~90 | none | New `### R8 — Prose density: short declarative sentences, full behavioral precision` section is added between R7 and the cross-cutting-principles `---` separator, and the finding-type gate `rule-violation` row cites `R1-R8`. |
| T08 | Create tests/lint/test-prompt-design-rules-r8.bats | CD-3 | tdd | low | ~35 | T07 | Anchor-phrase grep verifies R8 heading, tightening-pattern table header, "What NOT to tighten" subheading, reviewer-test sentence, the literal `R1-R8` gate citation, no duplicated R-rule headings, and every cited R-ID exists as a heading. |
| T09 | Append ID-hygiene rubric clause to agents/qrspi-finding-verifier.md | G1 | lightweight | high | ~20 | T01 | The verifier rubric directs grounding of forbidden-token-table findings in `skills/implementer-protocol/SKILL.md` § Hygiene contract via `<upstream_paths>` Read, treating its absence as a dispatch defect with no improvised fallback. |
| T10 | Create tests/unit/test-finding-verifier-id-hygiene-grounding.bats | G1 | tdd | high | ~70 | T09, T01 | A synthetic verifier dispatch on a `[Tnn]` fixture finding scores ≥ 70 against the hygiene contract; a regression-direction case against a v0.7.2-baseline rubric stub scores < 70. |
| T11 | Sweep [Tnn] and forbidden-finding-ID tokens from @test descriptions across tests/**/*.bats | G2 | tdd | medium | sizing_exception: schema-migration | T09 | A single mechanical sweep across the bats corpus strips the leading/trailing forbidden token patterns from inside `@test "..."` description strings only; intentional fixture tokens that need to appear in test bodies are emitted into generated fixture files under `tests/fixtures/` and never inlined into `@test "..."` descriptions, so the raw zero-match grep at the Phase-1 acceptance criterion passes without carve-out. Sequenced after T09 so the v0.7.3 self-host's own reviewers do not false-negative the sweep findings. |
| T12 | Create tests/lint/test-bats-test-name-id-hygiene.bats permanent CI lint | G2 | tdd | medium | ~50 | T11 | The lint greps every `@test` line under `tests/**/*.bats` and fails when a description matches a forbidden internal-ID or finding-ID token; an inline carve-out marker on a fixture-construction line inside a test body (only) exempts that body line from the lint match. |
| T13a | Promote implementer-protocol Pre-DONE self-check to blocking | G2 | lightweight | medium | ~20 | none | One anchor sentence promotes the Pre-DONE self-check from advisory to halt-DONE on any ID-hygiene match in added/modified `@test "..."` description strings. |
| T13b | Add revert-orchestration-drift fix-task mode to implementer-protocol with halt-on-conflict | G5 | lightweight | medium | ~25 | T19 | One new fix-task mode reverts non-subagent commits surfaced by the G5 boundary report after validating each SHA against the well-formed git object-name shape; on any single revert failure (conflict, merge-without-`-m`, deleted file) the subagent halts immediately, writes `orchestration-boundary-revert-failed.md`, and exits non-zero with skip-and-continue forbidden. |
| T14 | Create tests/unit/test-id-hygiene-lint-fail-direction.bats | G2 | tdd | low | ~30 | T12 | Drives the new lint against a generated fixture file under `tests/fixtures/` containing a forbidden internal-ID token and asserts non-zero exit with the documented diagnostic; the fixture file is generated by a test-body emit step (carrying the body-line carve-out marker) so the lint never sees the token in an `@test` description. |
| T15 | Add pre-fanout absorption-map anchor sentence to skills/plan/SKILL.md | G3 | lightweight | high | ~15 | T02 | The verbatim anchor sentence directs the plan-author to run `design-absorption-markers.sh`, ingest the redirect map, refuse standalone tasks for absorbed IDs, and halt with BLOCKED rather than manufacture a task home. |
| T16 | Append G3 rubric clauses to plan-spec and design reviewer agent bodies | G3 | lightweight | medium | ~40 | T02 | `agents/qrspi-plan-spec-reviewer.md` asserts no plan task carries an absorbed-goal ID; `agents/qrspi-design-reviewer.md` verifies the map preserves authorial intent across every entry. |
| T17a | Create tests/unit/test-plan-spec-reviewer-absorption.bats | G3 | tdd | medium | ~30 | T16, T02 | A synthetic plan.md drafted with an absorbed-ID task produces a `change_type: scope` finding from the plan-spec reviewer, and a Plan-step dispatch with `absorption_map_path:` absent halts non-zero with a `dispatch-defect:` named diagnostic. |
| T17b | Create tests/unit/test-design-reviewer-fidelity.bats | G3 | tdd | low | ~25 | T16, T02 | A synthetic design.md with an intent/marker contradiction produces a fidelity-mismatch finding from the design reviewer. |
| T17c | Create tests/unit/test-design-reviewer-dispatch-defect.bats | G3 | tdd | low | ~25 | T16, T02 | A Design-step dispatch with `absorption_map_path:` absent halts the reviewer non-zero with a `dispatch-defect:` named diagnostic instead of silently no-op'ing. |
| T18 | Create tests/lint/test-design-absorption-marker-set.bats structural lint | G3 | tdd | low | ~30 | T02 | Scan every `design.md` under `docs/qrspi/**/`; any absorption-shaped marker text MUST match one of the 4 enumerated patterns, and drift surfaces as a lint failure on the design.md PR. |
| T19 | Create scripts/orchestration-boundary-check.sh with per-phase phase-base dispatch, SHA-format validation, dispatch-defects section, and bats unit test | G5 | tdd | high | ~180 (sizing_exception: ci-scaffolding — full coverage matrix) | none | Phase-end script runs `git status --porcelain` (with `reviews/` tree excluded) and `git log <phase-base>..HEAD` post-filtered for non-`qrspi-` authors via the OBC author-marker filter; reads `<phase-base>` per `--phase` value (`implement` → G6 wave-1 sidecar; `integration`/`test` → `reviews/<phase>/phase-base.txt`), validates every SHA read from disk against the well-formed git object-name shape before any `git` invocation, and writes `reviews/<phase>/orchestration-boundary.md` with violations partitioned into a distinct `## Dispatch defects` section (missing/malformed phase-base.txt, malformed OBC author-name records) separate from the existing commit/workspace sections. |
| T20a | Wrap Wave Dispatch merge step with stage-commit parent-validation calls in skills/implement/SKILL.md | G6 | lightweight | medium | ~40 | T25 | `skills/implement/SKILL.md` § Wave Dispatch step 6 wraps the existing `git merge --no-ff` with pre-merge `--capture` and post-merge `--validate` calls to `validate-stage-commit-parents.sh`. |
| T20b | Insert OBC step and interactive/autopilot batch-gate additions with dispatch-defect branch in skills/implement/SKILL.md | G5 | lightweight | medium | ~70 | T19 | A new Step-N orchestration-boundary observability block plus interactive/autopilot batch-gate additions land before the batch gate; the autopilot branched-default carries a third "Dispatch defects → halt unconditionally, write `HALT-orchestration-boundary-undeterminable.md`, exit autopilot loop" branch alongside the existing commit-based and uncommitted-workspace branches. |
| T21 | Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/integrate/SKILL.md | G5 | lightweight | medium | ~110 | T19, T04b | `skills/integrate/SKILL.md` carries the verbatim HARD-RULE section, the Step-N OBC check, the interactive/autopilot batch-gate additions, and a phase-start write of `reviews/integration/phase-base.txt` as the first orchestrator action of the phase (before any subagent dispatch). |
| T22 | Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/test/SKILL.md | G5 | lightweight | medium | ~110 | T19, T04b | `skills/test/SKILL.md` carries the verbatim HARD-RULE section (with the `reviews/test/round-NN-results.md` allowlisted-write exception), the Step-N OBC check, batch-gate additions, and a phase-start write of `reviews/test/phase-base.txt` as the first orchestrator action of the phase. |
| T23 | Insert cross-cutting Orchestration Boundary note in skills/using-qrspi/SKILL.md | G5 | lightweight | low | ~15 | T19 | The verbatim `### Orchestration Boundary applies to every phase` cross-cutting note lands in `using-qrspi/SKILL.md`, pointing readers at the per-phase prose. |
| T24 | Create tests/lint/test-integrate-test-skill-phase-base-write.bats | G5 | tdd | low | ~30 | T21, T22 | Anchor-phrase grep asserts `skills/integrate/SKILL.md` and `skills/test/SKILL.md` each carry the phase-base.txt write step at phase start, locking the write side against silent SKILL-prose drift that would break OBC integration/test read paths. |
| T25 | Create scripts/validate-stage-commit-parents.sh with --capture/--validate, SHA-format validation, and bats unit test | G6 | tdd | high | ~150 | none | `--capture` writes integration-base SHA + per-task-tip SHAs to a runtime sidecar under `reviews/implement/wave-state/`; `--validate` reads it (validating every SHA against the well-formed git object-name shape before any `git` invocation), reads actual parents from `git log --format='%P'`, asserts first-parent equality and task-tip set equality, halts non-zero with the named `stage-commit-parent-mismatch:` diagnostic on failure. |
| T26 | Replace HEAD~1 with anchor-file lookup in using-qrspi Apply-fix step 12 and sweep inlining skills | G7 | lightweight | medium | ~25 | none | Per-step narrow-ref incantation becomes `git diff "$(cat reviews/<step>/round-<NN-1>-commit.txt)" -- <artifact-path>` (with the anchor-file SHA validated against the well-formed git object-name shape before the `git diff` runs); any other skill that inlines step-12's `HEAD~1` is updated identically; the divergence-sanity-check halt with `narrow-round-empty-diff:` diagnostic is preserved. |
| T27 | Create tests/unit/test-narrow-round-anchor-lookup.bats | G7 | tdd | medium | ~60 | T26 | A fixture with an unrelated commit between rounds proves the anchor-file-based diff returns round N's content while `HEAD~1`-based diff returns wrong content; missing anchor file exits non-zero with no silent fallback; empty narrowed diff fires the divergence-sanity-check diagnostic. |
| T28 | Create VERSION file and stamp the five consumer manifests from tools/build-plugin.mjs with bats coverage | G8 | tdd | high | ~120 | none | Repo-root `VERSION` (bare one-line) is the sole authoring path; `tools/build-plugin.mjs` reads it and writes the value into `"version"` of all five consumer files, halting with `version-source-missing-or-malformed:` on missing/empty/multi-line VERSION; the bats round-trip test proves `echo "9.9.9" > VERSION && node tools/build-plugin.mjs` propagates to all five files. |
| T29 | Create .github/workflows/build-then-diff.yml CI gate | G8 | tdd | medium | ~40 | T28 | A CI step runs `node tools/build-plugin.mjs && git diff --exit-code` on every PR and fails on any divergence between freshly-built tree and committed tree (catches version drift, build-artifact drift, marketplace `source` drift). |
| T30 | Document the new release flow in docs/release-runbook.md | G8 | lightweight | low | ~30 | T28 | Runbook prose names `VERSION` as the only file an author edits to bump, describes the `node tools/build-plugin.mjs` propagation step, and commits the resulting diff (VERSION + propagated stamps + regenerated `build/` content) as one release commit. |
| T31 | Create the 6 skills/_shared/ snippet files | G9 | lightweight | medium | ~exempt (sizing_exception: reusable-primitives) | none | `skills/_shared/{reviewer-dispatch,review-loop,config-validation,compaction-checkpoint,pause-gate,feedback-format}.md` are authored as the single source of truth for the multi-skill load-bearing process boilerplate that consuming skills `!cat`-resolve at skill-load time. |
| T32 | Trim skills/using-qrspi/SKILL.md (Pass 1+2+3) to target <350 lines | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives (canonical bootstrapper trim) | T07, T31, all G1–G7 prose-adding tasks | Three-tier placement applied, script-mechanic restatements deleted, R8 tightening applied; using-qrspi becomes the thin universal-orchestrator-behaviour bootstrapper with `!cat` references to `_shared/` snippets. |
| T33 | Trim skills/implement/SKILL.md (Pass 1+2+3) to target <500 lines | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives | T07, T31, T20a, T20b | 4× verifier-wiring duplication and 2× visual-fidelity duplication collapsed; jobId / tmpfile / HEAD~1 / convergence-table / sidecar-schema / change_type-enum / third-party-splitter narrative restatements deleted; `_shared/` `!cat` references added. |
| T34 | Trim skills/plan/SKILL.md (Pass 1+2+3) to target <400 lines | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives | T07, T31, T15 | Same four-pass application; the new pre-fanout absorption-map anchor sentence (T15) is preserved through the trim. |
| T35 | Trim the 8 artifact-step skills (goals/questions/research/design/phasing/structure/parallelize/replan) to target <300 lines each | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives (8-file bulk pass) | T07, T31, T05 | Each artifact-step SKILL applies the four-pass trim against its post-T05 state (high-level-dispatch prose already in place); per-skill `references/<topic>.md` files are created at extract time for any optional/example content. |
| T36 | Trim the 7 cross-cutting skills (integrate/test/implementer-protocol/reviewer-protocol/research-isolation/prompt-prose-writer/prompt-prose-reviewer) to target <300 lines each | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives (7-file bulk pass) | T07, T31, T13a, T21, T22 | Each cross-cutting SKILL applies the four-pass trim against its post-T13a/T21/T22 state (G2/G5/G2 additions already in place); per-skill `references/<topic>.md` files are created at extract time. |
| T37 | Create scripts/measure-active-footprint.sh, run it against the trimmed tree, and write docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md | G9 | tdd | medium | ~120 | T32, T33, T34, T35, T36 | The measurement script resolves `!cat` references transitively (with cycle detection and named diagnostics for unresolvable references), tokenises with a pinned tokenizer (default `tiktoken:cl100k_base`), and emits a per-turn footprint count; the captured stdout is the body of `g9-footprint-report.md`. |
| T38 | Create tests/lint/test-skill-trim-audit.bats grep audit | G9 | tdd | low | ~35 | T32, T33, T34, T35, T36 | The lint asserts zero matches across all active SKILL.md files for `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, and `third-party.*splitter` (narrative restatements; concrete script names in process-step calls are fine). |

### Dependency graph

Critical-path ordering, honouring goals.md § Cross-Cutting Notes (G1 → G2 prerequisite; G6/G7 paired round-mechanics surface; G9 lands last; G8 independent; CD-1 prerequisite for G1 always-appended path).

```
Foundations (no upstream deps):
  T01 (upstream-paths.sh — CD-1 + G1 always-append + G4 Plan branch)
  T02 (design-absorption-markers.sh — G3 primitive)
  T04b (dispatch-agent subagent author-marker env wrap — G5 primitive, independent of high-level mode)
  T07 (R8 rule in prompt-design-rules.md — CD-3 primitive)
  T13a (implementer-protocol Pre-DONE blocking — G2)
  T15 (plan SKILL pre-fanout anchor — depends on T02)
  T16 (G3 reviewer rubric clauses — depends on T02)
  T18 (design-marker structural lint — depends on T02)
  T19 (orchestration-boundary-check.sh — G5 primitive)
  T25 (validate-stage-commit-parents.sh — G6 primitive)
  T26 (using-qrspi HEAD~1 → anchor-file lookup — G7 in-place edit)
  T28 (VERSION + build-plugin.mjs stamper — G8 primitive)
  T31 (skills/_shared/ snippets — G9 primitive)

CD-1 / G1 / G4 prerequisite chain (G1 → G2 gate):
  T01 → T09 (verifier rubric clause) → T10 (verifier bats)
  T01 → T11 (G2 sweep — fires only after G1 verifier rubric lands)
  T11 → T12 (permanent CI lint) → T14 (fail-direction fixture)

CD-2 chain (review-prep + dispatch-agent high-level + skill-prose replacement):
  T02 → T03 (review-prep.sh — also G3 + G7 surface)
  T03 → T04a (dispatch-agent high-level entry mode)
  T04a → T05 (8 artifact-step SKILL high-level-dispatch replacement) → T06 (lint)

CD-3 chain:
  T07 → T08 (R8 lint)

G3 chain (post-T02 fan-out):
  T02 → T15 / T16 / T18
  T02 + T16 → T17a (plan-spec-reviewer absorption + Plan-step dispatch-defect halt)
  T02 + T16 → T17b (design-reviewer fidelity)
  T02 + T16 → T17c (design-reviewer dispatch-defect halt at Design step)

G5 chain (post-T19 fan-out; T04b carries the subagent author-marker the OBC filters on):
  T19 → T13b (revert-orchestration-drift fix-task mode)
  T19 → T20b (implement OBC step + interactive/autopilot batch-gate with dispatch-defect branch)
  T19 + T04b → T21 (integrate OBC + phase-base.txt write)
  T19 + T04b → T22 (test OBC + phase-base.txt write)
  T19 → T23 (using-qrspi cross-cutting note)
  T21 + T22 → T24 (phase-base-write lint)

G6 / G7 paired round-mechanics surface:
  T25 → T20a (implement Wave Dispatch stage-commit-parents wrap)
  T26 → T27 (anchor-file lookup bats)

G8 chain (independent of skill surface):
  T28 → T29 (build-then-diff CI workflow)
  T28 → T30 (release runbook)

G9 lands last (all goal surfaces stable; sequenced after T05, T13a, T13b, T15, T20a, T20b, T21, T22, T26 prose-adding tasks):
  T07 + T31 + all prose-adding tasks → T32 (using-qrspi trim)
  T07 + T31 + T20a + T20b → T33 (implement trim)
  T07 + T31 + T15 → T34 (plan trim)
  T07 + T31 + T05 → T35 (8 artifact-step skill trim)
  T07 + T31 + T13a + T13b + T21 + T22 → T36 (7 cross-cutting skill trim — T13a carries the Pre-DONE blocking prose; T13b carries the revert-orchestration-drift fix-task mode added in implementer-protocol)
  T32–T36 → T37 (measure-active-footprint.sh + g9-footprint-report.md)
  T32–T36 → T38 (skill-trim audit lint)
```

Symbolic-only branch-map invariant (research Q11/Q12) is preserved: resolved task-tip SHAs from G6 live in a runtime sidecar under `reviews/implement/wave-state/`, not in `parallelization.md`.

### Phase 1 Acceptance Criteria

End-to-end observable at phase boundary; each criterion traces to one or more goals in `goals.md`:

- [ ] Every goal-level `**Acceptance.**` subsection in `design.md` passes against the merged integration branch (G1–G9, CD-1–CD-3).
- [ ] `scripts/upstream-paths.sh --step <step>` emits the documented set for every supported step including the new Plan branch in both pipeline modes, and the always-appended array contains `skills/implementer-protocol/SKILL.md` (CD-1, G1, G4). An unknown `--step` value returns the always-appended SKILL paths only and exits 0 (per design.md CD-1 Acceptance bullet 2 — fail-soft direction); Plan-step missing/malformed `config.md` exits non-zero with its own named diagnostic.
- [ ] `scripts/dispatch-agent.sh --step --round --artifact-dir` high-level mode produces dispatch prompts identical in content to the equivalent low-level invocation with pre-computed paths (CD-2).
- [ ] Pre-dispatch Bash diff-redirect prose shrinkage across the eight artifact-step SKILLs totals ≥ 80 lines removed versus the v0.7.2 baseline (~≥ 10 lines per file × 8 files) — CD-2 quantitative acceptance.
- [ ] `skills/_shared/prompt-design-rules.md` carries R8 verbatim and the finding-type gate `rule-violation` row cites `R1-R8` (CD-3).
- [ ] A synthetic verifier dispatch on a `[Tnn]` fixture finding scores ≥ 70 against `skills/implementer-protocol/SKILL.md` § Hygiene contract (G1).
- [ ] `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` returns zero matches; `tests/lint/test-bats-test-name-id-hygiene.bats` rejects a synthetic regression PR that re-introduces `[T99]` (G2).
- [ ] The v0.7.3 self-host Plan step round-01 produces zero plan-spec-reviewer absorption findings (meta-acceptance for G3).
- [ ] The v0.7.3 self-host Plan-step verifier dispatch carries a deterministic `upstream_paths` parameter equal to the fixture-expected set for `pipeline: full` (G4).
- [ ] The v0.7.3 self-host Integrate phase produces an empty `reviews/integration/orchestration-boundary.md`; every subagent commit in the integration-branch phase range carries the `qrspi-<agent>` author marker (G5). Missing/malformed `reviews/<phase>/phase-base.txt` at OBC time surfaces as a violation in a distinct `## Dispatch defects` section in the report and triggers the autopilot's unconditional dispatch-defect halt (G5 fail-loud branch).
- [ ] The Implement-phase autopilot terminates the wave loop and writes `HALT-orchestration-boundary-undeterminable.md` when the OBC report carries any `## Dispatch defects` entry; no skip-and-continue path exists (G5).
- [ ] G9 Pass 4 regression-guard execution against the v0.7.2 phase-1 acceptance suite stays green across every trim task (G9).
- [ ] Every Implement-wave stage commit in the v0.7.3 self-host passes `validate-stage-commit-parents.sh --validate` silently; `parallelization.md` is unchanged across the phase (G6).
- [ ] Every step-12 narrow-round dispatch across the v0.7.3 self-host resolves its diff ref by reading `reviews/<step>/round-<NN-1>-commit.txt` (G7).
- [ ] `VERSION` is bumped exactly once to `0.7.3`, a single `node tools/build-plugin.mjs` invocation propagates to all five consumer manifests, and the `.github/workflows/build-then-diff.yml` CI gate passes on the release commit; `.github/plugin/*` stays in lockstep with `.claude-plugin/*` per `goals.md` § Constraints (G8).
- [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`) passes against the trimmed skill set with zero regressions; `scripts/measure-active-footprint.sh` reports < 30K tokens per typical session, captured at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (G9).

### Project Environment Fields

- `build_command: 'none'` — qrspi-plus is a bash + agent-prose plugin with no per-task compile step. `tools/build-plugin.mjs` is invoked only at release time (G8's flow), not during per-task implementer verification.
- `dev_command:` omitted — no v0.7.3 task declares a `smoke_checks:` block (the release touches scripts, agent bodies, skill prose, lint tests, and the build script; no route / page / layout / user-facing-component surface is added or modified).

## Task Specs

### T01: Create scripts/upstream-paths.sh with always-appended hygiene path, fail-soft unknown-step, and Plan-step branch
- **Phase:** 1
- **Goal IDs:** [CD-1, G1, G4]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/upstream-paths.sh` (Create), `tests/unit/test-upstream-paths.bats` (Create), `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~150
- **cross_task_consumers:**
  - `agents/qrspi-finding-verifier.md` (T09) — `co-edit` not applicable here (T09 is a separate task that consumes this script's output via the new rubric clause's `<upstream_paths>` Read); disposition: `pass-through`.
  - `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (T10) — disposition: `pass-through` (T10 reads the script's stdout for the assertion; no edit to this task's deliverables required).
- **Atomicity note:** Single observable: one script emitting the per-step path manifest; per-step branches (Goals/Questions/Research/Design/Phasing/Structure/Parallelize/Replan/Plan/unknown, plus the always-appended SKILL list including the Plan-branch config.md read) are internal control flow, not separate deliverables. The task is one coherent script with one well-defined contract surface and is not split.
- **Author note:** silent-claude R01-F03 raised a silent-degrade concern about the unknown-step fail-soft branch (the script returns the always-appended SKILL paths and exits 0 — a verifier dispatched against an unrecognised step still receives the SKILL paths and can produce a plausible-looking review without the artifact upstream paths the step actually requires). Addressing it would require a design.md amendment changing CD-1 Acceptance bullet 2 from fail-soft to fail-loud; the approved design currently mandates the fail-soft direction (CD-1 Acceptance bullet 2 + structure.md row 17). This plan honours the design contract and does not introduce a plan-side workaround. Re-opening the contract is a Design-phase decision, not a Plan-phase one.
- **Description:** A context-free script emits the per-step upstream-artifact path list to stdout, honouring the always-appended SKILL paths (including `skills/implementer-protocol/SKILL.md` as the canonical ID-hygiene authority) and reading `pipeline:` from `<artifact-dir>/config.md` only on the Plan branch. The script accepts `--step <step>` and optional `--artifact-dir <path>` and prints repo-relative paths and step-relative artifact basenames (the orchestrator joins them against `<abs_path>` per the existing dispatch composition pattern). An unknown `--step` value returns the always-appended SKILL paths only and exits 0 (per design.md CD-1 Acceptance bullet 2 and structure.md row 17 — fail-soft direction; the orchestrator's prose behaviour on an absent step was non-erroring, and the script preserves that contract). Missing or malformed `config.md` on the Plan branch halts non-zero with its own named diagnostic. The using-qrspi SKILL.md edit rewrites the prior "Per-step upstream-artifact lists" prose block into a one-line directive citing `scripts/upstream-paths.sh` as the sole source of truth for the per-step path set.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - For every supported step (Goals, Questions, Research, Design, Phasing, Structure, Parallelize, Replan), the script prints the documented set — captured against a fixture (traces design.md CD-1 Acceptance bullet 1).
  - Unknown step name returns the always-appended SKILL paths only and exits 0 — no diagnostic on stderr (CD-1 Acceptance bullet 2 — fail-soft direction; matches structure.md row 17).
  - Plan-step with `pipeline: full` config returns `goals.md, research/summary.md, design.md, phasing.md, structure.md` plus the always-appended SKILL paths (G4 Acceptance bullet 1).
  - Plan-step with `pipeline: quick` config returns `goals.md, research/summary.md` plus the always-appended SKILL paths (G4 Acceptance bullet 2).
  - Plan-step with missing or malformed `config.md` halts with the documented named diagnostic and exits non-zero (G4 Acceptance bullet 3).
  - The always-appended array contains `skills/implementer-protocol/SKILL.md` (G1 Acceptance bullet 2).
  - The using-qrspi SKILL.md no longer contains the per-step upstream-artifact prose block; it carries a one-line directive citing `scripts/upstream-paths.sh` (CD-1 Acceptance bullet 3).

### T02: Create scripts/design-absorption-markers.sh
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `scripts/design-absorption-markers.sh` (Create), `tests/unit/test-design-absorption-markers.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~80
- **cross_task_consumers:**
  - `scripts/review-prep.sh` (T03) — disposition: `pass-through` (T03 invokes this script for Design and Plan steps; T03 owns its own caller-side code).
  - `skills/plan/SKILL.md` (T15) — disposition: `pass-through` (T15 adds an anchor sentence directing the plan-author to run this script; the script itself is not edited).
  - `agents/qrspi-plan-spec-reviewer.md`, `agents/qrspi-design-reviewer.md` (T16) — disposition: `pass-through` (T16 adds rubric clauses that consume the script's output via the absorption map; the script is not edited).
  - `tests/unit/test-plan-spec-reviewer-absorption.bats`, `tests/unit/test-design-reviewer-fidelity.bats`, `tests/unit/test-design-reviewer-dispatch-defect.bats` (T17a/T17b/T17c) — disposition: `pass-through` (these reviewer-fixture tests consume the script's output via fixtures; no edit to this task's deliverables required).
  - `tests/lint/test-design-absorption-marker-set.bats` (T18) — disposition: `pass-through` (the lint enforces the marker-set discipline this script depends on; no edit to this task's deliverables required).
- **Description:** A script reads `design.md` from an explicit path argument and prints a tab-separated absorbed-goal redirect map to stdout, one line per absorbed ID with the absorbing-ID (or the sentinel `no-task`) in the second column. The script recognises exactly the four canonical absorption-marker forms enumerated in G3.a (heading-suffix moot/absorbed/already-fixed, block-internal explicit-non-goal, acceptance-criterion no-separate-task, free-prose deferred-to); marker shapes outside that enumerated set are not recognised (T18's structural lint owns the marker-set discipline). A marker-free design.md exits 0 with empty stdout; a missing or unreadable design path exits non-zero with a named diagnostic.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Against a fixture design.md containing all 4 marker forms, the script returns the expected map — one line per absorbed ID with the correct absorbing-ID column (G3 Acceptance bullet 1, first half).
  - Against a marker-free design.md, the script returns empty stdout and exits 0 (G3 Acceptance bullet 1, second half).
  - Each of the 4 enumerated marker forms is independently exercised by a fixture (regression guard against pattern drift).
  - A fixture containing a non-enumerated absorption-shaped marker is NOT recognised (the script ignores it; T18's structural lint owns the marker-set discipline).
  - Missing or unreadable design path exits non-zero with a named diagnostic, not a silent empty map.

### T03: Create scripts/review-prep.sh for per-step pre-dispatch input generation
- **Phase:** 1
- **Goal IDs:** [CD-2, G3, G7]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/review-prep.sh` (Create), `tests/unit/test-review-prep.bats` (Create)
- **Dependencies:** T02
- **LOC estimate:** ~180 (sizing_exception: reusable-primitives — single owner for per-step pre-dispatch input generation across all artifact steps)
- **cross_task_consumers:**
  - `scripts/dispatch-agent.sh` (T04a) — disposition: `pass-through` (T04a invokes this script from the high-level entry mode and threads the produced paths into reviewer prompts; this script is not edited by T04a).
- **Description:** A new script `scripts/review-prep.sh --step <step> --round <N> --artifact-dir <path>` produces all per-step pre-dispatch artifact-derived inputs (diff with narrowing ref, absorption-map where applicable, future inputs) and writes them to known relative paths under `<artifact-dir>/reviews/<step>/round-NN.*`. A step-specific generation table lives internal to the script: Design and Plan produce diff plus absorption-map (consuming `scripts/design-absorption-markers.sh`); Goals produces diff only; Research / Phasing / Structure / Parallelize produce diff with appropriate narrowing; per-task implement review produces a per-task diff. Diff narrowing follows the existing per-round anchor-file convergence rule (G7) — the script reads `reviews/<step>/round-<NN-1>-commit.txt` rather than using `HEAD~1`. Every SHA read from `reviews/<step>/round-<NN-1>-commit.txt` is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE being passed to any `git` invocation; a SHA failing the shape check halts non-zero with the `sha-format-invalid:` named diagnostic. The default branch on "artifact-dir not in a git repo" or "git diff produced no output when a diff was expected" is fail-loud: the script exits non-zero with the named diagnostic `review-prep-no-diff-source:` (artifact-dir not a git working tree) or `review-prep-empty-diff:` (git diff returned no output for a step that requires one). The legitimate fixture-only "silent empty output" shape is opt-in via an explicit `--allow-empty-no-diff` flag — without that flag, the production-default direction halts loud. A corrupt artifact-dir halts non-zero with its own named diagnostic (`review-prep-corrupt-artifact-dir:`). dispatch-agent (T04a) is the sole orchestrator-visible caller and never passes `--allow-empty-no-diff` for a real review round.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The script "produces the documented input set for each supported step" — one bats fixture per step asserts the expected files appear at `<artifact-dir>/reviews/<step>/round-NN.*` (CD-2 Acceptance bullet 1, first half).
  - A `--step plan` fixture asserts the absorption-map is written to the expected path for the plan-spec reviewer to consume (CD-2 Acceptance bullet 1, parenthetical for G3 change 3).
  - A `--step design` fixture asserts both the diff and the absorption-map are produced.
  - A `--step goals` fixture asserts only the diff is produced (no absorption-map, no error).
  - Diff narrowing in round ≥ 2 reads `reviews/<step>/round-<NN-1>-commit.txt` for the narrowing ref; a fixture proves the resulting diff matches round (N-1)'s per-round commit content (traces G7 Acceptance bullet 3, sub-bullet 1).
  - A SHA read from `reviews/<step>/round-<NN-1>-commit.txt` that fails the well-formed git object-name shape (e.g., uppercase hex, length outside 7–64, non-hex characters) halts non-zero with the `sha-format-invalid:` named diagnostic — no `git` command runs against the malformed value.
  - A corrupt artifact-dir surfaces the `review-prep-corrupt-artifact-dir:` named diagnostic and non-zero exit (CD-2 Acceptance bullet 1, second half — "fail-loud on a corrupt artifact-dir").
  - Production-default invocation (no `--allow-empty-no-diff` flag): artifact-dir not in a git repo halts non-zero with the `review-prep-no-diff-source:` named diagnostic; a step that requires a diff but `git diff` produced no output halts non-zero with the `review-prep-empty-diff:` named diagnostic — neither condition silently degrades (silent-claude R2-F01 fail-loud direction).
  - Fixture-only invocation with the explicit `--allow-empty-no-diff` flag: the legitimate non-git fixture case emits no files and exits 0 (preserves the test-fixture surface that R2-F01 carved out via opt-in).
  - A side-by-side fixture proves dispatch-agent's high-level invocation produces a prompt byte-identical to the equivalent low-level invocation with pre-computed paths (design.md CD-2 Acceptance bullet 2 — paired-coverage assertion with T04a).

### T04a: Add high-level entry mode to scripts/dispatch-agent.sh
- **Phase:** 1
- **Goal IDs:** [CD-2]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/dispatch-agent.sh` (Modify), `tests/unit/test-dispatch-agent-highlevel-mode.bats` (Create)
- **Dependencies:** T03
- **LOC estimate:** ~80
- **cross_task_consumers:**
  - `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/phasing/SKILL.md`, `skills/structure/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md` (T05) — disposition: `pass-through` (T05 calls the new flag set in every artifact-step SKILL § Review Round; the dispatch-agent script itself is not edited by T05, and the consumer-side edits live in T05).
  - `scripts/review-prep.sh` (T03) — disposition: `pass-through` (this task's high-level mode invokes review-prep; review-prep's own production-default contract handles its own failure direction per T03).
- **Description:** `scripts/dispatch-agent.sh` gains a high-level entry mode keyed on the presence of `--step <step> --round <N> --artifact-dir <path>` in addition to today's `--output-dir / --artifact / --agents` batched-mode flags. In high-level mode, dispatch-agent invokes `scripts/review-prep.sh` first and threads the produced paths into reviewer prompts as `diff_file_path:` and `absorption_map_path:` parameters. The existing low-level `--diff-file <path>` mode is preserved for tests and non-standard callers. review-prep failure propagates verbatim — dispatch-agent exits non-zero with review-prep's stderr; the high-level entry never sets `--allow-empty-no-diff` so the production-default fail-loud direction from T03 is the only path through review-prep in a real review round.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - High-level `--step --round --artifact-dir` invocation produces a dispatch byte-identical (in prompt content and manifest entries) to the equivalent low-level invocation with pre-computed paths — side-by-side bats fixture asserts byte-equality of the resulting prompt (CD-2 Acceptance bullet 2 — paired with the T03 byte-identical expectation).
  - High-level mode threads `diff_file_path:` and `absorption_map_path:` (when applicable) into the dispatch prompt; a Design-step fixture proves both parameters appear, a Goals-step fixture proves only `diff_file_path:` appears.
  - review-prep failure causes dispatch-agent to exit non-zero with review-prep's stderr verbatim (CD-2 § Why this approach — single-exit-code shape).
  - A production-default high-level invocation against an artifact-dir not in a git repo halts non-zero with review-prep's `review-prep-no-diff-source:` named diagnostic on stderr — dispatch-agent does NOT silently proceed with a missing diff path (silent-claude R2-F01 paired-coverage assertion with T03).
  - The low-level `--diff-file <path>` mode remains functional against a fixture (regression guard for tests and non-standard callers).

### T04b: Add subagent author-marker env wrap to scripts/dispatch-agent.sh
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/dispatch-agent.sh` (Modify), `tests/unit/test-dispatch-agent-author-marker.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~50
- **cross_task_consumers:**
  - `skills/integrate/SKILL.md` (T21), `skills/test/SKILL.md` (T22) — disposition: `pass-through` (T21/T22 depend on the subagent author-marker behaviour to make G5's boundary check meaningful, but neither edits scripts/dispatch-agent.sh).
  - `scripts/orchestration-boundary-check.sh` (T19) — disposition: `pass-through` (T19's author-marker filter consumes the marker scheme this task installs; T19 does not edit this script).
- **Description:** Every dispatched subagent git command is wrapped with the subagent author-marker scheme so subagent commits carry the marker the G5 boundary check filters on. The `<agent>` interpolation is validated against the valid agent-name charset (lowercase letters, digits, hyphen) before being injected into the `GIT_AUTHOR_NAME` environment variable; an `<agent>` string failing the charset check halts dispatch with a named diagnostic and exits non-zero. The author-marker scheme is the literal Implement-layer chooses; Plan commits the behavioural shape (the marker prefix is `qrspi-`, the agent-name field is validated charset-safe before injection, the wrap is set on every dispatched git command not just the first one).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Subagent git commits in a synthetic fixture round carry the `qrspi-<agent>` author marker in `git log --format='%an'` (G5 Acceptance bullet 5).
  - An `<agent>` value containing characters outside the valid agent-name charset (e.g., a space, a control byte, a path separator) halts dispatch with a named diagnostic and exits non-zero before any git command runs (no silently-malformed marker).
  - The marker is set on every dispatched git command in the subagent's session, not just the first — proven by a fixture round with multiple commits.
  - The low-level (non-high-level) dispatch path is also wrapped (regression guard — the marker is a G5 invariant independent of CD-2 high-level mode).

### T05: Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs
- **Phase:** 1
- **Goal IDs:** [CD-2, G9]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/goals/SKILL.md` (Modify), `skills/questions/SKILL.md` (Modify), `skills/research/SKILL.md` (Modify), `skills/design/SKILL.md` (Modify), `skills/phasing/SKILL.md` (Modify), `skills/structure/SKILL.md` (Modify), `skills/parallelize/SKILL.md` (Modify), `skills/replan/SKILL.md` (Modify), `scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh` (Create — schema-migration structural-lint script)
- **Dependencies:** T04a
- **LOC estimate:** ungated (schema-migration N-files trio applies — see Sizing exception below)
- **Sizing exception:** schema-migration
- **Sizing rationale:** Single repeated edit shape across the eight artifact-step SKILL bodies — each file has its pre-dispatch Bash diff-redirect paragraph replaced with one `dispatch-agent.sh` invocation. Per-line review burden collapses to "is the documented removal pattern matched and is the dispatch invocation correctly shaped?" — the structural-lint script proves both.
- **Structural lint:** scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh
- **cross_task_consumers:**
  - `tests/lint/test-no-diff-redirect-prose.bats` (T06) — disposition: `pass-through` (T06 lints the post-T05 SKILL tree for zero remaining diff-redirect paragraphs; no edit to this task's deliverables required).
- **dependent_tests:**
  - `tests/unit/test-diff-file-emission.bats` — currently asserts every in-scope per-step SKILL.md references `round-NN.diff`; that assertion breaks for the eight files T05 modifies — `co-edit` to update the assertion shape so it asserts the absence of the `round-NN.diff` redirect pattern in the eight artifact-step skills and presence of the dispatch-agent high-level invocation instead.
- **Description:** Each of the eight artifact-step SKILL.md files has its § Review Round section's pre-dispatch Bash diff-redirect paragraph replaced with one `dispatch-agent.sh --step <step> --round NN --artifact-dir <ABS>` invocation. The replacement prose carries the high-level invocation only — no per-step Bash redirect block, no pre-step instruction the orchestrator can skip. The replacement is mechanical: the structural-lint script proves the diff is only documented-removal patterns plus the dispatch invocation addition. R1 (anchor-phrase preservation for the surrounding "Run the Review Round" prose), R3 (load-bearing dispatch invocation at end of section), R7 (preserve the existing anchor phrases the reviewer dispatch test depends on), and R8 (prose-density tightening of the replacement paragraph) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Review Round prose; R2 — the replacement paragraph is self-contained, carrying only the high-level dispatch invocation; R3 — load-bearing dispatch call at the end of the section; R7 — the dispatch invocation phrasing the T06 lint and the dispatch-agent high-level mode in T04a depend on; R8 — prose-density tightening of the replacement paragraph.
  - Pre-dispatch Bash diff-redirect prose shrinkage across the eight artifact-step SKILLs totals ≥ 80 lines removed versus the v0.7.2 baseline (~≥ 10 lines per file × 8 files) — CD-2 Acceptance bullet 4 quantitative claim, lifted verbatim from design.md.
  - The structural-lint script (`scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh`) passes against the sweep PR's diff and fails against a fixture diff that includes a non-mechanical edit (e.g., a body content change in the same hunk).
  - Zero `git diff > round-NN.diff` Bash redirect blocks remain in any of the 8 modified files (verified by the T06 lint).

### T06: Create tests/lint/test-no-diff-redirect-prose.bats
- **Phase:** 1
- **Goal IDs:** [CD-2, G9]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/lint/test-no-diff-redirect-prose.bats` (Create)
- **Dependencies:** T05
- **LOC estimate:** ~25
- **Description:** A grep audit asserts zero `git diff > round-NN.diff` Bash redirect blocks remain in the eight artifact-step SKILL.md files after T05's pass. The lint runs in CI on every PR and prevents reintroduction of the per-step diff-emission prose pattern CD-2 retires.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - "Skill-body prose audit: zero `git diff > round-NN.diff` Bash redirect blocks remain in `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md`" (CD-2 Acceptance bullet 3, verbatim).
  - The lint fails against a fixture skill body that re-introduces the redirect pattern (fail-direction guard).
  - The lint's pattern is scoped to the eight artifact-step skills only — a benign occurrence of the literal string in an unrelated skill body or test fixture does not trigger a false positive.

### T07: Insert R8 prose-density rule in skills/_shared/prompt-design-rules.md
- **Phase:** 1
- **Goal IDs:** [CD-3]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/_shared/prompt-design-rules.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~90
- **cross_task_consumers:**
  - `tests/lint/test-prompt-design-rules-r8.bats` (T08) — disposition: `pass-through` (T08 anchor-phrase grep verifies the post-T07 prose state; no edit to this task's deliverables required).
  - `skills/using-qrspi/SKILL.md` (T32), `skills/implement/SKILL.md` (T33), `skills/plan/SKILL.md` (T34), the 8 artifact-step SKILLs (T35), the 7 cross-cutting SKILLs (T36) — disposition: `pass-through` (each trim task applies the R8 reviewer test to its tightened prose; none edits prompt-design-rules.md).
- **Description:** A new `### R8 — Prose density: short declarative sentences, full behavioral precision` section is inserted between R7 and the cross-cutting-principles `---` separator. The section carries the tightening-pattern table header `| Pattern in current prose | Tightened form | Why it works |`, the `What NOT to tighten` subheading, the reviewer-test sentence "Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?", and the "minimal does NOT mean short" guardrail tying R8 to the existing cross-cutting principles. The finding-type gate `rule-violation` row updates its citation to `R1-R8`. R1 (anchor-phrase preservation for the heading), R2 (the new section is self-contained — no cross-rule references that bury the rule), R3 (R8 lands at the end of the R-rule list, the load-bearing position before the cross-cutting principles), R7 (verbatim phrasing of the new anchor phrases the T08 lint depends on), and R8 itself (the new rule, applied to its own prose) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — heading `### R8 — Prose density: short declarative sentences, full behavioral precision` present verbatim; R2 — the R8 section is self-contained, no cross-rule external references; R3 — R8 lands at the load-bearing end-position of the R-rule list, before the cross-cutting principles `---` separator; R7 — all anchor phrases (table header, `What NOT to tighten` subheading, reviewer-test sentence) are exact and match the T08 lint's grep expectations; R8 — applied to the new section's own prose; finding-type gate `rule-violation` row cites `R1-R8` as a literal substring.

### T08: Create tests/lint/test-prompt-design-rules-r8.bats
- **Phase:** 1
- **Goal IDs:** [CD-3]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/lint/test-prompt-design-rules-r8.bats` (Create)
- **Dependencies:** T07
- **LOC estimate:** ~35
- **Description:** An anchor-phrase grep test asserts the R8 section is present and exact in `skills/_shared/prompt-design-rules.md`: the heading `### R8 — Prose density: short declarative sentences, full behavioral precision`, the tightening-pattern table header `| Pattern in current prose | Tightened form | Why it works |`, the `What NOT to tighten` subheading, the reviewer-test sentence, the literal `R1-R8` substring in the finding-type gate `rule-violation` row, no duplicated R-rule headings (R1–R8 each appear exactly once), and every R-ID cited in the finding-type gate exists as a heading.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The R8 heading is present verbatim (CD-3 Acceptance bullet 1, first sub-clause).
  - The tightening-pattern table header is present verbatim (CD-3 Acceptance bullet 1, second sub-clause).
  - The `What NOT to tighten` subheading is present verbatim (CD-3 Acceptance bullet 1, third sub-clause).
  - The reviewer-test sentence is present exact (CD-3 Acceptance bullet 1, fourth sub-clause).
  - The `rule-violation` row of the finding-type gate cites the literal substring `R1-R8` (CD-3 Acceptance bullet 2).
  - No R-rule heading is duplicated and every R-ID cited in the finding-type gate exists as a section heading (CD-3 Acceptance bullet 4).
  - A fixture file with a duplicated R3 heading fails the lint (fail-direction guard).

### T09: Append ID-hygiene rubric clause to agents/qrspi-finding-verifier.md
- **Phase:** 1
- **Goal IDs:** [G1]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `agents/qrspi-finding-verifier.md` (Modify)
- **Dependencies:** T01
- **LOC estimate:** ~20
- **cross_task_consumers:**
  - `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (T10) — disposition: `pass-through` (T10 drives a synthetic verifier dispatch against the post-T09 rubric and asserts the rubric clause grounds findings in `skills/implementer-protocol/SKILL.md` § Hygiene contract; no edit to this task's deliverables required).
- **Description:** A new rubric clause is appended to `agents/qrspi-finding-verifier.md` § Rubric directing the verifier to ground findings whose subject is an identifier-hygiene token (forbidden-token-table match) in `skills/implementer-protocol/SKILL.md` § Hygiene contract via `<upstream_paths>` Read. The clause treats absence of the path from `<upstream_paths>` as a dispatch defect with no improvised fallback, and names both forbidden-token tables (Internal-ID, Evergreen-markdown) as load-bearing. The clause is the verbatim prose-design block from design.md G1 § Solution change 1. R1 (the clause is a new section appended to § Rubric — anchor-phrase preservation for the existing rubric headings), R2 (self-contained — no cross-document references the verifier would have to chase), R3 (the clause lands at the end of § Rubric, the load-bearing position), R7 (verbatim phrasing the T10 fixture asserts), and R8 (prose-density tightening applied to the clause itself) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the existing § Rubric headings; R2 — the new clause is self-contained, references `skills/implementer-protocol/SKILL.md` § Hygiene contract by exact path and section name; R3 — the new clause lands at the end of § Rubric, the load-bearing position; R7 — verbatim phrasing of the design.md G1 § Solution change 1 prose-design block (the T10 fixture grep depends on the literal phrasing); R8 — prose-density tightening of the new clause; the clause names both forbidden-token tables (Internal-ID, Evergreen-markdown) as load-bearing.

### T10: Create tests/unit/test-finding-verifier-id-hygiene-grounding.bats
- **Phase:** 1
- **Goal IDs:** [G1]
- **task_type:** tdd
- **tier:** high
- **Target files:** `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (Create)
- **Dependencies:** T09, T01
- **LOC estimate:** ~70
- **Description:** A bats test drives a synthetic verifier dispatch against a fixture finding whose subject is a `[Tnn]` token in a bats test name; the test inspects the resulting sidecar and asserts the score is ≥ 70 against the post-T09 rubric. A regression-direction sub-test drives the same fixture finding against a v0.7.2-baseline rubric stub (one that lacks the T09 clause) and asserts the score is < 70 — proving G1 actually moves the score across the correctness floor.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic verifier dispatch on a `[Tnn]` fixture finding "scores ≥ 70" against `skills/implementer-protocol/SKILL.md` § Hygiene contract via the post-T09 rubric (G1 Acceptance bullet 3).
  - The same fixture finding "scored under the v0.7.2 verifier scores < 70" — regression-direction guard against a v0.7.2-baseline rubric stub (G1 Acceptance bullet 4).
  - The fixture finding's grounding section in the sidecar names `skills/implementer-protocol/SKILL.md` § Hygiene contract as the authority cited (not `CONTRIBUTING.md`, not improvised).
  - The fixture forbidden token is carried via an inline `# bats lint:no-id-hygiene` carve-out marker so T12's permanent lint does not false-positive against this test's own fixture string.

### T11: Sweep [Tnn] and forbidden-finding-ID tokens from @test descriptions across the bats corpus
- **Phase:** 1
- **Goal IDs:** [G2]
- **task_type:** tdd
- **tier:** medium
- **Target files:** Every `.bats` file under `tests/acceptance/`, `tests/acceptance/v07-phase1/`, `tests/integration/`, `tests/lint/`, and `tests/unit/` (Modify — release-wide mechanical sweep; the enumerated set at sweep time is the output of `find tests/ -name '*.bats'` against the repo HEAD at implement-start, which currently surfaces 115 bats files across the four directories). `scripts/structural-lints/check-bats-id-hygiene-sweep.sh` (Create — the structural-lint script that enforces the mechanical-only diff shape).
- **Dependencies:** T09
- **LOC estimate:** ungated (schema-migration N-files trio applies — see Sizing exception below)
- **Sizing exception:** schema-migration
- **Sizing rationale:** Single mechanical sweep across the bats corpus strips token patterns from `@test "..."` description strings only; per-instance review is structurally impossible and unnecessary because the diff is mechanically generated by a single regex.
- **Structural lint:** scripts/structural-lints/check-bats-id-hygiene-sweep.sh
- **dependent_tests:** none
  - **Search proof:** `grep -rn -- '@test "[^"]*\[F[0-9]+' tests/`
  - The proof pattern matches `@test` lines that reference a forbidden finding-ID token of the form `[F<digits>]` inside the description. A zero-match result demonstrates no consuming test file under `tests/` asserts on a forbidden finding-ID description as its own behavioural-claim subject — i.e., no consumer test breaks when the sweep strips such tokens. The reviewer re-runs the command from the repo root and treats any non-zero hit as a contract defect requiring the field to be re-shaped to a path list with per-file dispositions. (Note: the Phase-1 acceptance criterion's separate grep `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` audits the sweep's own subject and is expected to return zero matches AFTER the sweep applies — that is the sweep's load-bearing output, not its consumer-detection probe.)
- **Description:** A single mechanical sweep across the enumerated `.bats` files strips the leading/trailing forbidden token patterns from inside `@test "..."` description strings only; body content (test logic, assertions, fixtures) is untouched. The sweep is shaped so the raw zero-match grep at the Phase-1 acceptance criterion passes WITHOUT any `@test`-description carve-out: any intentional `[Tnn]` token a test legitimately needs to exercise lives in the **test body** (where it is emitted to a generated fixture file under `tests/fixtures/`) or in a pre-generated fixture file under `tests/fixtures/`, never in an `@test "..."` description string. The inline `# bats lint:no-id-hygiene` carve-out marker applies only to fixture-construction body lines that emit a forbidden token to a fixture file — never to an `@test "..."` description. Sequencing after T09 ensures the v0.7.3 self-host's own reviewers do not false-negative the sweep findings.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - After the sweep PR, `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` returns zero matches (G2 Acceptance bullet 1, verbatim) — and the zero-match holds without any `@test`-description carve-out exemption.
  - The mechanical-check structural-lint script passes against the sweep PR's diff and fails against a fixture diff that includes a non-mechanical edit (e.g., a body-content change in the same hunk).
  - Body content (the lines between `@test "..."` and the next `}`) is byte-identical pre- and post-sweep for every modified test (per-file diff guard).
  - Tests that intentionally exercise forbidden tokens (e.g., T14's fail-direction fixture, T10's verifier fixture) emit those tokens to fixture files under `tests/fixtures/` from a test-body emit step carrying the body-line carve-out marker, never inline them into `@test "..."` descriptions, and survive the sweep unchanged.

### T12: Create tests/lint/test-bats-test-name-id-hygiene.bats permanent CI lint
- **Phase:** 1
- **Goal IDs:** [G2]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `tests/lint/test-bats-test-name-id-hygiene.bats` (Create)
- **Dependencies:** T11
- **LOC estimate:** ~50
- **Description:** A permanent CI lint greps every `@test` line under `tests/**/*.bats` and fails when a description matches a forbidden internal-ID token (`[Tnn]` or sub-task suffix shape) or a forbidden finding-ID token. Failure output lists offending `file:line` locations and the offending strings (the documented diagnostic shape). The carve-out marker `# bats lint:no-id-hygiene` is honoured only on fixture-construction body lines inside a test body that emit a forbidden token to a generated fixture file under `tests/fixtures/`; the lint does NOT exempt `@test "..."` description strings on the basis of an adjacent carve-out marker (the G2 acceptance grep must pass without `@test`-description carve-out exemption). The lint runs in CI on every PR; reintroduction of the swept tokens into an `@test "..."` description is mechanically impossible to land.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The lint exists and passes on the post-sweep clean tree (G2 Acceptance bullet 3, first half).
  - The lint fails (with the documented diagnostic shape) against a fixture file under `tests/fixtures/` that carries a forbidden internal-ID token inside an `@test "..."` description string (G2 Acceptance bullet 3, second half) — the fail-direction is exercised by T14.
  - The carve-out marker `# bats lint:no-id-hygiene` on a fixture-construction body line inside a test body exempts that body line from the lint match.
  - An `@test "..."` description string containing a forbidden token is NOT exempted by an adjacent carve-out marker — the `@test`-description rule has no carve-out.
  - The lint's failure output lists `file:line` locations and the offending strings (named-diagnostic discipline; no silent fail).

### T13a: Promote implementer-protocol Pre-DONE self-check to blocking
- **Phase:** 1
- **Goal IDs:** [G2]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/implementer-protocol/SKILL.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~20
- **Description:** One anchor sentence is added to `skills/implementer-protocol/SKILL.md` § Pre-DONE self-check (combined hygiene scan) promoting the existing self-check from advisory to halt-DONE: any ID-hygiene match in added or modified `@test "..."` description strings halts the DONE signal, requiring the implementer to fix the violation before reporting complete. R1 (anchor-phrase preservation for the surrounding § Pre-DONE self-check section), R3 (the new blocking sentence lands at the end of the existing self-check paragraph, the load-bearing position), R7 (verbatim phrasing the T12 lint and downstream reviewer agents rely on), and R8 (prose-density tightening of the new sentence) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Pre-DONE self-check section; R2 — the new sentence is self-contained, naming the scope (`@test "..."` description strings) and the halt direction inline; R3 — promotion-to-blocking sentence lands at the end of the self-check paragraph, the load-bearing position; R7 — verbatim phrasing the T12 lint and the downstream Pre-DONE-aware reviewer agents depend on; R8 — prose-density tightening of the new sentence.

### T13b: Add revert-orchestration-drift fix-task mode to implementer-protocol with halt-on-conflict
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/implementer-protocol/SKILL.md` (Modify)
- **Dependencies:** T19
- **LOC estimate:** ~25
- **Description:** A new `revert-orchestration-drift` fix-task mode is added to `skills/implementer-protocol/SKILL.md` § Fix-task modes. The mode consumes the G5 boundary violation report (`reviews/<phase>/orchestration-boundary.md`) and reverts each non-subagent commit it names in reverse chronological order under the subagent's author marker. Every SHA read from the report is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) before being passed to any `git` invocation; a SHA failing the shape check halts the subagent with a `sha-format-invalid:` named diagnostic and exits non-zero. The mode is halt-on-conflict: if any `git revert --no-edit <SHA>` fails (merge conflict, merge-commit-without-`-m`, deleted file, or any other failure class), the subagent halts immediately, runs `git revert --abort` to leave the working tree clean of partial revert state, writes `orchestration-boundary-revert-failed.md` naming the failed SHA and the failure class, leaves no other state changes, and exits non-zero. Skip-and-continue across remaining SHAs is forbidden. On full success, the subagent writes `orchestration-boundary-revert.md` summarising the reverts. R1 (anchor-phrase preservation for the surrounding § Fix-task modes section), R3 (the new mode lands at the end of § Fix-task modes, the load-bearing position), R7 (verbatim phrasing the G5 boundary report's consumer expects), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Fix-task modes; R2 — the new mode is self-contained, names the report path, the halt-on-conflict semantics, and the per-failure-class halt direction inline; R3 — load-bearing position at the end of § Fix-task modes; R7 — verbatim phrasing the G5 boundary report's consumer surface depends on; R8 — prose-density tightening.
  - Every SHA the mode reads from the boundary report is validated against the well-formed git object-name shape before any `git` invocation; a malformed SHA triggers the `sha-format-invalid:` named diagnostic and a non-zero exit, with no `git` command run against the malformed value.
  - A single revert failure (conflict, merge-without-`-m`, deleted file) halts the mode immediately, leaves the working tree clean of partial revert state (the `git revert --abort` cleanup step ran), writes `orchestration-boundary-revert-failed.md` naming the failed SHA and the failure class, and exits non-zero.
  - Skip-and-continue across remaining SHAs after a failure is absent from the prose (a reviewer grep verifies the mode does NOT contain any "continue", "skip", or "next SHA" branch after a revert failure).

### T14: Create tests/unit/test-id-hygiene-lint-fail-direction.bats
- **Phase:** 1
- **Goal IDs:** [G2]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/unit/test-id-hygiene-lint-fail-direction.bats` (Create), `tests/fixtures/id-hygiene/bad-test-name.bats.fixture` (Create — a generated fixture file containing the forbidden internal-ID token under `tests/fixtures/`, not under `tests/**/*.bats`, so the permanent CI lint never sees it as an `@test` line)
- **Dependencies:** T12
- **LOC estimate:** ~30
- **Description:** A fail-direction fixture test drives the T12 lint against a generated fixture file under `tests/fixtures/id-hygiene/` containing a forbidden internal-ID token inside an `@test "..."` description string, and asserts non-zero exit with the documented diagnostic shape (`file:line` location and the offending string in the failure output). The fixture file lives under `tests/fixtures/` (NOT `tests/**/*.bats`) so the permanent CI lint never sees it as a real `@test` line; the test body emits or maintains the fixture content with a body-line carve-out marker on the emit step. The test's own `@test "..."` descriptions contain zero forbidden tokens — the fail-direction proof is in driving the lint against the fixture file, not in including the token in this test's own description.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A regression PR (synthetic) that adds a forbidden internal-ID token to a real test name is rejected at CI by the lint — exercised against the fixture file under `tests/fixtures/id-hygiene/` (G2 Acceptance bullet 4).
  - The lint's failure output for the fixture lists the fixture file path and line number with the offending string (named-diagnostic guard).
  - This test's own `@test "..."` description strings contain zero forbidden tokens (the fixture file under `tests/fixtures/` is the carrier, not this test's descriptions).


### T15: Add pre-fanout absorption-map anchor sentence to skills/plan/SKILL.md
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/plan/SKILL.md` (Modify)
- **Dependencies:** T02
- **LOC estimate:** ~15
- **cross_task_consumers:**
  - `agents/qrspi-plan-spec-reviewer.md`, `agents/qrspi-design-reviewer.md` (T16) — disposition: `pass-through` (T16 adds rubric clauses that depend on the verbatim anchor phrasing this task installs; the reviewer bodies are edited by T16, not this task).
  - `tests/unit/test-plan-spec-reviewer-absorption.bats` (T17a) — disposition: `pass-through` (the T17a plan-spec-reviewer fixture asserts against the verbatim phrasing this task installs; no edit to this task's deliverables required).
  - `skills/plan/SKILL.md` (T34) — disposition: `pass-through` (the T34 trim preserves the anchor sentence this task adds — anchor-phrase preservation is part of T34's specific findings to verify).
- **Description:** A verbatim anchor sentence is added to `skills/plan/SKILL.md` directing the plan-author to run `scripts/design-absorption-markers.sh` against `design.md` before fan-out, ingest the resulting redirect map, refuse to author standalone tasks for absorbed goal IDs, and halt with BLOCKED rather than manufacture a task home for residual work under an absorbed/moot/deferred goal. R1 (anchor-phrase preservation for the surrounding § Pre-fanout section), R2 (the sentence is self-contained — names the script and the BLOCKED halt without external cross-references), R3 (the sentence lands at the start of the pre-fanout step list, the load-bearing position for a gate directive), R7 (verbatim phrasing the T16 reviewer clauses and T17a plan-spec-reviewer fixture assert), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Pre-fanout section; R2 — the anchor sentence is self-contained, names the script, the redirect-map consumption step, and the BLOCKED halt inline; R3 — the sentence lands at the start of the pre-fanout step list, the load-bearing position for a gate directive; R7 — verbatim phrasing the T16 plan-spec reviewer clause and the T17 plan-spec fixture depend on; R8 — prose-density tightening of the anchor sentence.

### T16: Append G3 rubric clauses to plan-spec and design reviewer agent bodies (including absorption_map_path dispatch-defect contract for Plan and Design)
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `agents/qrspi-plan-spec-reviewer.md` (Modify), `agents/qrspi-design-reviewer.md` (Modify)
- **Dependencies:** T02
- **LOC estimate:** ~50
- **cross_task_consumers:**
  - `tests/unit/test-plan-spec-reviewer-absorption.bats` (T17a), `tests/unit/test-design-reviewer-fidelity.bats` (T17b), `tests/unit/test-design-reviewer-dispatch-defect.bats` (T17c) — disposition: `pass-through` (each fixture asserts the verbatim rubric clauses this task installs; no edit to this task's deliverables required).
- **Description:** Two coordinated rubric-clause appendments. The plan-spec reviewer body gains (a) a clause asserting no plan task carries an absorbed-goal ID (per the redirect map produced by `scripts/design-absorption-markers.sh`); a violation surfaces as a `change_type: scope` finding — and (b) a dispatch-defect contract clause: at the Plan step, an absent `absorption_map_path:` parameter is a dispatch defect; the reviewer halts with a `dispatch-defect:` named diagnostic and exits non-zero rather than silently proceeding with an empty absorbed-ID set (which would silently produce zero absorption findings and false-satisfy the G3 acceptance — silent-claude R2-F02 fail-loud direction). The design reviewer body gains (a) a fidelity-check clause asserting every absorption marker in `design.md` preserves authorial intent — a marker that contradicts its goal block's body (intent/marker contradiction) surfaces as a fidelity-mismatch finding — and (b) the same dispatch-defect contract clause at the Design step: an absent `absorption_map_path:` parameter is a dispatch defect; the reviewer halts with a `dispatch-defect:` named diagnostic and exits non-zero. The `absorption_map_path:` parameter is mandatory at exactly two steps — Plan and Design — and is optional only at goals/research/phasing/structure/parallelize steps, where the design absorption map has no applicable role. R1 (anchor-phrase preservation for both agents' § Rubric headings), R2 (self-contained clauses), R3 (each clause lands at the end of its agent's § Rubric, the load-bearing position), R7 (verbatim phrasing the T17a/T17b/T17c bats fixtures assert), and R8 (prose-density tightening) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for both agents' § Rubric headings; R2 — every new clause is self-contained, naming the redirect-map source, the `change_type`, the fidelity-mismatch direction, and the dispatch-defect halt direction inline; R3 — each clause lands at the end of its agent's § Rubric; R7 — verbatim phrasing the T17a/T17b/T17c bats fixtures assert against; R8 — prose-density tightening.
  - The plan-spec reviewer's dispatch-defect clause names absent `absorption_map_path:` at the Plan step as a dispatch defect (`dispatch-defect:` diagnostic, non-zero exit) — the plan-spec reviewer does not proceed with an empty absorbed-ID set.
  - The design reviewer's dispatch-defect clause names absent `absorption_map_path:` at the Design step as a dispatch defect (`dispatch-defect:` diagnostic, non-zero exit), and names goals/research/phasing/structure/parallelize as the only steps where the parameter is optional.

### T17a: Create tests/unit/test-plan-spec-reviewer-absorption.bats
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `tests/unit/test-plan-spec-reviewer-absorption.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~30
- **Description:** A synthetic-dispatch bats test verifies the T16 plan-spec rubric clause fires on real findings. The test drafts a fixture `plan.md` with a task labeled with an absorbed goal ID (per a fixture absorption-map produced by T02's script) and asserts the plan-spec reviewer produces a `change_type: scope` finding. The test also invokes the Plan-step plan-spec-reviewer dispatch with the `absorption_map_path:` parameter absent and asserts the reviewer halts non-zero with the `dispatch-defect:` named diagnostic instead of silently proceeding with an empty absorbed-ID set (silent-claude R2-F02 fail-loud direction at the Plan step).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic plan.md drafted with an absorbed-ID task produces a `change_type: scope` finding from the plan-spec reviewer (G3 Acceptance bullet 4, second half).
  - A clean plan.md fixture (no absorbed-ID tasks) produces zero absorption findings (no-false-positive guard).
  - A Plan-step plan-spec-reviewer dispatch with `absorption_map_path:` absent halts the reviewer with a `dispatch-defect:` named diagnostic and non-zero exit — the reviewer does not silently produce a zero-finding pass (silent-claude R2-F02 fail-loud direction).

### T17b: Create tests/unit/test-design-reviewer-fidelity.bats
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/unit/test-design-reviewer-fidelity.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~25
- **Description:** A synthetic-dispatch bats test verifies the T16 design-reviewer fidelity rubric clause fires on real findings. The test drafts a fixture `design.md` where a goal block's body describes independent scope but the heading suffix claims the goal is absorbed by another CD (intent/marker contradiction), and asserts the design reviewer produces a fidelity-mismatch finding.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic design.md with an intent/marker contradiction produces a fidelity-mismatch finding from the design reviewer (G3 Acceptance bullet 5, second half).
  - A clean design.md fixture (markers consistent with goal-block bodies) produces zero fidelity-mismatch findings (no-false-positive guard).

### T17c: Create tests/unit/test-design-reviewer-dispatch-defect.bats
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/unit/test-design-reviewer-dispatch-defect.bats` (Create)
- **Dependencies:** T16, T02
- **LOC estimate:** ~25
- **Description:** A synthetic-dispatch bats test verifies the T16 design-reviewer dispatch-defect contract clause fires on real findings. The test invokes the Design-step reviewer dispatch with the `absorption_map_path:` parameter absent and asserts the reviewer halts non-zero with the `dispatch-defect:` named diagnostic instead of silently no-op'ing.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A Design-step dispatch with `absorption_map_path:` absent halts the design reviewer with a `dispatch-defect:` named diagnostic and non-zero exit (silent-claude F01 dispatch-defect fail-loud direction).
  - A goals/research/phasing/structure/parallelize-step dispatch with `absorption_map_path:` absent proceeds normally (no false positive for steps where the parameter has no applicable role).

### T18: Create tests/lint/test-design-absorption-marker-set.bats structural lint
- **Phase:** 1
- **Goal IDs:** [G3]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/lint/test-design-absorption-marker-set.bats` (Create)
- **Dependencies:** T02
- **LOC estimate:** ~30
- **Description:** A structural lint scans every `design.md` under `docs/qrspi/**/` and asserts any absorption-shaped marker text matches one of the 4 enumerated patterns (heading-suffix, block-internal explicit non-goal, acceptance-criterion no-separate-task, free-prose deferred-to). Drift surfaces as a lint failure on the design.md PR. The lint runs in CI on every PR; new absorption marker forms cannot land without a paired design-decision update to the enumerated set.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The lint "passes against the v0.7.3 design.md (this very document — meta-acceptance)" (G3 Acceptance bullet 2, first half).
  - The lint "fails against a fixture design.md containing a non-enumerated marker form" (G3 Acceptance bullet 2, second half).
  - The lint's failure output names the offending file, line, and the non-enumerated marker text (named-diagnostic discipline).
  - A design.md with zero absorption markers passes the lint silently.

### T19: Create scripts/orchestration-boundary-check.sh with per-phase phase-base dispatch, SHA-format validation, dispatch-defects section, and bats unit test
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/orchestration-boundary-check.sh` (Create), `tests/unit/test-orchestration-boundary-check.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~180 (sizing_exception: ci-scaffolding — full per-phase coverage matrix plus author-marker filter plus allowlisted-path exclusion plus dispatch-defects partition)
- **cross_task_consumers:**
  - `skills/implement/SKILL.md` (T20b) — disposition: `pass-through` (T20b's autopilot reads the `## Dispatch defects` section to decide the unconditional halt branch; the script contract this task defines is what T20b's prose calls).
  - `skills/integrate/SKILL.md` (T21) — disposition: `pass-through` (T21 invokes the script as the integrate-phase Step-N OBC call; T21 also writes the `reviews/integration/phase-base.txt` this script reads — the read-side contract is stable).
  - `skills/test/SKILL.md` (T22) — disposition: `pass-through` (T22 invokes the script as the test-phase Step-N OBC call; T22 also writes the `reviews/test/phase-base.txt` this script reads — the read-side contract is stable).
  - `skills/implementer-protocol/SKILL.md` (T13b) — disposition: `pass-through` (the T13b revert-orchestration-drift fix-task mode consumes the `reviews/<phase>/orchestration-boundary.md` violation report this script writes; the report shape this task defines is what T13b reads).
  - `tests/lint/test-integrate-test-skill-phase-base-write.bats` (T24) — disposition: `pass-through` (T24 locks the SKILL prose against drift that would break this script's read paths; no edit to this task's deliverables required).
- **Description:** A phase-end script accepts `--phase <implement|integration|test> --artifact-dir <path>` and writes a violation report to `<artifact-dir>/reviews/<phase>/orchestration-boundary.md`. The script runs `git status --porcelain` (with the `reviews/` tree excluded — those paths are allowlisted bookkeeping) and `git log <phase-base>..HEAD --format='%H %an'` post-filtered for commits whose author does NOT carry the subagent author marker (the OBC author-marker filter). The author-marker filter is fail-loud: any author-name value containing a newline, multiple whitespace characters, or other awk-record-breaking bytes triggers the `obc-author-name-malformed:` named diagnostic and surfaces as a violation entry under the `## Dispatch defects` section — not silently excluded. Phase-base resolution is per-phase: `implement` reads the G6 wave-1 sidecar at `reviews/implement/wave-state/`; `integration` reads `reviews/integration/phase-base.txt`; `test` reads `reviews/test/phase-base.txt`. Every SHA read from disk (from either the sidecar or the phase-base.txt file) is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE being passed to any `git` invocation; a malformed SHA triggers a `sha-format-invalid:` named diagnostic, exits non-zero, and writes a violation entry under `## Dispatch defects`. Missing or malformed `phase-base.txt` (integration/test phases) is itself a dispatch defect — the script writes a violation entry under a distinct `## Dispatch defects` section of the report and exits non-zero with `phase-base-missing:` or `phase-base-malformed:` named diagnostics. Missing or malformed wave-1 sidecar (implement phase) is symmetrically a dispatch defect — the script writes a violation entry under `## Dispatch defects` with the `wave-1-sidecar-missing:` or `wave-1-sidecar-malformed:` named diagnostics and exits non-zero (silent-claude R2-F03 symmetrization direction — implement phase wave-1 sidecar is treated identically to integration/test phase-base.txt). The script exits 0 fail-soft only when the report contains zero dispatch-defect entries — commit and workspace entries remain fail-soft because the batch gate inspects the report.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The script accepts `--phase` + `--artifact-dir`, writes the report; exits 0 on clean trees and on dirty trees that carry only commit or workspace entries (fail-soft); exits non-zero when any `## Dispatch defects` entry is present (G5 Acceptance bullet 4, first half).
  - A clean integration branch (zero non-subagent commits, zero uncommitted edits outside `reviews/`, zero dispatch defects) produces an empty report.
  - One non-subagent commit in the phase range produces one entry in the report naming the commit SHA, author, and subject under the existing commit-violations section.
  - An uncommitted-edit workspace produces an entry in the report under the existing workspace-violations section.
  - Uncommitted files under the `reviews/` tree are excluded from the uncommitted count (allowlisted bookkeeping).
  - For `--phase implement`, the script reads phase-base from the G6 wave-1 sidecar under `reviews/implement/wave-state/`; for `--phase integration` or `--phase test`, the script reads `reviews/<phase>/phase-base.txt`.
  - A SHA read from disk that fails the well-formed git object-name shape (e.g., uppercase hex, length outside 7–64, non-hex characters) triggers the `sha-format-invalid:` named diagnostic, writes a violation entry under `## Dispatch defects`, and exits non-zero — no `git` command runs against the malformed value.
  - Missing or malformed `phase-base.txt` writes a violation entry under a distinct `## Dispatch defects` section of the report and exits non-zero with `phase-base-missing:` or `phase-base-malformed:` named diagnostics (silent-claude F02 dispatch-defect direction).
  - For `--phase implement`, a missing or malformed wave-1 sidecar at `reviews/implement/wave-state/` writes a violation entry under `## Dispatch defects` with the `wave-1-sidecar-missing:` or `wave-1-sidecar-malformed:` named diagnostic and exits non-zero — symmetric with the integration/test `phase-base.txt` dispatch-defect direction (silent-claude R2-F03 symmetrization).
  - An author-name value containing a newline, multiple whitespace characters, or other awk-record-breaking bytes triggers the `obc-author-name-malformed:` named diagnostic and writes a violation entry under `## Dispatch defects` — not silently excluded from the filter (security-claude F02 OBC fail-loud direction; coverage-claude F02 — newline, multi-whitespace, and control-byte (`\x00`–`\x1F` excluding TAB/LF) inputs each produce the named diagnostic explicitly).

### T20a: Wrap Wave Dispatch git merge --no-ff with stage-commit parent validation in skills/implement/SKILL.md
- **Phase:** 1
- **Goal IDs:** [G6]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/implement/SKILL.md` (Modify)
- **Dependencies:** T25
- **LOC estimate:** ~40
- **Description:** `skills/implement/SKILL.md` § Wave Dispatch step 6 (the `git merge --no-ff` step) gains pre-merge `--capture` and post-merge `--validate` calls to `scripts/validate-stage-commit-parents.sh` wrapping the existing merge invocation. The wrap is the load-bearing seam: the `--capture` call records the expected parent SHA before the merge, the `--validate` call confirms the resulting merge commit's parent matches, and any mismatch halts the wave with a named diagnostic. R1 (anchor-phrase preservation for § Wave Dispatch), R2 (the validation-wrapper lines are self-contained — name the script and the diagnostic inline), R3 (the wrapper calls land immediately around the `git merge --no-ff` step, the load-bearing position), R7 (verbatim phrasing the design.md G6 § Solution validation seam expects), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Wave Dispatch; R2 — the validation-wrapper lines are self-contained, name the script and the named diagnostic inline; R3 — the `--capture` and `--validate` calls land immediately around the `git merge --no-ff` step; R7 — verbatim phrasing of the design.md G6 § Solution validation seam; R8 — prose-density tightening.

### T20b: Insert OBC step and batch-gate additions in skills/implement/SKILL.md with Dispatch-defects unconditional halt branch
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/implement/SKILL.md` (Modify)
- **Dependencies:** T19
- **LOC estimate:** ~80
- **Description:** A new `### Step N — Orchestration boundary observability check` block lands before the batch-gate step in `skills/implement/SKILL.md`, calling `scripts/orchestration-boundary-check.sh --phase implement --artifact-dir <ABS>` at phase end after all waves complete. The batch-gate section gains interactive-menu and autopilot branched-default additions surfacing the OBC report before phase advancement. The autopilot branched-default has three branches: (a) clean report (zero entries) → proceed to next phase; (b) commit or workspace entries only → surface the report to the operator for review and proceed under operator confirmation; (c) any entries under the report's `## Dispatch defects` section → halt unconditionally — write `HALT-orchestration-boundary-undeterminable.md` to `<artifact-dir>/reviews/implement/` and exit the autopilot loop. The third branch is unconditional: no operator override, no skip-and-continue. R1 (anchor-phrase preservation for § Batch Gate), R2 (the OBC block and the three branches are self-contained — name the script, the report path, the dispatch-defect halt file, and the unconditional direction inline), R3 (the OBC call lands at phase end after all waves complete, the load-bearing position), R7 (verbatim phrasing the T24 lint and the autopilot loop's halt-decision consumer expect), and R8 (prose-density tightening of the non-HARD-RULE prose) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Batch Gate; R2 — the OBC block and the three autopilot branches are self-contained, name the script, the report path, the dispatch-defect halt file, and the unconditional direction inline; R3 — the OBC call lands at phase end after all waves complete; R7 — verbatim phrasing of the design.md G5 § Solution (b) and (c) inlines; R8 — prose-density tightening.
  - The autopilot branched-default contains a third branch keyed on the `## Dispatch defects` section of the OBC report: any non-empty Dispatch-defects section triggers an unconditional halt — `HALT-orchestration-boundary-undeterminable.md` is written and the autopilot loop exits — with no operator override or skip-and-continue branch (silent-claude F02 unconditional-halt direction).

### T21: Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/integrate/SKILL.md
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/integrate/SKILL.md` (Modify)
- **Dependencies:** T19, T04b
- **LOC estimate:** ~110
- **Description:** `skills/integrate/SKILL.md` gains the verbatim HARD-RULE Orchestration Boundary section (the "MAIN CHAT ONLY ORCHESTRATES" block plus per-phase responsibilities, "does NOT" list, and "Why this rule matters in Integrate" rationale — all self-contained, no cross-skill references). A new `### Step N — Orchestration boundary observability check` block lands before the batch-gate step calling `scripts/orchestration-boundary-check.sh --phase integration --artifact-dir <ABS>`. The batch-gate section gains interactive-menu and autopilot branched-default additions surfacing the OBC report. The phase-start prose names the `reviews/integration/phase-base.txt` write (recording `integration_base_sha=<HEAD-SHA>` for the OBC script to read) as the **first orchestrator action of the integrate phase** — performed before any subagent dispatch in the phase. R1, R2, R3 (load-bearing HARD-RULE at the top of the skill body — the section the orchestrator must internalise first), R7 (verbatim phrasing the T24 lint and the OBC script's phase-base read path depend on), and R8 (prose-density tightening of the non-HARD-RULE prose; the HARD-RULE block itself is verbatim and not tightened) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the integrate skill's existing structure; R2 — the verbatim HARD-RULE block, the responsibilities list, the "does NOT" list, and the rationale are self-contained (no cross-skill references); R3 — HARD-RULE block lands at a top-of-skill position the orchestrator must internalise first; R7 — verbatim phrasing of the design.md G5 § Solution (a) prose-design block (the T24 lint and the OBC integration read path depend on the literal phrasing of the phase-base.txt write step); R8 — prose-density tightening of the non-HARD-RULE prose (HARD-RULE itself is not tightened — "what NOT to tighten" guardrail covers verbatim contract blocks).
  - The phase-start prose names the `reviews/integration/phase-base.txt` write as the first orchestrator action of the integrate phase, performed before any subagent dispatch in the phase — so the OBC script's per-phase read path always finds a written phase-base when the OBC step runs.

### T22: Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/test/SKILL.md
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/test/SKILL.md` (Modify)
- **Dependencies:** T19, T04b
- **LOC estimate:** ~110
- **Description:** `skills/test/SKILL.md` gains the verbatim HARD-RULE Orchestration Boundary section with the `reviews/test/round-NN-results.md` allowlisted-write exception named in the per-phase responsibilities list, the Step-N OBC block calling `scripts/orchestration-boundary-check.sh --phase test --artifact-dir <ABS>`, the batch-gate interactive and autopilot additions, and a phase-start write of `reviews/test/phase-base.txt`. The phase-base.txt write is named as the **first orchestrator action of the test phase** — performed before any subagent dispatch in the phase. R1, R2, R3 (load-bearing HARD-RULE positioning), R7 (verbatim phrasing the T24 lint depends on), and R8 (prose-density tightening of the non-HARD-RULE prose) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the test skill's existing structure; R2 — the HARD-RULE block (with the `reviews/test/round-NN-results.md` allowlisted-write exception named in the responsibilities list) is self-contained; R3 — HARD-RULE at the load-bearing top-of-skill position; R7 — verbatim phrasing the T24 lint and the OBC test read path depend on; R8 — prose-density tightening of the non-HARD-RULE prose.
  - The phase-start prose names the `reviews/test/phase-base.txt` write as the first orchestrator action of the test phase, performed before any subagent dispatch in the phase — so the OBC script's per-phase read path always finds a written phase-base when the OBC step runs.

### T23: Insert cross-cutting Orchestration Boundary note in skills/using-qrspi/SKILL.md
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** lightweight
- **tier:** low
- **Target files:** `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** T19
- **LOC estimate:** ~15
- **Description:** A verbatim `### Orchestration Boundary applies to every phase` cross-cutting note is added to `skills/using-qrspi/SKILL.md`, pointing readers at the per-phase prose in `integrate/SKILL.md` and `test/SKILL.md` (which T21 and T22 author). The note is self-contained — it carries the HARD-RULE summary inline so the using-qrspi-only context still surfaces the rule even when the per-phase skills are not yet loaded. R1 (anchor-phrase preservation for surrounding universal-orchestrator-behaviours sections), R2 (self-contained inline HARD-RULE summary), R3 (load-bearing — placed in the universal-rules section, not buried), R7 (verbatim heading phrasing), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding universal-orchestrator-behaviours sections; R2 — the cross-cutting note is self-contained (carries the HARD-RULE summary inline so using-qrspi alone surfaces the rule); R3 — the note lands in the universal-rules section, not buried; R7 — verbatim heading `### Orchestration Boundary applies to every phase`; R8 — prose-density tightening of the note.

### T24: Create tests/lint/test-integrate-test-skill-phase-base-write.bats
- **Phase:** 1
- **Goal IDs:** [G5]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/lint/test-integrate-test-skill-phase-base-write.bats` (Create)
- **Dependencies:** T21, T22
- **LOC estimate:** ~30
- **Description:** A grep audit asserts `skills/integrate/SKILL.md` and `skills/test/SKILL.md` each carry the phase-base.txt write step at phase start — the literal anchor phrases that name `reviews/integration/phase-base.txt` and `reviews/test/phase-base.txt` as the write targets. The lint locks the write side against silent SKILL-prose drift that would break the OBC script's integration/test read paths.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - `skills/integrate/SKILL.md` contains the phase-base.txt write step naming `reviews/integration/phase-base.txt` (anchor-phrase grep) — locks the SKILL prose against the OBC integration read path (G5 Acceptance bullet 4 sub-bullet read-path coverage).
  - `skills/test/SKILL.md` contains the phase-base.txt write step naming `reviews/test/phase-base.txt` (anchor-phrase grep).
  - A fixture skill body missing the write step fails the lint with a named diagnostic.

### T25: Create scripts/validate-stage-commit-parents.sh with --capture/--validate, SHA-format validation, and bats unit test
- **Phase:** 1
- **Goal IDs:** [G6]
- **task_type:** tdd
- **tier:** high
- **Target files:** `scripts/validate-stage-commit-parents.sh` (Create), `tests/unit/test-validate-stage-commit-parents.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~150
- **cross_task_consumers:**
  - `skills/implement/SKILL.md` (T20a) — disposition: `pass-through` (T20a's Wave Dispatch prose wraps the `git merge --no-ff` invocation with the `--capture` and `--validate` calls this script defines; T20a is the sole call site of this script in the skill prose).
- **Description:** A new script with two modes wraps the existing wave-dispatch merge step. `--capture` (called pre-merge) writes the integration-base SHA (`git rev-parse HEAD`) and the per-task-tip SHAs (`git rev-parse refs/heads/<task-NN>` for each task in the wave) to a runtime sidecar under `reviews/implement/wave-state/`. `--validate` (called post-merge) reads the sidecar, reads actual parents from `git log --format='%P' -n 1 HEAD`, asserts `actual_parents[0] == captured_integration_base_sha` (first-parent ordering invariant) and `set(actual_parents[1:]) == set(captured_task_tip_shas)` (task-tip set equality), and halts non-zero with the named `stage-commit-parent-mismatch:` diagnostic on either-invariant failure. Every SHA the script reads from the runtime sidecar is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE being passed to any `git` invocation or comparison; a malformed SHA triggers the named `sha-format-invalid:` diagnostic and a non-zero exit. A sidecar whose on-disk shape does not match the expected schema (missing `integration_base:` field, missing `task_tips:` list, malformed key/value structure, or extra unknown top-level fields) triggers the named `sidecar-schema-mismatch:` diagnostic and a non-zero exit before any SHA value is read or compared. The runtime sidecar preserves the symbolic-only branch-map invariant — resolved SHAs are NOT written back to `parallelization.md`.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Fixture stage commit with correct parents — validation passes silently, wave advances (G6 Acceptance bullet 1 sub-bullet 1).
  - Fixture stage commit with correct task-tip set but integration-base NOT in parent[0] position — validation halts with `stage-commit-parent-mismatch` diagnostic naming the wrong first-parent SHA (G6 Acceptance bullet 1 sub-bullet 2).
  - Fixture stage commit with one task tip missing from parent set — validation halts naming the missing tip (G6 Acceptance bullet 1 sub-bullet 3).
  - Fixture stage commit with an unexpected extra parent — validation halts naming the extra parent (G6 Acceptance bullet 1 sub-bullet 4).
  - Single-task fixture wave — integration-base parent counted correctly in expected set; passes when present, halts when absent (G6 Acceptance bullet 1 sub-bullet 5).
  - `--capture` writes integration-base SHA and task-tip SHAs as separable fields to the runtime sidecar before `git merge`; `--validate` reads from that sidecar (G6 Acceptance bullet 3).
  - `parallelization.md` is unchanged after the wave — runtime sidecar holds the resolved SHAs (symbolic-only branch-map invariant per research Q11/Q12, G6 Acceptance bullet 3 final clause).
  - A SHA read from the runtime sidecar that fails the well-formed git object-name shape triggers the `sha-format-invalid:` named diagnostic and a non-zero exit — no `git` command runs against the malformed value, no comparison proceeds.
  - A runtime sidecar whose on-disk shape does not match the expected schema (missing `integration_base:`, missing `task_tips:` list, malformed key/value structure, or extra unknown top-level fields) triggers the `sidecar-schema-mismatch:` named diagnostic and a non-zero exit before any SHA value is read or compared (coverage-claude F03).

### T26: Replace HEAD~1 with anchor-file lookup in using-qrspi Apply-fix step 12, sweep inlining skills, and validate the anchor-file SHA
- **Phase:** 1
- **Goal IDs:** [G7]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/using-qrspi/SKILL.md` (Modify — the canonical Apply-fix step 12 definition), `skills/design/SKILL.md` (Modify), `skills/goals/SKILL.md` (Modify), `skills/implement/SKILL.md` (Modify), `skills/implementer-protocol/SKILL.md` (Modify), `skills/integrate/SKILL.md` (Modify), `skills/parallelize/SKILL.md` (Modify), `skills/phasing/SKILL.md` (Modify), `skills/plan/SKILL.md` (Modify), `skills/questions/SKILL.md` (Modify), `skills/replan/SKILL.md` (Modify), `skills/research/SKILL.md` (Modify), `skills/reviewer-protocol/SKILL.md` (Modify), `skills/structure/SKILL.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~30
- **dependent_tests:**
  - `tests/unit/test-narrow-round-anchor-lookup.bats` (T27 — three fixtures asserting the anchor-file-lookup incantation behaves correctly under the failure modes `HEAD~1` exposed, plus the SHA-format validation halt direction)
- **Description:** `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 12 narrow-ref incantation is replaced with the anchor-file lookup `git diff "$(cat reviews/<step>/round-<NN-1>-commit.txt)" -- <artifact-path>`. Any other skill whose body inlines the step-12 `HEAD~1` shorthand (surfaced by `grep -rn 'HEAD~1' skills/`) is updated identically at the inlining site. The new incantation prose names a SHA-format validation step: the SHA read from `reviews/<step>/round-<NN-1>-commit.txt` is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE being passed to the `git diff` invocation; a malformed anchor file triggers the named `sha-format-invalid:` diagnostic and halts non-zero. The existing divergence-sanity-check halt with the `narrow-round-empty-diff:` named diagnostic is preserved verbatim. R1 (anchor-phrase preservation for § Apply-fix protocol step 12 surrounding prose), R2 (the new incantation is self-contained — names the anchor file path and the SHA-format halt direction inline), R3 (load-bearing incantation in its existing position), R7 (verbatim phrasing the T27 bats fixture asserts), and R8 (no tightening — the incantation is a literal command, not prose) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Apply-fix protocol step 12's surrounding prose; R2 — the new incantation is self-contained, names the anchor file path and the SHA-format halt direction inline; R3 — incantation in its existing load-bearing position; R7 — verbatim phrasing of `git diff "$(cat reviews/<step>/round-<NN-1>-commit.txt)" -- <artifact-path>` (the T27 bats fixtures grep for this literal substring); R8 — the incantation is a literal command, not prose subject to R8 tightening; the divergence-sanity-check halt with the `narrow-round-empty-diff:` named diagnostic is preserved verbatim; zero occurrences of `git diff HEAD~1 --` remain in step 12 (and at any inlining site surfaced by `grep -rn 'HEAD~1' skills/`).
  - The anchor-file SHA read from `reviews/<step>/round-<NN-1>-commit.txt` is validated against the well-formed git object-name shape before the `git diff` invocation; a malformed anchor file triggers the `sha-format-invalid:` named diagnostic and a non-zero exit — no `git diff` runs against the malformed value.

### T27: Create tests/unit/test-narrow-round-anchor-lookup.bats
- **Phase:** 1
- **Goal IDs:** [G7]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `tests/unit/test-narrow-round-anchor-lookup.bats` (Create)
- **Dependencies:** T26
- **LOC estimate:** ~60
- **Description:** A bats test with three fixtures verifies the anchor-file lookup behaves correctly under the failure modes `HEAD~1` exposed. Fixture 1: round N+1 with an unrelated commit landed between rounds — the anchor-file-based diff returns round N's per-round commit content, the `HEAD~1`-based diff returns wrong content (regression guard against the v0.7.2 shifted-shape bug). Fixture 2: anchor file missing — the orchestrator's call exits non-zero with a clear error, no silent fallback to `HEAD~1`. Fixture 3: empty narrowed diff — the divergence sanity check fires with the `narrow-round-empty-diff:` named diagnostic.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Fixture with an unrelated commit between rounds — anchor-file-based diff "returns the correct content (round N's per-round commit diff)" while `HEAD~1`-based diff "returns wrong content" (G7 Acceptance bullet 3 sub-bullet 1).
  - Missing anchor file — the orchestrator's call "exits non-zero with a clear error (no silent fallback)" (G7 Acceptance bullet 3 sub-bullet 2).
  - Empty-narrowed-diff — "the divergence sanity check fires with the `narrow-round-empty-diff` diagnostic" (G7 Acceptance bullet 3 sub-bullet 3).
  - Fixture with a malformed anchor file (e.g., uppercase hex, non-hex characters, or content outside the well-formed git object-name shape) — the orchestrator's call halts with the `sha-format-invalid:` named diagnostic and exits non-zero before any `git diff` runs against the malformed value.

### T28: Create VERSION file and stamp the five consumer manifests from tools/build-plugin.mjs with bats coverage
- **Phase:** 1
- **Goal IDs:** [G8]
- **task_type:** tdd
- **tier:** high
- **Target files:** `VERSION` (Create), `tools/build-plugin.mjs` (Modify), `.claude-plugin/marketplace.json` (Modify), `.claude-plugin/plugin.json` (Modify), `.github/plugin/marketplace.json` (Modify), `.github/plugin/plugin.json` (Modify), `build/.claude-plugin/plugin.json` (Modify), `tests/unit/test-version-stamping.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~120
- **cross_task_consumers:**
  - `.github/workflows/build-then-diff.yml` (T29) — disposition: `pass-through` (T29 is the operational consumer of the build-script change; the CI gate runs the build-then-diff flow that depends on `tools/build-plugin.mjs` stamping VERSION into the five consumer manifests).
  - `docs/release-runbook.md` (T30) — disposition: `pass-through` (T30 documents the new release flow, naming `VERSION` as the sole authoring path and the `version-source-missing-or-malformed:` / `version-source-malformed:` diagnostics — the runbook references contracts this task defines, but no edit to this task's deliverables is required).
- **Description:** A repo-root `VERSION` file (bare one-line containing the version string, e.g., `0.7.3`) becomes the sole authoring path for the plugin version. `tools/build-plugin.mjs` reads `VERSION` and writes the value into the `"version"` field of all five consumer files on every build. The build script halts non-zero with `version-source-missing-or-malformed: VERSION at repo root must contain a single non-empty version string` on missing, empty, or multi-line `VERSION`. Beyond the structural one-line-non-empty check, the VERSION content is validated against an explicit semver allowlist regex `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` (major.minor.patch with optional `+build` or `-prerelease` suffix); a value that is a well-formed single non-empty line but does NOT match the semver shape triggers the distinct `version-source-malformed:` named diagnostic and halts non-zero — preventing arbitrary content (e.g., `latest`, `v0.7.3`, `0.7`, `0.7.3.4`, shell-substitution attempts) from being stamped into the five consumer manifests (security-claude R2-F02). The five consumer files are updated in this task to reflect the current version stamped from VERSION (mechanical update on first run).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - `VERSION` exists at repo root and "contains exactly one version string" (G8 Acceptance bullet 1).
  - `echo "9.9.9" > VERSION && node tools/build-plugin.mjs && grep '"version": "9.9.9"'` matches in all five consumer files (G8 Acceptance bullet 2, verbatim).
  - The build script halts with the named diagnostic `version-source-missing-or-malformed:` on missing-file and empty-file cases (G8 Acceptance bullet 4).
  - A multi-line `VERSION` triggers the `version-source-missing-or-malformed:` named diagnostic (edge case per design § Dependencies bullet 1).
  - A single-line VERSION whose content does NOT match the semver shape `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` (e.g., `latest`, `v0.7.3`, `0.7`, `0.7.3.4`, `$(rm -rf /)`) triggers the `version-source-malformed:` named diagnostic and a non-zero exit — distinct from the `version-source-missing-or-malformed:` structural-class failure (security-claude R2-F02).
  - A single-line VERSION that DOES match the semver shape (including suffixes like `0.7.3-rc1`, `0.7.3+build.42`) passes validation and stamps successfully into the five consumer files.
  - `build/.claude-plugin/plugin.json` is updated by the build script (not by hand) — proves the sole-writer discipline for `build/`.

### T29: Create .github/workflows/build-then-diff.yml CI gate
- **Phase:** 1
- **Goal IDs:** [G8]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `.github/workflows/build-then-diff.yml` (Create)
- **Dependencies:** T28
- **LOC estimate:** ~40
- **Description:** A new CI workflow runs `node tools/build-plugin.mjs && git diff --exit-code` on every PR and fails on any divergence between the freshly-built tree and the committed tree. The gate catches the entire class of "did the committed `build/` artifact match the source?" regressions — version drift, build-artifact drift in `build/`, marketplace `source` field shifts (the v0.7.2.3 `source: "./"` vs `"./build"` shape) — not version-only drift.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The CI step "runs `node tools/build-plugin.mjs && git diff --exit-code` and fails on any divergence" (G8 Acceptance bullet 3, first half).
  - A fixture commit that "hand-edits `"version"` in one consumer file (without bumping `VERSION`) causes the CI step to fail" (G8 Acceptance bullet 3, second half).
  - The workflow triggers on every PR (not only on release branches) — pull_request event configured.
  - Workflow failure output names the diverging file(s) (named-diagnostic discipline via `git diff --exit-code`'s natural output).

### T30: Document the new release flow in docs/release-runbook.md
- **Phase:** 1
- **Goal IDs:** [G8]
- **task_type:** lightweight
- **tier:** low
- **Target files:** `docs/release-runbook.md` (Modify if existing, else Create)
- **Dependencies:** T28
- **LOC estimate:** ~30
- **Description:** The release runbook is updated (or created) to name `VERSION` as the only file an author edits to bump, describe the `node tools/build-plugin.mjs` propagation step that writes the new version into all five consumer files, and document the release-commit shape — one commit containing the `VERSION` edit, the propagated stamps in the five consumer files, and the regenerated `build/` content. R1 (anchor-phrase preservation for any existing release-runbook structure), R2 (the new section is self-contained — names the file, the command, and the commit shape inline), R3 (load-bearing release-flow section at a discoverable position), R7 (verbatim phrasing of `VERSION` and the build command), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for any existing release-runbook structure; R2 — the new section is self-contained, names `VERSION`, the build command, and the release-commit shape inline; R3 — release-flow section at a discoverable position; R7 — verbatim phrasing of `VERSION` as the single authoring path and `node tools/build-plugin.mjs` as the propagation step; R8 — prose-density tightening.

### T31: Create the 6 skills/_shared/ snippet files
- **Phase:** 1
- **Goal IDs:** [G9]
- **task_type:** lightweight
- **tier:** medium
- **Target files:** `skills/_shared/reviewer-dispatch.md` (Create), `skills/_shared/review-loop.md` (Create), `skills/_shared/config-validation.md` (Create), `skills/_shared/compaction-checkpoint.md` (Create), `skills/_shared/pause-gate.md` (Create), `skills/_shared/feedback-format.md` (Create)
- **Dependencies:** none
- **LOC estimate:** sizing_exception: reusable-primitives (six new shared snippet files — single source of truth for multi-skill load-bearing process boilerplate)
  - **sizing_rationale:** Each snippet is the single source of truth for a multi-skill process boilerplate; per-file LOC is small but six files sum above the 200-LOC ceiling. Each snippet replaces N inlined copies across the consuming skills; net active-context footprint decreases.
- **cross_task_consumers:**
  - `skills/using-qrspi/SKILL.md` (T32) — disposition: `pass-through` (T32's Pass 1 three-tier placement `!cat`-resolves multi-skill load-bearing process boilerplate from `skills/_shared/`; no edit to this task's deliverables required).
  - `skills/implement/SKILL.md` (T33) — disposition: `pass-through` (T33's Pass 1 three-tier placement `!cat`-resolves reviewer-dispatch, review-loop, pause-gate, feedback-format as applicable; no edit to this task's deliverables required).
  - `skills/plan/SKILL.md` (T34) — disposition: `pass-through` (T34's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate; no edit to this task's deliverables required).
  - `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` (T35) — disposition: `pass-through` (T35's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate across the 8 artifact-step skills; no edit to this task's deliverables required).
  - `skills/{integrate,test,implementer-protocol,reviewer-protocol,research-isolation,prompt-prose-writer,prompt-prose-reviewer}/SKILL.md` (T36) — disposition: `pass-through` (T36's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate across the 7 cross-cutting skills; no edit to this task's deliverables required).
- **dependent_tests:**
  - `tests/lint/test-skill-trim-audit.bats` (T38 — grep audit verifies the snippet boundaries hold post-trim and the `!cat` references resolve in consuming skills)
- **Description:** Six new snippet files under `skills/_shared/` are authored as the single source of truth for the multi-skill load-bearing process boilerplate that consuming skills `!cat`-resolve at skill-load time. `reviewer-dispatch.md` carries the verbatim reviewer-dispatch incantation; `review-loop.md` carries the Standard Review Loop body; `config-validation.md` carries the Config Validation procedure body; `compaction-checkpoint.md` carries the Compaction Checkpoint template; `pause-gate.md` carries the Pause Gate UI; `feedback-format.md` carries the Feedback File Format. Each snippet is self-contained — consuming skills inline-resolve it via `!cat` and reviewers verify the rule against the snippet, not the inlined copy. R1 (anchor-phrase preservation across snippets — consuming skills depend on stable phrasing), R2 (each snippet is self-contained — no cross-snippet references that fragment salience), R3 (snippets carry only load-bearing content — informational templates land at the start of the consuming skill, load-bearing rules at the end), R7 (verbatim phrasing the consuming skills depend on), and R8 (prose-density tightening of all snippet bodies) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation across snippets (consuming skills depend on stable phrasing); R2 — each snippet is self-contained, no cross-snippet references that fragment salience; R3 — informational templates land at the start of the consuming skill body, load-bearing rules at the end (the consuming-skill `!cat` ordering reflects this); R5 — snippets carry every-invocation content (R5(a)/(b)/(c) ruled out for these — that's why `!cat` rather than Read-on-demand `references/`); R7 — verbatim phrasing the consuming skills, reviewers, and any anchor-phrase greps depend on; R8 — prose-density tightening of all snippet bodies.

### T32: Trim skills/using-qrspi/SKILL.md (Pass 1+2+3) to target <350 lines
- **Phase:** 1
- **Goal IDs:** [G9, CD-3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T01, T05, T09, T13a, T15, T16, T20a, T20b, T23, T26
- **LOC estimate:** sizing_exception: reusable-primitives (canonical bootstrapper trim — three-tier placement pass over the universal-orchestrator-behaviour bootstrapper)
  - **sizing_rationale:** Trim pass touches a single file but the cross-cutting nature of the canonical bootstrapper makes any per-line scoping arbitrary; the unit of work is the full pass against the trimmed state.
- **Description:** Pass 1 (three-tier placement) reorganises `skills/using-qrspi/SKILL.md` so universal orchestrator behaviours stay, multi-skill load-bearing process boilerplate `!cat`-resolves to the new `skills/_shared/` snippets (T31), skill-specific process moves to the owning skill, and optional examples plus rare-path procedures move to `skills/using-qrspi/references/<topic>.md`. Pass 2 (script-mechanic restatement deletion) removes prose that narrates dispatch / jobId / tmpfile / HEAD~1 / convergence / sidecar-schema / change_type-enum / third-party-splitter mechanics — scripts are SSoT. Pass 3 (R8 tightening) applies the R8 reviewer test to every kept paragraph. The G2/G3/G5/G7 prose-adding changes (T13a, T23, T26, the canonical Apply-fix step 12, the pre-fanout anchor) are preserved through the trim. R1, R2, R3, R5 (`references/` extraction only for genuinely optional content per R5 conditions), R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of using-qrspi's distinctive headings and the G2/G3/G5/G7 prose additions (T13a, T23, T26, the canonical Apply-fix step 12, the pre-fanout anchor) through the trim; R2 — every kept paragraph self-contained post-trim; R3 — load-bearing universal rules retained in the active body, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only for content satisfying R5(a) optional, R5(b) rare-path, or R5(c) pedagogical conditions; R7 — anchor phrases the reviewer dispatch and lint tests depend on are exact post-trim; R8 — R8 reviewer test applied to every kept paragraph; trim audit (T38) produces zero matches for the narrative-restatement pattern set; target <350 lines as a guidepost (the regression guard via the v0.7.2 phase-1 acceptance suite is the real gate).

### T33: Trim skills/implement/SKILL.md (Pass 1+2+3) to target <500 lines
- **Phase:** 1
- **Goal IDs:** [G9, CD-3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/implement/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T20a, T20b
- **LOC estimate:** sizing_exception: reusable-primitives (canonical implementer-spine trim)
  - **sizing_rationale:** Trim pass against the heaviest active skill body; the unit of work is the full pass against the post-T20a/T20b state.
- **Description:** Three-tier placement plus deletion plus R8 tightening applied to `skills/implement/SKILL.md`. The 4× verifier-wiring duplication collapses to one canonical reference; the 2× visual-fidelity dispatch duplication collapses to one canonical reference; jobId / tmpfile / HEAD~1 / convergence-table / sidecar-schema / change_type-enum / third-party-splitter narrative restatements are deleted (scripts are SSoT); `_shared/` `!cat` references are added for reviewer-dispatch, review-loop, pause-gate, feedback-format as applicable. The T20a additions (Wave Dispatch validation wrap) and T20b additions (OBC step, batch-gate additions including the unconditional dispatch-defects halt branch) are preserved through the trim. R1, R2, R3, R5, R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of implement/SKILL.md's distinctive headings and the T20a + T20b additions (OBC step, Wave Dispatch validation wrap, batch-gate additions including the unconditional dispatch-defects halt branch) through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing wave-dispatch and batch-gate content retained, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — anchor phrases the T24 lint and any reviewer dispatch depend on are exact post-trim; R8 — R8 reviewer test applied; 4× verifier-wiring and 2× visual-fidelity duplications collapsed; jobId / tmpfile / HEAD~1 / convergence-table / sidecar-schema / change_type-enum / third-party-splitter narrative restatements deleted; trim audit (T38) passes; target <500 lines.

### T34: Trim skills/plan/SKILL.md (Pass 1+2+3) to target <400 lines
- **Phase:** 1
- **Goal IDs:** [G9, CD-3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/plan/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T15
- **LOC estimate:** sizing_exception: reusable-primitives (plan-skill trim)
  - **sizing_rationale:** Trim pass against the plan-authoring spine; the unit of work is the full pass against the post-T15 state.
- **Description:** Three-tier placement plus deletion plus R8 tightening applied to `skills/plan/SKILL.md`. The new T15 pre-fanout absorption-map anchor sentence is preserved verbatim through the trim. `_shared/` `!cat` references replace any inlined reviewer-dispatch, review-loop, or pause-gate boilerplate. Optional pedagogical content (worked examples, rare-path procedures) moves to `skills/plan/references/<topic>.md`. R1 (the T15 anchor sentence is anchor-phrase-preserved), R2, R3, R5, R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of plan/SKILL.md's distinctive headings and the T15 pre-fanout absorption-map anchor sentence verbatim through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing plan-authoring content retained, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — T15's anchor sentence preserved verbatim; R8 — R8 reviewer test applied; trim audit (T38) passes; target <400 lines.

### T35: Trim the 8 artifact-step skills to target <300 lines each
- **Phase:** 1
- **Goal IDs:** [G9, CD-3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/goals/SKILL.md` (Modify), `skills/questions/SKILL.md` (Modify), `skills/research/SKILL.md` (Modify), `skills/design/SKILL.md` (Modify), `skills/phasing/SKILL.md` (Modify), `skills/structure/SKILL.md` (Modify), `skills/parallelize/SKILL.md` (Modify), `skills/replan/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T05
- **LOC estimate:** sizing_exception: reusable-primitives (8-file bulk-pass sweep — single repeated trim shape across the 8 artifact-step skills)
  - **sizing_rationale:** Bulk-pass mechanical sweep applying the four-pass trim to eight skill bodies; the unit of work is the full pass against the post-T05 state.
- **dependent_tests:**
  - `tests/lint/test-no-diff-redirect-prose.bats` (T06 — locks the artifact-step skills against the diff-redirect prose pattern T05 removed; post-trim the lint must still pass)
  - `tests/lint/test-skill-trim-audit.bats` (T38 — grep audit verifies the narrative-restatement pattern set is absent across the 8 trimmed skills)
- **Description:** Each of the eight artifact-step skills (`goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`) applies the three-tier placement plus deletion plus R8 tightening passes against its post-T05 state (the high-level-dispatch replacement prose from T05 is already in place). `_shared/` `!cat` references replace any inlined boilerplate; per-skill `references/<topic>.md` files are created at extract time for optional examples or rare-path procedures. R1 (anchor-phrase preservation for each skill's distinctive headings), R2, R3, R5 (`references/` extraction only under R5 conditions), R7, R8 shape the sweep.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of each artifact-step skill's distinctive headings and the T05 high-level-dispatch replacement prose through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing per-step process retained, informational content moved to per-skill `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — T05's anchor phrases preserved verbatim (the T06 lint depends on the absence of the diff-redirect pattern, which post-trim must still hold); R8 — R8 reviewer test applied across all 8 files; trim audit (T38) passes for all 8 files; target <300 lines each.

### T36: Trim the 7 cross-cutting skills to target <300 lines each
- **Phase:** 1
- **Goal IDs:** [G9, CD-3]
- **task_type:** lightweight
- **tier:** high
- **Target files:** `skills/integrate/SKILL.md` (Modify), `skills/test/SKILL.md` (Modify), `skills/implementer-protocol/SKILL.md` (Modify), `skills/reviewer-protocol/SKILL.md` (Modify), `skills/research-isolation/SKILL.md` (Modify), `skills/prompt-prose-writer/SKILL.md` (Modify), `skills/prompt-prose-reviewer/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T13a, T13b, T21, T22
- **LOC estimate:** sizing_exception: reusable-primitives (7-file bulk-pass sweep — single repeated trim shape across the 7 cross-cutting skills)
  - **sizing_rationale:** Bulk-pass mechanical sweep applying the four-pass trim to seven cross-cutting skill bodies; the unit of work is the full pass against the post-T13a/T21/T22 state.
- **dependent_tests:**
  - `tests/lint/test-skill-trim-audit.bats` (T38 — grep audit verifies the narrative-restatement pattern set is absent across the 7 trimmed skills, and that the HARD-RULE anchor blocks survive)
  - `tests/lint/test-integrate-test-skill-phase-base-write.bats` (T24 — anchor-phrase grep for the phase-base.txt write step in `skills/integrate/SKILL.md` and `skills/test/SKILL.md` must still pass post-trim)
- **Description:** Each of the seven cross-cutting skills applies the three-tier placement plus deletion plus R8 tightening passes against its post-T13a/T13b/T21/T22 state. The G2 promotion-to-blocking sentence (T13a) and the new revert-orchestration-drift fix-task mode prose (T13b) in `implementer-protocol/SKILL.md`, and the verbatim HARD-RULE Orchestration Boundary sections plus phase-base.txt write steps in `integrate/SKILL.md` and `test/SKILL.md` (T21, T22), are preserved through the trim — HARD-RULE prose and the revert-orchestration-drift mode body are not tightened by R8 (the "What NOT to tighten" guardrail covers verbatim contract blocks and load-bearing fix-mode definitions). `_shared/` `!cat` references replace any inlined boilerplate. R1 (preservation of the HARD-RULE and other anchor blocks, including the T13b mode body), R2, R3, R5, R7, R8 shape the sweep.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of each cross-cutting skill's distinctive headings, the T13a promotion-to-blocking sentence and the T13b revert-orchestration-drift fix-task mode prose in `implementer-protocol/SKILL.md`, and the verbatim HARD-RULE Orchestration Boundary sections plus phase-base.txt write steps in `integrate/SKILL.md` and `test/SKILL.md` (T21, T22) through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing cross-cutting rules retained; R5 — extraction only under R5 conditions; R7 — anchor phrases (HARD-RULE blocks, blocking-sentence anchor, phase-base.txt write step, revert-orchestration-drift mode body) preserved verbatim — HARD-RULE prose and the T13b mode body are not tightened by R8 (the "what NOT to tighten" guardrail covers verbatim contract blocks and load-bearing fix-mode definitions); R8 — R8 reviewer test applied to non-HARD-RULE prose; trim audit (T38) passes for all 7 files; target <300 lines each.

### T37: Create scripts/measure-active-footprint.sh, run it against the trimmed tree, and write g9-footprint-report.md
- **Phase:** 1
- **Goal IDs:** [G9]
- **task_type:** tdd
- **tier:** medium
- **Target files:** `scripts/measure-active-footprint.sh` (Create), `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (Create)
- **Dependencies:** T32, T33, T34, T35, T36
- **LOC estimate:** ~120
- **Description:** A measurement script resolves `!cat` references transitively across the trimmed skill bodies (with cycle detection and named diagnostics — `footprint-snippet-unresolvable:` for an unresolvable `!cat` target, `footprint-snippet-cycle:` for circular `!cat` references), tokenises the resolved content with a pinned tokenizer (default `tiktoken:cl100k_base`), and emits a per-turn footprint count for a typical session (`using-qrspi` + the heaviest active skill + all `!cat`'d shared snippets). The captured stdout becomes the body of `g9-footprint-report.md`, recording the post-trim footprint as the G9 acceptance evidence.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The script "resolves `!cat` references transitively" against a fixture skill body with nested `!cat` references (cycle detection coverage).
  - An unresolvable `!cat` reference surfaces the `footprint-snippet-unresolvable:` named diagnostic and a non-zero exit (no silent skip; coverage-claude F01).
  - A circular `!cat` reference (A `!cat`s B which `!cat`s A) is detected and surfaces the `footprint-snippet-cycle:` named diagnostic and a non-zero exit (cycle detection coverage; coverage-claude F01).
  - Run against the trimmed tree (post-T32-through-T36), the script "shows total per-turn footprint (using-qrspi + heaviest active skill + `!cat`'d shared snippets) below 30K tokens for a typical session" (G9 Acceptance bullet 7, verbatim).
  - The captured stdout is written to `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (G9 Acceptance bullet 7, final clause).

### T38: Create tests/lint/test-skill-trim-audit.bats grep audit
- **Phase:** 1
- **Goal IDs:** [G9]
- **task_type:** tdd
- **tier:** low
- **Target files:** `tests/lint/test-skill-trim-audit.bats` (Create)
- **Dependencies:** T32, T33, T34, T35, T36
- **LOC estimate:** ~35
- **Description:** A grep audit asserts zero matches across all active SKILL.md files for the documented narrative-restatement patterns: `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, `third-party.*splitter`. The audit's scope is narrative restatements only — concrete script names in process-step calls (e.g., `scripts/round-prepare.sh`, `scripts/verifier-fan-in.sh`) are allowed and not flagged. The lint runs in CI on every PR; reintroduction of script-mechanic restatement narrative is mechanically blocked.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - "A grep-based audit confirms zero matches across all active SKILL.md files for the following patterns: `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, `third-party.*splitter`" (G9 Acceptance bullet 8, verbatim).
  - A fixture skill body that re-introduces a `jobId` narrative restatement fails the lint with a named diagnostic naming the file, line, and offending pattern (fail-direction guard).
  - Concrete script names in process-step calls (e.g., `scripts/round-prepare.sh`) are allowed — a fixture skill body with such a call does not trigger the lint (no-false-positive guard).

