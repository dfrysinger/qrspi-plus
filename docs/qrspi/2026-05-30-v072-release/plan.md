---
status: approved
phase_start_commit: 514a994072334add13ba70634ad840376d343696
test_writer_model: sonnet
---

# Implementation Plan

## Overview

v0.7.2 is a single-phase hardening drop against the deployed qrspi-plus v0.7.1 pipeline: 35 approved goals decomposed across seven vertical slices (1.1 through 1.7) into 38 tasks. Task numbering is sparse (1–44 with gaps at 18, 22, 23, 41, 42, 43); the gap dispositions differ — gap 18 (G25, absorbed by CD-1); gap 22 (G24-F02, defers to G25 → CD-1); gap 23 (G24-F03, moot after tree audit — duplication target never existed); gap 41 (G26, runtime concern already fixed pre-v0.7.2; BW02 regression-prevention rides on G21 in T40); gap 42 (G24-F01, moot after tree audit); gap 43 (G24-F04, moot after tree audit per design.md L2064 — old regex pattern no longer present at meaningful volume). G29 is also absorbed by CD-1 and ships no standalone task — T11 was repurposed to a CD-1 dispatch-manifest-provenance task under G3 rather than being deleted. See design.md ## G24/G25/G26/G29 for per-disposition rationales; numbering preserved for stable cross-references across rounds. The release ships cross-cutting fixes spanning four coherent surfaces — apply-fix / verifier backbone (1.1–1.2), per-task review pipeline (1.3), dispatch infrastructure (1.4), and skill-prose / structural / build hardening (1.5–1.7). Two cross-slice prerequisite chains perturb pure within-slice sequencing: (a) slice 1.4's `scripts/round-prepare.sh` (G4, T12) is consumed by slice 1.3 G9 (T13), so T12 is sequenced ahead of the slice 1.3 block; and (b) the round-02 repurposing of T11 to [G3] (CD-1 dispatch-manifest provenance) plus T09's `actual_model:` provenance edits and T13's per-task round-prepare edits all land before T20's G3 splitter rename (T09/T11/T13 → T20), so the pre-rename dispatch surface is fully provisioned before the script hard-rename collapses it. T11 remains numerically parked under Slice 1.2 by display position for cross-reference stability after the round-02 relabel — its dispatch-infrastructure work is Slice 1.4 surface and is sequenced via dep-graph item 4 below. Otherwise each slice's tasks chain only within-slice (schema → consumer → tests), and slice 1.7 build tooling is fully independent of slices 1.1–1.6 and can ship last in parallel.

## Phase 1: v0.7.2 release

Phase 1 is the whole release: all 35 goals, all seven slices, no future-phase content. Slice ordering and per-task ordering appear in the **Task List by Slice** section below.

### Phase 1 Acceptance Criteria

Per-phase criteria that must be observable end-to-end at phase boundary, independent of any single task. Each criterion is the cross-task observable behavior the Test phase verifies before the release PR opens:

- [ ] **End-to-end pipeline run on a non-trivial sample project completes Goals → Test cleanly with `verifier_enabled: true`, `scope_tagger_enabled: true`, and `second_reviewer: true`** — every review round dispatches per-finding sidecars on disk with valid `change_type` values, `scripts/verifier-fan-in.sh` produces the expected aggregate, second-reviewer (Codex) and Claude reviewer outputs both reliably persist across rounds, and no orchestrator chat-parsing fallback fires.
- [x] **Every fail-loud invariant in the release fires loud on a seeded regression input** — splitter on adversarial Codex stdout, dispatch on misrouted `model_routing` entries, validation table on missing `model_routing:`, `_resolve-lib.sh` halt when a CD-1 dispatch resolves to a `tier: none` configuration, `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt when `second_reviewer: true` resolves both reviewer slots to the same vendor, `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt when `second_reviewer: true` resolves to an unavailable vendor, `plan.md` post-approval split halt when a present per-task file's `# block-hash:` no longer matches its normalized source block, `scripts/verifier-fan-in.sh` halt with a matching `.verifier-fan-in-audit.json` cause for each documented malformation (missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, unparseable score), reviewer-protocol against fabricated procedural-authority outputs, the path-filter exfil guard in `scripts/dispatch-agent.sh`, and `tools/build-plugin.mjs` `resolves outside repository` halt when a `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape exfiltration surface), `tools/build-plugin.mjs` include-cycle halt with the full cycle printed, `tools/build-plugin.mjs` malformed `!cat` directive and missing-target halts with `file:line` diagnostics, and `tools/build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt when any built file under `build/` still contains the legacy resolver token each produce non-zero exit with a diagnostic, never silent fallback.
- [x] **Apply-fix sub-threshold observations and disposition instrumentation fire correctly** — a review round producing both above-threshold and sub-threshold findings emits the Sub-Threshold Observations block in dispositions, and the verifier rejects wholesale-hallucination findings on the calibration seeds for the substituted Codex model.
- [x] **Plugin build pipeline produces a reproducible release artifact** — `node tools/build-plugin.mjs` exits 0 against the v0.7.2 HEAD source tree, `git diff --exit-code build/ .claude-plugin/marketplace.json` is empty, the built `build/` tree omits all dev-only paths (`docs/`, `tools/`, `tests/`), all `!cat` directives are expanded, and `${CLAUDE_SKILL_DIR}` does not appear anywhere in the shipped tree.
- [x] **Full bats suite is green against deduplicated helpers and hardened anti-pattern pins** — `tests/lint/test-bats-body-assertion-guard.bats` catches body-less assertions on its seed regression, T40's seeded G21 violation and BW02 violation both produce non-zero lint exit with a `file:line` diagnostic, and T44's regex pins on `dispatch-routing`/`config-validation` continue to fire on their existing seed fixtures after the round-02 dep re-point.
- [ ] **Every v0.7.2-scoped GitHub issue closes or is explicitly deferred** — each of the 35 goal-backing parent issues closes when its backing commits land; each self-host-monitoring issue filed during the v0.7.2 run (currently #280–#288 + any filed during Plan/Implement/Test) either closes by commits landing in v0.7.2 or is documented in the release notes with a one-line v0.7.3+ deferral rationale.
- [ ] **Release PR opens against `main` with green CI and a canary smoke pass** — the PR contains the v0.7.2 commit set, CI is green (lint + unit + integration + acceptance + build-gate), the canary smoke against the built plugin succeeds, and release notes name each goal-backing issue's disposition.

(Per-task criteria live in each `tasks/task-NN.md`'s `## Test Expectations` block; the per-phase block above captures cross-task observable behavior at phase end.)

## Task List by Slice

Task numbers are globally sequential. Cross-slice dependency (Slice 1.4 G4 → Slice 1.3 G9) forces Task 12 (G4 cumulative diff helper) to land before the Slice 1.3 block — Slice 1.3's tasks are therefore numbered T13–T15 with T12 absent from its display block.

### Slice 1.1 — Apply-fix / verifier backbone

- **Task 01 — G7 verifier-filter-rule shared snippet** — goals: [G7] — deps: none — LOC: ~60 — task_type: lightweight — model: sonnet
- **Task 02 — G12 verifier-fan-in script with dispatch-prose include** — goals: [G12] — deps: none — LOC: ~180 — task_type: code — model: opus
- **Task 03 — G6 reviewer disk-write contract across first-party and third-party emission paths** — goals: [G6] — deps: [Task 01] — LOC: ~150 — task_type: code — model: opus
- **Task 04 — G8 reviewer frontmatter emits `change_type` not `category`** — goals: [G8] — deps: [Task 03] — LOC: ~90 — task_type: code — model: opus
- **Task 05 — G13 `change_type` enum drift hardening on both reviewer-emit and orchestrator-consume sides** — goals: [G13] — deps: [Task 02, Task 04] — LOC: ~110 — task_type: code — model: opus
- **Task 06 — G11 verifier sidecar extension correction and orchestrator-bypass fix** — goals: [G11] — deps: [Task 02] — LOC: ~80 — task_type: code — model: sonnet
- **Task 07 — G14 verifier rubric correction for `Informational` findings** — goals: [G14] — deps: [Task 06] — LOC: ~100 — task_type: code — model: opus

### Slice 1.2 — Verifier rubric calibration + instrumentation

- **Task 08 — G19 verifier wholesale-hallucination rubric class** — goals: [G19] — deps: [Task 07] — LOC: ~120 — task_type: code — model: sonnet
- **Task 09 — G20 reviewer-model calibration for task-tool-substituted Codex model** — goals: [G20] — deps: [Task 08] — LOC: ~160 — task_type: code — model: opus
- **Task 10 — G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation** — goals: [G28] — deps: [Task 09] — LOC: ~150 — task_type: code — model: opus
- **Task 11 — G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file` in `.dispatch-manifest.json`)** — goals: [G3] — deps: none — LOC: ~110 — task_type: code — model: sonnet — *Note: relabeled from [G29] to [G3] in round-02; the work is Slice 1.4 dispatch-infrastructure surface but T11 remains parked here numerically for cross-reference stability.*

### Slice 1.3 — Per-task review pipeline corrections

(Task 12 — G4 cumulative diff helper — appears under Slice 1.4 below; Slice 1.3 G9 consumes the helper script G4 creates, so G4 is sequenced ahead of this block.)

- **Task 13 — G9 per-task review orchestration fires scope-tagger, `round-NN.diff`, and `round-NN-commit.txt` artifacts** — goals: [G9] — deps: [Task 12] — LOC: ~120 — task_type: code — model: opus
- **Task 14 — G15 Plan sweep-task contract with dependent-test scope** — goals: [G15] — deps: none — LOC: ~110 — task_type: code — model: opus
- **Task 15 — G18 Plan cross-task consumer surface** — goals: [G18] — deps: [Task 14] — LOC: ~130 — task_type: code — model: opus

### Slice 1.4 — Dispatch infrastructure

- **Task 12 — G4 canonical cumulative diff helper (`round-prepare.sh` + `await-round.sh` + section-anchor manifest + per-skill anchors JSON)** — goals: [G4] — deps: none — LOC: ~280 — sizing_exception: reusable primitives — task_type: code — model: opus
- **Task 16 — G22 `model_routing` config schema and agent-sweep migration** — goals: [G22] — deps: none — LOC: ~320 — sizing_exception: schema-migration — task_type: code — model: opus
- **Task 17 — G23 validation table covers `model_routing` and cross-links fail-loud paragraphs** — goals: [G23] — deps: [Task 16] — LOC: ~80 — task_type: code — model: opus
- **Task 19 — G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration** — goals: [G27] — deps: [Task 16] — LOC: ~210 — sizing_exception: reusable primitives — task_type: code — model: opus
- **Task 20 — G3 dispatch-script rename collapse (`run-codex-review.sh` → `dispatch-agent.sh`; `run-third-party-llm.sh` → `dispatch-companion.sh`; `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`) and per-skill prose migration** — goals: [G3] — deps: [Task 09, Task 11, Task 12, Task 13, Task 19] — LOC: ~260 — sizing_exception: reusable primitives — task_type: code — model: opus
- **Task 21 — G16 path-filter exfil hardening in `dispatch-agent.sh`** — goals: [G16] — deps: [Task 20] — LOC: ~120 — task_type: code — model: opus
- **Task 24 — CD-4 `detect-interaction-mode.sh` helper** — goals: [G6, G11, G12] — deps: [Task 02] — LOC: ~110 — task_type: code — model: sonnet

### Slice 1.5 — Skill prose & interactive dialog quality

- **Task 25 — G31 prompt-prose primitives (`prompt-prose-detection` + `-writer-addition` + `-reviewer-addition` + `prompt-design-rules` + new prompt-prose-writer SKILL + new prompt-prose-reviewer SKILL + docs rename)** — goals: [G31] — deps: none — LOC: ~340 — sizing_exception: reusable primitives — task_type: lightweight — model: sonnet
- **Task 26 — G31 prompt-prose include sites across Design, Plan, and reviewer agents** — goals: [G31] — deps: [Task 25] — LOC: ~140 — task_type: lightweight — model: sonnet
- **Task 27 — CD-2 evergreen-output-rule shared snippet and include sites** — goals: [G3, G4, G22, G27] — deps: none — LOC: ~120 — task_type: lightweight — model: sonnet
- **Task 28 — CD-3 multi-actor-flow-check shared snippet and include sites** — goals: [G1, G30, G33] — deps: none — LOC: ~110 — task_type: lightweight — model: sonnet
- **Task 29 — G34 Design scope-reviewer alignment with detailed-solution boundary (design-altitude-boundary primitive + scope-reviewer + owns-defers)** — goals: [G34] — deps: none — LOC: ~150 — task_type: lightweight — model: sonnet
- **Task 30 — G1 Design phase decision-completeness template** — goals: [G1] — deps: [Task 29] — LOC: ~160 — task_type: lightweight — model: sonnet
- **Task 31 — G33 Design skill interactive dialog clarity** — goals: [G33] — deps: [Task 30] — LOC: ~90 — task_type: lightweight — model: sonnet
- **Task 32 — G30 Goals and Design dialogue authoring quality and compaction-resilient incremental persistence** — goals: [G30] — deps: [Task 30, Task 31] — LOC: ~180 — task_type: code — model: opus
- **Task 33 — G2 Plan schema-migration task shape** — goals: [G2] — deps: none — LOC: ~80 — task_type: lightweight — model: sonnet
- **Task 34 — G5 Plan post-approval split idempotency** — goals: [G5] — deps: none — LOC: ~110 — task_type: code — model: sonnet
- **Task 35 — G10 reviewer-protocol anti-fabrication hardening** — goals: [G10] — deps: [Task 03] — LOC: ~100 — task_type: code — model: opus
- **Task 36 — G17 implementer-protocol and test-writer stale-prose cleanup** — goals: [G17] — deps: none — LOC: ~70 — task_type: lightweight — model: sonnet

### Slice 1.6 — Structure SKILL absorbs unified architecture

- **Task 37 — G35 Structure SKILL absorbs unified architecture content with `structure-altitude-boundary` primitive** — goals: [G35] — deps: [Task 29] — LOC: ~190 — task_type: lightweight — model: sonnet
- **Task 38 — G35 Structure reviewers (artifact + scope) enforce architecture-only-in-structure boundary** — goals: [G35] — deps: [Task 37] — LOC: ~120 — task_type: lightweight — model: sonnet

### Slice 1.7 — Build & release tooling + test-infrastructure hardening

- **Task 39 — G32 plugin build pipeline (`tools/build-plugin.mjs` + `render-skill.sh` + `g4-section-anchor-refresh.sh` + marketplace.json + CI workflow + CONTRIBUTING)** — goals: [G32] — deps: [Task 21, Task 25] — LOC: ~360 — sizing_exception: CI scaffolding — task_type: code — model: opus
- **Task 40 — G21 bats short-circuit hardening with body-assertion-guard lint (incl. G26 BW02/minimum-version rule)** — goals: [G21, G26] — deps: none — LOC: ~140 — task_type: code — model: sonnet
- **Task 44 — G24-F05 anti-pattern pin regex hardening** — goals: [G24] — deps: [Task 17, Task 40] — LOC: ~80 — task_type: code — model: sonnet

### Dependency Graph

Three cross-slice dependency clusters dominate the graph; everything else is within-slice ordering of primitives → consumers → tests.

1. **G4 cumulative diff helper (Slice 1.4) → G9 per-task review (Slice 1.3).** `scripts/round-prepare.sh` and `scripts/await-round.sh` are created in Task 12 (Slice 1.4) but consumed by Task 13 (Slice 1.3 G9), so Task 12 is sequenced ahead of the 1.3 block in the global numbering. This is the only cross-slice forward dep that perturbs slice ordering.

2. **G22 model_routing schema (Slice 1.4) → G23 validation table.** Both touch `skills/using-qrspi/SKILL.md` and `config.md`; sequential ordering within Slice 1.4 prevents merge conflicts on the shared edit surface and ensures the validation table covers the new schema before fail-loud paragraphs reference it. (Note: G24-F02 prose consolidation and G25 top-level invariant — originally planned as T22 / T18 in this chain — were dropped per design.md ## G24 and ## G25 absorbing those goals into CD-1 with no separate v0.7.2 task.)

3. **G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7).** G16 edits `scripts/dispatch-agent.sh` (the renamed file from G3); G32's `build/` allow-list and `!cat` resolver inspect every shipped script under its new name, so G32 lands after G3 + G16 are merged.

4. **G20 `actual_model:` provenance (T09) + G3 dispatch-manifest provenance (T11) + G9 per-task round-prepare edits (T13) → G3 splitter rename (T20).** T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; `scripts/round-prepare.sh` for T13); T20 hard-renames those files and migrates the 12 consumer SKILLs. Sequencing T09/T11/T13 ahead of T20 prevents the rename from clobbering in-flight provenance edits and prevents T20 from leaving stale pre-rename caller paths behind.

Within-slice chains worth noting: G31 primitives (T25) before all G31 consumer sites (T26) and before G32 (T39 needs the `prompt-prose-detection.md` defensive-copy site to exist); G34 design-altitude-boundary (T29) before G35 structure-altitude-boundary (T37) so the two altitude primitives are reviewed against a shared template; G1 (T30) before G33 (T31) before G30 (T32) to serialize the three design/SKILL.md edits and prevent same-paragraph conflicts. Slice 1.7 G21+G26 (T40) → G24-F05 (T44) is a short test-infrastructure chain (T40 lands the lint file and BW02 rule; T44 hardens the regex pins against the post-G22/G23 dispatch-routing wording).

Slice 1.1 → Slice 1.2 is a soft chain (Slice 1.2 verifier rubric work assumes the Slice 1.1 verifier sidecar/`change_type` foundation is in place). Slice 1.6 depends on Slice 1.5's G34 (shared altitude-boundary pattern). Slice 1.7 is otherwise independent of Slices 1.1–1.6 except that T39 depends on T25 for the defensive-copy site and on T21 for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection.

### Project Environment Fields

- `build_command: node tools/build-plugin.mjs` — invoked by the implementer gate at per-task verification (matches the CI gate G32 establishes; the script exits 0 when the source tree is well-formed and `build/` is reproducible from source).
- `dev_command: 'none'` — qrspi-plus is a plugin (no dev server). CLI testing for this repo is via the bats suite (`bats tests/`) and direct skill invocation through the host CLI; no smoke-check gate fires, so `dev_command` is intentionally absent.

## Task Specs

Task specifications have been split into per-task files under `tasks/task-NN.md` (see post-approval-split-contract.md). Refer to those files for full specs.

