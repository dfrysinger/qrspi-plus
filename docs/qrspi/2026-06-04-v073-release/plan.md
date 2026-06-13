---
status: approved
phase_start_commit: 5e054a6ec9928cf29a548e0a5de8a54bfd67697b
test_writer_tier: null
---

# Implementation Plan

## Overview

v0.7.3 ships pipeline-correctness fixes for the eight P0 defects surfaced by the v0.7.2 self-host run plus a release-wide active-skill-prompt footprint reduction, in a single phase with a single end-to-end slice. The slice extends the v0.7.2 universal dispatch chain with two new orchestration-facing scripts (`upstream-paths.sh`, `review-prep.sh`) and two new observability/validation scripts (`orchestration-boundary-check.sh`, `validate-stage-commit-parents.sh`); adds rubric clauses to four reviewer/verifier agent bodies; promotes the implementer Pre-DONE self-check from advisory to blocking; sweeps `[Tnn]` / `R\d+-F\d+` tokens from `@test` descriptions across the test corpus and pins them out with a permanent CI lint; centralises plugin version stamping behind a repo-root `VERSION` file; lands the R8 prose-density rule in `prompt-design-rules.md`; and applies a 4-pass trim (three-tier placement → delete script-mechanic restatements → R8 tightening → regression-guard execution) to all 14 active skills against six new `_shared/` snippets `!cat`-resolved at skill-load time.

Per `phasing.md`, all nine goals (G1–G9) and all three cross-goal design decisions (CD-1, CD-2, CD-3) ship together in Phase 1; there is no Phase 2, no replan gate between phases, and no content deferred to `future-*.md`.

## Phase 1: v0.7.3 release

Tasks are enumerated below. Each task carries `goal_id(s)`, `task_type`, `tier`, an LOC estimate, dependencies, and a one-sentence behavior claim. Per-task spec bodies follow the partition table below as `### Txx:` blocks in this document.

Sizing notes: `task_type: lightweight` is used where the deliverable is prompt prose only (SKILL.md / `agents/*.md` edits) — Test Expectations on those tasks will use the rules-application clause from Plan SKILL § Prompt-prose Test-Expectations clause. `task_type: tdd` is used for any task that ships or modifies a bash script, a bats fixture, or a JS build script. `sizing_exception` is named (per the closed exception set, whose canonical field values are exactly `schema-migration`, `ci-scaffolding`, `reusable-primitives` — the lowercased-hyphenated forms; prose references to the class names use the human forms "schema migration", "CI scaffolding", "reusable primitives") on tasks expected to exceed the 200-LOC ceiling. The hyphenated form is the single source of truth used in every `sizing_exception:` field across this plan; downstream consumers grep for the literal hyphenated values.

### Task partition (45 tasks) — overview

| ID | Title | goal_id(s) | task_type | tier | LOC | Deps | One-sentence behavior |
|----|-------|------------|-----------|------|-----|------|-----------------------|
| T01 | Create scripts/upstream-paths.sh with always-appended hygiene path, fail-soft unknown-step, and Plan-step branch | CD-1, G1, G4 | tdd | high | ~150 | none | Per-step upstream-artifact path list is emitted by a context-free script that honours the always-appended SKILL paths (including the canonical ID-hygiene authority) and reads `pipeline:` from `<artifact-dir>/config.md` only for the Plan branch; an unknown `--step` value returns the always-appended SKILL paths and exits 0 (per design.md CD-1 Acceptance bullet 2). |
| T02 | Create scripts/design-absorption-markers.sh | G3 | tdd | medium | ~80 | none | Grep `design.md` for the 4 enumerated absorption markers and print a tab-separated `<absorbed-ID> <absorbing-ID|"no-task">` redirect map to stdout. |
| T03 | Create scripts/review-prep.sh for per-step pre-dispatch input generation | CD-2, G3, G7 | tdd | high | ~180 (sizing_exception: reusable-primitives) | T02 | Per-step diff (narrowed via the anchor-file `cat` of `reviews/<step>/round-<NN-1>-commit.txt`, not `HEAD~1`) and per-step absorption-map (at Design and Plan) are written to known paths under `<artifact-dir>/reviews/<step>/round-NN.*`. |
| T04a | Add high-level entry mode to scripts/dispatch-agent.sh | CD-2 | tdd | high | ~80 | T03 | When `--step --round --artifact-dir` accompany the existing flags, dispatch-agent invokes `review-prep.sh` first and threads `diff_file_path` / `absorption_map_path` into reviewer prompts. |
| T04b | Add subagent author-marker env wrap to scripts/dispatch-agent.sh | G5 | tdd | high | ~50 | none | Every dispatched subagent git command is wrapped with the subagent author-marker scheme (a `GIT_AUTHOR_NAME=qrspi-<agent>` env composition validated against the agent-name charset) so subagent commits carry the marker the G5 boundary check filters on. |
| T05 | Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs | CD-2, G9 | lightweight | medium | ~80 | T04a | Each of `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` § Review Round replaces the pre-dispatch Bash diff-redirect prose with one `dispatch-agent.sh --step <step> --round NN --artifact-dir <ABS>` invocation. |
| T06 | Create tests/lint/test-no-diff-redirect-prose.bats | CD-2, G9 | tdd | low | ~25 | T05 | Grep audit asserts zero `git diff > round-NN.diff` Bash redirect blocks remain in the eight artifact-step skills. |
| T07 | Insert R8 prose-density rule in skills/_shared/prompt-design-rules.md | CD-3 | lightweight | medium | ~90 | none | New `### R8 — Prose density: short declarative sentences, full behavioral precision` section is added between R7 and the cross-cutting-principles `---` separator, and the finding-type gate `rule-violation` row cites `R1-R8`. |
| T08 | Create tests/lint/test-prompt-design-rules-r8.bats | CD-3 | tdd | low | ~35 | T07 | Anchor-phrase grep verifies R8 heading, tightening-pattern table header, "What NOT to tighten" subheading, reviewer-test sentence, the literal `R1-R8` gate citation, no duplicated R-rule headings, and every cited R-ID exists as a heading. |
| T09 | Append ID-hygiene rubric clause to agents/qrspi-finding-verifier.md | G1 | lightweight | high | ~20 | T01 | The verifier rubric directs grounding of forbidden-token-table findings in `skills/implementer-protocol/SKILL.md` § Hygiene contract via `<upstream_paths>` Read, treating its absence as a dispatch defect with no improvised fallback. |
| T10 | Create tests/unit/test-finding-verifier-id-hygiene-grounding.bats | G1 | tdd | high | ~70 | T09, T01 | A synthetic verifier dispatch on a `[Tnn]` fixture finding scores ≥ 70 against the hygiene contract; a regression-direction case against a v0.7.2-baseline rubric stub scores < 70. |
| T11 | Sweep [Tnn] and forbidden-finding-ID tokens from @test descriptions across tests/**/*.bats | G2 | tdd | medium | sizing_exception: schema-migration | T09 | A single mechanical sweep across the bats corpus strips the leading/trailing forbidden token patterns from inside `@test "..."` description strings only; intentional fixture tokens that need to appear in test bodies are emitted into generated fixture files under `tests/fixtures/` and never inlined into `@test "..."` descriptions, so the raw zero-match grep at the Phase-1 acceptance criterion passes without carve-out. Sequenced after T09 so the v0.7.3 self-host's own reviewers do not false-negative the sweep findings; the schema-migration mandatory-trio `structural_lint:` script (`scripts/structural-lints/check-bats-id-hygiene-sweep.sh`) is pre-committed at the repository root out-of-band of this plan, so the mandatory-trio existence check passes at plan-spec review time without a T39 dependency. |
| T12 | Create tests/lint/test-bats-test-name-id-hygiene.bats permanent CI lint | G2 | tdd | medium | ~50 | T11 | The lint greps every `@test` line under `tests/**/*.bats` and fails when a description matches a forbidden internal-ID or finding-ID token; an inline carve-out marker on a fixture-construction line inside a test body (only) exempts that body line from the lint match. |
| T13a | Promote implementer-protocol Pre-DONE self-check to blocking | G2 | lightweight | medium | ~20 | none | One anchor sentence promotes the Pre-DONE self-check from advisory to halt-DONE on any ID-hygiene match in added/modified `@test "..."` description strings. |
| T13b | Add revert-orchestration-drift fix-task mode to implementer-protocol with halt-on-conflict | G5 | lightweight | medium | ~25 | T19 | One new fix-task mode reverts non-subagent commits surfaced by the G5 boundary report after validating each SHA against the well-formed git object-name shape; on any single revert failure (conflict, merge-without-`-m`, deleted file) the subagent halts immediately, writes `orchestration-boundary-revert-failed.md`, and exits non-zero with skip-and-continue forbidden. |
| T14 | Create tests/unit/test-id-hygiene-lint-fail-direction.bats | G2 | tdd | low | ~30 | T12 | Drives the new lint against a generated fixture file under `tests/fixtures/` containing a forbidden internal-ID token and asserts non-zero exit with the documented diagnostic; the fixture file is generated by a test-body emit step (carrying the body-line carve-out marker) so the lint never sees the token in an `@test` description. |
| T15 | Add pre-fanout absorption-map anchor sentence to skills/plan/SKILL.md | G3 | lightweight | high | ~15 | T02 | The verbatim anchor sentence directs the plan-author to run `design-absorption-markers.sh`, ingest the redirect map, refuse standalone tasks for absorbed IDs, and halt with BLOCKED rather than manufacture a task home. |
| T16 | Append G3 rubric clauses to plan-spec and design reviewer agent bodies | G3 | lightweight | medium | ~50 | T02 | `agents/qrspi-plan-spec-reviewer.md` asserts no plan task carries an absorbed-goal ID; `agents/qrspi-design-reviewer.md` verifies the map preserves authorial intent across every entry. |
| T17a | Create tests/unit/test-plan-spec-reviewer-absorption.bats | G3 | tdd | medium | ~30 | T16, T02 | A synthetic plan.md drafted with an absorbed-ID task produces a `change_type: scope` finding from the plan-spec reviewer, and a Plan-step dispatch with `absorption_map_path:` absent halts non-zero with a `dispatch-defect:` named diagnostic. |
| T17b | Create tests/unit/test-design-reviewer-fidelity.bats | G3 | tdd | low | ~25 | T16, T02 | A synthetic design.md with an intent/marker contradiction produces a fidelity-mismatch finding from the design reviewer. |
| T17c | Create tests/unit/test-design-reviewer-dispatch-defect.bats | G3 | tdd | low | ~25 | T16, T02 | A Design-step dispatch with `absorption_map_path:` absent halts the reviewer non-zero with a `dispatch-defect:` named diagnostic instead of silently no-op'ing. |
| T18 | Create tests/lint/test-design-absorption-marker-set.bats structural lint | G3 | tdd | low | ~30 | T02 | Scan every `design.md` under `docs/qrspi/**/`; any absorption-shaped marker text MUST match one of the 4 enumerated patterns, and drift surfaces as a lint failure on the design.md PR. |
| T19 | Create scripts/orchestration-boundary-check.sh with per-phase phase-base dispatch, SHA-format validation, dispatch-defects section, and bats unit test | G5 | tdd | high | ~180 (sizing_exception: ci-scaffolding — full coverage matrix) | none | Phase-end script runs `git status --porcelain` (with `reviews/` tree excluded) and `git log <phase-base>..HEAD` post-filtered for non-`qrspi-` authors via the OBC author-marker filter; reads `<phase-base>` per `--phase` value (`implement` → G6 wave-1 sidecar; `integration`/`test` → `reviews/<phase>/phase-base.txt`), validates every SHA read from disk against the well-formed git object-name shape before any `git` invocation, and writes `reviews/<phase>/orchestration-boundary.md` with violations partitioned into a distinct `## Dispatch defects` section (missing/malformed phase-base.txt, malformed OBC author-name records) separate from the existing commit/workspace sections. |
| T19c | Create scripts/validate-stage-commit-parents.sh with --capture/--validate, SHA-format validation, and bats unit test | G6 | tdd | high | ~150 | none | `--capture` writes integration-base SHA + per-task-tip SHAs to a runtime sidecar under `reviews/implement/wave-state/`; `--validate` reads it (validating every SHA against the well-formed git object-name shape before any `git` invocation), reads actual parents from `git log --format='%P'`, asserts first-parent equality and task-tip set equality, halts non-zero with the named `stage-commit-parent-mismatch:` diagnostic on failure. The ID is T19c (not T25) to keep T20a's dependency on this primitive backward in numerical order — see Dependency graph. |
| T20a | Wrap Wave Dispatch merge step with stage-commit parent-validation calls in skills/implement/SKILL.md | G6 | lightweight | medium | ~40 | T19c | `skills/implement/SKILL.md` § Wave Dispatch step 6 wraps the existing `git merge --no-ff` with pre-merge `--capture` and post-merge `--validate` calls to `validate-stage-commit-parents.sh`. |
| T20b | Insert OBC step and interactive/autopilot batch-gate additions with dispatch-defect branch in skills/implement/SKILL.md | G5 | lightweight | medium | ~80 | T19 | A new Step-N orchestration-boundary observability block plus interactive/autopilot batch-gate additions land before the batch gate; the autopilot branched-default carries a third "Dispatch defects → halt unconditionally, write `HALT-orchestration-boundary-undeterminable.md`, exit autopilot loop" branch alongside the existing commit-based and uncommitted-workspace branches. |
| T21 | Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/integrate/SKILL.md | G5 | lightweight | medium | ~110 | T19, T04b | `skills/integrate/SKILL.md` carries the verbatim HARD-RULE section, the Step-N OBC check, the interactive/autopilot batch-gate additions, and a phase-start write of `reviews/integration/phase-base.txt` as the first orchestrator action of the phase (before any subagent dispatch). |
| T22 | Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/test/SKILL.md | G5 | lightweight | medium | ~110 | T19, T04b | `skills/test/SKILL.md` carries the verbatim HARD-RULE section (with the `reviews/test/round-NN-results.md` allowlisted-write exception), the Step-N OBC check, batch-gate additions, and a phase-start write of `reviews/test/phase-base.txt` as the first orchestrator action of the phase. |
| T23 | Insert cross-cutting Orchestration Boundary note in skills/using-qrspi/SKILL.md | G5 | lightweight | low | ~15 | T19 | The verbatim `### Orchestration Boundary applies to every phase` cross-cutting note lands in `using-qrspi/SKILL.md`, pointing readers at the per-phase prose. |
| T24 | Create tests/lint/test-integrate-test-skill-phase-base-write.bats | G5 | tdd | low | ~30 | T21, T22 | Anchor-phrase grep asserts `skills/integrate/SKILL.md` and `skills/test/SKILL.md` each carry the phase-base.txt write step at phase start, locking the write side against silent SKILL-prose drift that would break OBC integration/test read paths. |
| T24b | Create tests/lint/test-obc-script-absent-anchor.bats | G5 | tdd | low | ~30 | T20b, T21, T22 | Anchor-phrase grep asserts `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and `skills/test/SKILL.md` each carry the verbatim pre-invocation OBC-script-existence check that writes `obc-script-absent:` to `## Dispatch defects` and halts before invocation, locking the consumer-side script-absent dispatch-defect anchor against silent SKILL-prose drift. |
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
| T36 | Trim the 7 cross-cutting skills (integrate/test/implementer-protocol/reviewer-protocol/research-isolation/prompt-prose-writer/prompt-prose-reviewer) to target <300 lines each | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives (7-file bulk pass) | T07, T31, T13a, T13b, T21, T22 | Each cross-cutting SKILL applies the four-pass trim against its post-T13a/T13b/T21/T22 state (G2/G5/G2/G5 additions already in place); per-skill `references/<topic>.md` files are created at extract time. |
| T37 | Create scripts/measure-active-footprint.sh, run it against the trimmed tree, and write docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md | G9 | tdd | medium | ~120 | T32, T33, T34, T35, T36 | The measurement script resolves `!cat` references transitively (with cycle detection and named diagnostics for unresolvable references), tokenises with a pinned tokenizer (default `tiktoken:cl100k_base`), and emits a per-turn footprint count; the captured stdout is the body of `g9-footprint-report.md`. |
| T38 | Create tests/lint/test-skill-trim-audit.bats grep audit | G9 | tdd | low | ~35 | T32, T33, T34, T35, T36 | The lint asserts zero matches across all active SKILL.md files for `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, and `third-party.*splitter` (narrative restatements; concrete script names in process-step calls are fine). |
| T39 | Add tests/unit/test-check-bats-id-hygiene-sweep.bats — bats coverage for the pre-committed structural-lint script | G2 | tdd | low | ~30 | none | A bats test file exercising the pre-committed `scripts/structural-lints/check-bats-id-hygiene-sweep.sh` against fixture diffs (mechanical-only diff passes; body-content changes, non-`.bats` file changes outside `tests/fixtures/`, and empty diffs each exit non-zero with a named diagnostic). The script itself is pre-committed at the repository root out-of-band of this plan so the schema-migration mandatory-trio existence check passes at plan-spec review time; T39 adds CI coverage so the script's behaviour is locked against regressions. |

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
  T19c (validate-stage-commit-parents.sh — G6 primitive; ID kept numerically below T20a so T20a's dep on this primitive is backward)
  T26 (using-qrspi HEAD~1 → anchor-file lookup — G7 in-place edit)
  T28 (VERSION + build-plugin.mjs stamper — G8 primitive)
  T31 (skills/_shared/ snippets — G9 primitive)
  T39 (bats coverage for the pre-committed `check-bats-id-hygiene-sweep.sh` structural-lint script — G2; the script itself is pre-committed out-of-band so the schema-migration mandatory-trio existence check passes without a T11→T39 dependency)

CD-1 / G1 / G4 prerequisite chain (G1 → G2 gate):
  T01 → T09 (verifier rubric clause) → T10 (verifier bats)
  T01 → T11 (G2 sweep — fires after G1 verifier rubric lands; the structural-lint script is pre-committed out-of-band)
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
  T20b + T21 + T22 → T24b (OBC-script-absent anchor lint)

G6 / G7 paired round-mechanics surface:
  T19c → T20a (implement Wave Dispatch stage-commit-parents wrap)
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
- [ ] `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` returns zero matches AND `grep -rE '@test "[^"]*R[0-9]+-F[0-9]+' tests/**/*.bats` returns zero matches; `tests/lint/test-bats-test-name-id-hygiene.bats` rejects a synthetic regression PR that re-introduces either `[T99]` or `R99-F99` into an `@test "..."` description string (G2 — both `[Tnn]` and `R\d+-F\d+` token classes from goals.md G2 + design.md G2 Solution change 1 are explicitly audited).
- [ ] The v0.7.3 self-host Plan step round-01 produces zero plan-spec-reviewer absorption findings (meta-acceptance for G3).
- [ ] The v0.7.3 self-host Plan-step verifier dispatch carries a deterministic `upstream_paths` parameter equal to the fixture-expected set for `pipeline: full` (G4).
- [ ] The v0.7.3 self-host Integrate phase produces an empty `reviews/integration/orchestration-boundary.md`; every subagent commit in the integration-branch phase range carries the `qrspi-<agent>` author marker (G5). Missing/malformed `reviews/<phase>/phase-base.txt` at OBC time surfaces as a violation in a distinct `## Dispatch defects` section in the report and triggers the autopilot's unconditional dispatch-defect halt (G5 fail-loud branch, per design.md § G5 Solution (b) script-level exit non-zero + § Solution (c) autopilot dispatch-defects-first branch).
- [ ] The Implement-phase autopilot terminates the wave loop and writes `HALT-orchestration-boundary-undeterminable.md` when the OBC report carries any `## Dispatch defects` entry; no skip-and-continue path exists (G5, per design.md § G5 Solution (c) autopilot precedence ordering).
- [ ] Every Implement-wave stage commit in the v0.7.3 self-host passes `validate-stage-commit-parents.sh --validate` silently; `parallelization.md` is unchanged across the phase (G6).
- [ ] Every step-12 narrow-round dispatch across the v0.7.3 self-host resolves its diff ref by reading `reviews/<step>/round-<NN-1>-commit.txt` (G7).
- [ ] The plugin installs cleanly from the published `.claude-plugin/*` and `.github/plugin/*` manifests on a fresh Copilot CLI session (phasing.md § Phase 1 replan-gate criterion 2; G8 lockstep).
- [ ] `VERSION` is bumped exactly once to `0.7.3`, a single `node tools/build-plugin.mjs` invocation propagates to all five consumer manifests, and the `.github/workflows/build-then-diff.yml` CI gate passes on the release commit; `.github/plugin/*` stays in lockstep with `.claude-plugin/*` per `goals.md` § Constraints (G8).
- [ ] The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`) passes against the trimmed skill set with zero regressions (G9).
- [ ] `scripts/measure-active-footprint.sh` reports < 30K tokens per typical session, captured at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md` (G9).

### Project Environment Fields

- `build_command: 'none'` — qrspi-plus is a bash + agent-prose plugin with no per-task compile step. `tools/build-plugin.mjs` is invoked only at release time (G8's flow), not during per-task implementer verification.
- `dev_command:` omitted — no v0.7.3 task declares a `smoke_checks:` block (the release touches scripts, agent bodies, skill prose, lint tests, and the build script; no route / page / layout / user-facing-component surface is added or modified).

