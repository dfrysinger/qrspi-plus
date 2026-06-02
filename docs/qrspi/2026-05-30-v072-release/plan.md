---
status: draft
phase_start_commit: null
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
- [ ] **Every fail-loud invariant in the release fires loud on a seeded regression input** — splitter on adversarial Codex stdout, dispatch on misrouted `model_routing` entries, validation table on missing `model_routing:`, `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an unknown vendor, reviewer-protocol against fabricated procedural-authority outputs, and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, never silent fallback.
- [ ] **Apply-fix sub-threshold observations and disposition instrumentation fire correctly** — a review round producing both above-threshold and sub-threshold findings emits the Sub-Threshold Observations block in dispositions, and the verifier rejects wholesale-hallucination findings on the calibration seeds for the substituted Codex model.
- [ ] **Plugin build pipeline produces a reproducible release artifact** — `node tools/build-plugin.mjs` exits 0 against the v0.7.2 HEAD source tree, `git diff --exit-code build/ .claude-plugin/marketplace.json` is empty, the built `build/` tree omits all dev-only paths (`docs/`, `tools/`, `tests/`), all `!cat` directives are expanded, and `${CLAUDE_SKILL_DIR}` does not appear anywhere in the shipped tree.
- [ ] **Full bats suite is green against deduplicated helpers and hardened anti-pattern pins** — `tests/lint/test-bats-body-assertion-guard.bats` catches body-less assertions on its seed regression, T40's seeded G21 violation and BW02 violation both produce non-zero lint exit with a `file:line` diagnostic, and T44's regex pins on `dispatch-routing`/`config-validation` continue to fire on their existing seed fixtures after the round-02 dep re-point.
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
- **Task 19 — G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration** — goals: [G27] — deps: none — LOC: ~210 — sizing_exception: reusable primitives — task_type: code — model: opus
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

- **Task 39 — G32 plugin build pipeline (`tools/build-plugin.mjs` + `render-skill.sh` + `g4-section-anchor-refresh.sh` + marketplace.json + CI workflow + CONTRIBUTING)** — goals: [G32] — deps: [Task 25] — LOC: ~360 — sizing_exception: CI scaffolding — task_type: code — model: opus
- **Task 40 — G21 bats short-circuit hardening with body-assertion-guard lint (incl. G26 BW02/minimum-version rule)** — goals: [G21, G26] — deps: none — LOC: ~140 — task_type: code — model: sonnet
- **Task 44 — G24-F05 anti-pattern pin regex hardening** — goals: [G24] — deps: [Task 17, Task 40] — LOC: ~80 — task_type: code — model: sonnet

### Dependency Graph

Three cross-slice dependency clusters dominate the graph; everything else is within-slice ordering of primitives → consumers → tests.

1. **G4 cumulative diff helper (Slice 1.4) → G9 per-task review (Slice 1.3).** `scripts/round-prepare.sh` and `scripts/await-round.sh` are created in Task 12 (Slice 1.4) but consumed by Task 13 (Slice 1.3 G9), so Task 12 is sequenced ahead of the 1.3 block in the global numbering. This is the only cross-slice forward dep that perturbs slice ordering.

2. **G22 model_routing schema (Slice 1.4) → G23 validation table.** Both touch `skills/using-qrspi/SKILL.md` and `config.md`; sequential ordering within Slice 1.4 prevents merge conflicts on the shared edit surface and ensures the validation table covers the new schema before fail-loud paragraphs reference it. (Note: G24-F02 prose consolidation and G25 top-level invariant — originally planned as T22 / T18 in this chain — were dropped per design.md ## G24 and ## G25 absorbing those goals into CD-1 with no separate v0.7.2 task.)

3. **G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7).** G16 edits `scripts/dispatch-agent.sh` (the renamed file from G3); G32's `build/` allow-list and `!cat` resolver inspect every shipped script under its new name, so G32 lands after G3 + G16 are merged.

4. **G20 `actual_model:` provenance (T09) + G3 dispatch-manifest provenance (T11) + G9 per-task round-prepare edits (T13) → G3 splitter rename (T20).** T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; `scripts/round-prepare.sh` for T13); T20 hard-renames those files and migrates the 12 consumer SKILLs. Sequencing T09/T11/T13 ahead of T20 prevents the rename from clobbering in-flight provenance edits and prevents T20 from leaving stale pre-rename caller paths behind.

Within-slice chains worth noting: G31 primitives (T25) before all G31 consumer sites (T26) and before G32 (T39 needs the `prompt-prose-detection.md` defensive-copy site to exist); G34 design-altitude-boundary (T29) before G35 structure-altitude-boundary (T37) so the two altitude primitives are reviewed against a shared template; G1 (T30) before G33 (T31) before G30 (T32) to serialize the three design/SKILL.md edits and prevent same-paragraph conflicts. Slice 1.7 G21+G26 (T40) → G24-F05 (T44) is a short test-infrastructure chain (T40 lands the lint file and BW02 rule; T44 hardens the regex pins against the post-G22/G23 dispatch-routing wording).

Slice 1.1 → Slice 1.2 is a soft chain (Slice 1.2 verifier rubric work assumes the Slice 1.1 verifier sidecar/`change_type` foundation is in place). Slice 1.6 depends on Slice 1.5's G34 (shared altitude-boundary pattern). Slice 1.7 is otherwise independent of Slices 1.1–1.6 (only T39 depends on T25 for the defensive-copy site).

### Project Environment Fields

- `build_command: node tools/build-plugin.mjs` — invoked by the implementer gate at per-task verification (matches the CI gate G32 establishes; the script exits 0 when the source tree is well-formed and `build/` is reproducible from source).
- `dev_command: 'none'` — qrspi-plus is a plugin (no dev server). CLI testing for this repo is via the bats suite (`bats tests/`) and direct skill invocation through the host CLI; no smoke-check gate fires, so `dev_command` is intentionally absent.

## Task Specs

### Task 01: G7 verifier-filter-rule shared snippet

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G7]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** skills/_shared/verifier-filter-rule.md (create)
- **Dependencies:** none. **Blocks:** [Task 03] (reviewer disk-write contract work is ordered after this shared snippet).
- **LOC estimate:** ~60

**Overview**

Create the shared verifier-filter-rule snippet consumed by orchestrator prose so the filter boundary is visible at point of use without copying numeric threshold values into loaded skill text. The snippet makes `scripts/verifier-fan-in.sh` header constants the authoritative threshold source and gives downstream consumers a single reusable statement instead of another drift-prone paraphrase. (Why: see goals.md ### G7. Approach: see design.md ## G7 and design.md ### CD-4.)

**Scope**

- **In:**
  - Create `skills/_shared/verifier-filter-rule.md` with a `## Verifier Filter Rule` section.
  - State, in one short canonical passage, that verifier fan-in filters findings according to script-owned header constants and that consumers read the kept set produced by the fan-in flow.
  - Explicitly point consumers to `scripts/verifier-fan-in.sh` header constants for current filter floors while keeping numeric threshold values out of the snippet.
  - Apply R1-R7 plus the cross-cutting prompt-design principles from `skills/_shared/prompt-design-rules.md` to keep the snippet concise, reusable, positive, and load-bearing.

- **Out:**
  - Implementing `scripts/verifier-fan-in.sh` and the verifier-dispatch prose snippet — T02 owns.
  - Updating reviewer emission contracts, sidecar formats, or `change_type` schema enforcement — T03-T05 own those downstream surfaces.
  - Rewriting loaded consumer skill prose or adding `!cat` include sites beyond this new snippet file — downstream consumer tasks own those modifications.

**Definition of done**

- `skills/_shared/verifier-filter-rule.md` exists and contains exactly one `## Verifier Filter Rule` section.
- The snippet contains no inline numeric threshold values for the verifier filter floors.
- The snippet names `scripts/verifier-fan-in.sh` header constants as the authoritative source for current filter floors.
- The snippet explains the script-owned filter boundary clearly enough that consumers do not need to restate threshold values in loaded orchestrator prose.
- The snippet remains a short canonical reusable statement, not a historical explanation or duplicated apply-fix procedure.
- The text satisfies the applicable prompt-design rules: concise wording, shared-spine/reference discipline, anchor-phrase use, positive substitute, and load-bearing-rule clarity.

**Test expectations**

- File-existence check for `skills/_shared/verifier-filter-rule.md`.
- Grep check confirms a `## Verifier Filter Rule` heading exists in the snippet.
- Grep audit confirms verifier floor numerals are absent from the snippet while `scripts/verifier-fan-in.sh` and `header constants` are present.
- Prompt-design review applies R1-R7 plus cross-cutting principles from `skills/_shared/prompt-design-rules.md` and verifies the snippet is one concise canonical statement, not duplicated consumer prose.
- Anchor-phrase audit confirms the snippet directs readers to `scripts/verifier-fan-in.sh` header constants rather than restating current threshold values.

**References**

- goals.md ### G7 — problem framing for verifier threshold drift and missing point-of-use rule visibility.
- design.md ## G7 — chosen approach: script-owned threshold source and short pointer prose.
- design.md ### CD-4 → F / G7 acceptance — fan-in pipeline, orchestrator-side prose collapse, and no-threshold-in-skills acceptance checks.
- structure.md ### `skills/_shared/verifier-filter-rule.md` — per-file responsibility, required heading, no-inline-threshold constraint, and anchor pointer phrase.

### Task 02: G12 verifier-fan-in script with dispatch-prose include

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G12]
- **Task type:** code
- **Model:** opus
- **Target files:** scripts/verifier-fan-in.sh (create), skills/_shared/verifier-dispatch-prose.md (create)
- **Dependencies:** none. **Blocks:** Task 05 (G13 enum hardening on `scripts/verifier-fan-in.sh`), Task 06 (G11 verifier sidecar extension lock), Task 24 (CD-4 interaction-mode helper).
- **LOC estimate:** ~180

**Overview**

Create the deterministic verifier fan-in primitive and the shared verifier-dispatch prose snippet so apply-fix consumes disk-written verifier sidecars through `kept-findings.txt` instead of chat-parsed verifier output. The script owns the kept-set decision and audit trail; the snippet gives artifact-level and task-level consumers one includeable dispatch sequence without duplicating per-finding loop prose. (Why: see goals.md ### G12. Approach: see design.md ## G12 and design.md ### CD-4.)

**Scope**

- **In:**
  - Create `scripts/verifier-fan-in.sh` to enumerate `<round-dir>/*.finding-F*.md`, validate each finding's `change_type:`, locate the paired `<reviewer-tag>.finding-F<NN>.score.md` sidecar, parse `score:`, apply the script-owned threshold rule, and emit the canonical kept set.
  - Write `kept-findings.txt` as one absolute kept finding-file path per line and `.verifier-fan-in-audit.json` with scored, kept, dropped, halt, and threshold data.
  - Fail loudly with a non-zero exit and audit halt record for missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, or unparseable score.
  - Create `skills/_shared/verifier-dispatch-prose.md` with the single `dispatch-agent.sh --verifier-fanout` invocation, one Task call per emitted spec line using the referenced dispatch file verbatim, `await-round.sh`, and the subsequent `scripts/verifier-fan-in.sh <round-dir>` invocation.
  - Preserve the singleton verifier tier-override shape and keep verifier payload prose out of orchestrator stdout/stderr.

- **Out:**
  - `change_type` enum drift hardening across reviewer emission and fan-in consumption — Task 05 owns.
  - Verifier-agent sidecar path/extension instruction updates — Task 06 owns.
  - Interaction-mode detection and rescue/escalation helper behavior for CD-4 halt handling — Task 24 owns.
  - Adding `!cat` include sites to consumer skill files — outside this task's target files; this task authors the includeable shared snippet only.

**Definition of done**

- `scripts/verifier-fan-in.sh` exists and accepts a round directory argument for the fan-in pass.
- A well-formed round exits 0, writes `kept-findings.txt` containing only absolute paths for kept finding files, and writes `.verifier-fan-in-audit.json` with scored, kept, dropped, empty `halts`, and threshold data.
- Findings below the configured floors for `style`, `clarity`, and `correctness` are dropped; `scope` and `intent` findings are kept without score-threshold filtering.
- Missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score each exit non-zero and record the matching halt cause in `.verifier-fan-in-audit.json`.
- `skills/_shared/verifier-dispatch-prose.md` documents exactly one verifier fan-out dispatch sequence: `dispatch-agent.sh --verifier-fanout`, one Task call per emitted spec line using `DISPATCH_FILE=<absolute-path-from-PROMPT_FILE>`, `await-round.sh`, then `scripts/verifier-fan-in.sh <round-dir>`.
- The shared snippet does not echo verifier payloads, does not restate per-finding verifier loops, and uses a bare `<tier>` for verifier `--tier-override` rather than the reviewer CSV grammar.

**Test expectations**

- Run a well-formed fixture round and verify exit 0, `kept-findings.txt` absolute-path contents, and `.verifier-fan-in-audit.json` counts/thresholds with `halts: []`.
- Run threshold fixtures proving below-floor `style`, `clarity`, and `correctness` findings are dropped while `scope` and `intent` findings are not threshold-filtered.
- Run malformed fixture rounds for missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score; each must exit non-zero and write the matching audit halt cause.
- Inspect `skills/_shared/verifier-dispatch-prose.md` for the required `dispatch-agent.sh --verifier-fanout` invocation, one-Task-per-spec-line contract, `await-round.sh` follow-up, and fan-in invocation.
- Grep the shared snippet to confirm it contains no verifier payload echoing, no inline per-finding verifier loop, and no reviewer-style `tag=tier` tier-override grammar.

**References**

- goals.md ### G12 — problem framing for replacing chat-parsed verifier sidecars with an automated fan-in consumer.
- design.md ## G12 — declares the CD-4 verifier-fan-in pipeline as the resolution and names the script as canonical filter.
- design.md ### CD-4 — end-to-end reviewer → verifier → sidecar → fan-in → kept-findings flow, component C script behavior, component H dispatch snippet behavior, and G12 acceptance.
- structure.md ### `scripts/verifier-fan-in.sh` — per-file block for the script interface, audit schema, halt causes, and threshold/filter responsibilities.
- structure.md ### `skills/_shared/verifier-dispatch-prose.md` — per-file block for the shared verifier-dispatch prose contents and constraints.
- structure.md ### CD-4 / G12 verifier-dispatch-prose `!cat` include sites — downstream consumer placement context for the shared snippet.

### Task 03: G6 reviewer disk-write contract across first-party and third-party emission paths

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G6]
- **Task type:** code
- **Model:** opus
- **Target files:** skills/reviewer-protocol/SKILL.md (modify), skills/reviewer-protocol/first-party-emission.md (create), skills/reviewer-protocol/third-party-emission.md (create), tests/unit/test-per-finding-file-emission.bats (modify)
- **Dependencies:** Task 01. **Blocks:** [Task 04, Task 35] (both modify `skills/reviewer-protocol/SKILL.md` after the G6 protocol split lands).
- **LOC estimate:** ~150

**Overview**

Split reviewer emission guidance into an emission-agnostic reviewer protocol plus first-party and third-party emission contracts, so every reviewer path has one authoritative output channel and wrong-channel output fails loudly instead of masquerading as a clean round. This task pins the file-contract layer in unit coverage while preserving the existing transport-neutral schema and routing content in the protocol core. (Why: see goals.md ### G6. Approach: see design.md ## G6.)

**Scope**

- **In:**
  - Modify `skills/reviewer-protocol/SKILL.md` so it retains only emission-agnostic protocol content: finding schema, classifier, untrusted-data handling, phase routing, dispatch contract, and untrusted scope-hint guidance.
  - Create `skills/reviewer-protocol/first-party-emission.md` with the first-party Write-tool contract, required per-finding paths, clean sentinel path, path rules, and wrong-channel failure surface.
  - Create `skills/reviewer-protocol/third-party-emission.md` with the third-party stdout-boundary contract, `NO_FINDINGS` sentinel, splitter materialization requirements, and wrong-channel failure surface.
  - Modify `tests/unit/test-per-finding-file-emission.bats` to pin the on-disk shape, clean sentinel, third-party materialization, no-findings sentinel, and wrong-channel diagnostic behavior.

- **Out:**
  - Creating `scripts/detect-interaction-mode.sh` and host interaction-mode detection tests — T24 owns.
  - Changing reviewer frontmatter from `category` to `change_type` or partition-routing behavior — T04 owns after this protocol split.
  - Adding the reviewer-protocol anti-fabrication fail-loud rule and acceptance coverage — T35 owns after this protocol split.
  - Modifying dispatch architecture, host/vendor routing, or model-routing tiers — outside this task's target files.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains no emission-contract prose requiring the Write tool or stdout emission; it keeps only the transport-neutral protocol surfaces named above.
- `skills/reviewer-protocol/first-party-emission.md` exists with sections for the first-party emission contract, Write-tool requirements, and path rules.
- The first-party contract requires `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` per finding or `<round_subdir>/<reviewer_tag>.clean.md` for zero findings, and states that any other channel produces zero findings for that tag with the expected loud failure surface.
- `skills/reviewer-protocol/third-party-emission.md` exists with sections for the third-party emission contract, stdout boundary, and splitter requirements.
- The third-party contract requires `<<<FINDING-BOUNDARY>>>` blocks or literal `NO_FINDINGS` on stdout, states that `third-party-finding-splitter.sh` materializes on-disk files, and does not use the word `override` in prose.
- `tests/unit/test-per-finding-file-emission.bats` covers per-finding files, the clean sentinel, third-party boundary materialization, the no-findings sentinel, and wrong-channel output reporting `expected tag produced no output` rather than silently passing.
- Protocol-surface regression checks confirm no pre-rename references to `run-codex-review`, `codex-emission-override`, or `codex-finding-splitter` remain in `skills/reviewer-protocol/SKILL.md`.

**Test expectations**

- Grep audit of `skills/reviewer-protocol/SKILL.md` confirms emission-contract matches for Write-tool or stdout instructions are absent from the core protocol.
- File-existence checks confirm both `skills/reviewer-protocol/first-party-emission.md` and `skills/reviewer-protocol/third-party-emission.md` exist.
- Section-heading checks confirm `first-party-emission.md` includes first-party contract, Write-tool requirements, and path-rules sections, and `third-party-emission.md` includes third-party contract, stdout-boundary, and splitter-requirements sections.
- Path/sentinel grep checks confirm the first-party file names `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` and `<round_subdir>/<reviewer_tag>.clean.md`, while the third-party file names `<<<FINDING-BOUNDARY>>>`, `NO_FINDINGS`, and `third-party-finding-splitter.sh`.
- Grep audit confirms `skills/reviewer-protocol/third-party-emission.md` prose does not contain the word `override`.
- `tests/unit/test-per-finding-file-emission.bats` asserts per-finding file paths, the clean sentinel, third-party boundary materialization, the no-findings sentinel, and wrong-channel emission reporting `expected tag produced no output`.
- Rename-surface grep confirms `skills/reviewer-protocol/SKILL.md` has no `run-codex-review`, `codex-emission-override`, or `codex-finding-splitter` matches.

**References**

- goals.md ### G6 — problem framing for reviewer disk-write contract failures and chat-only reviewer output under task-tool transport.
- design.md ## G6 — selected solution: emission-agnostic protocol core plus first-party and third-party emission siblings with iron-law wrong-channel clauses.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — per-file responsibility for stripping emission prose and retaining only transport-neutral protocol content.
- structure.md ### `skills/reviewer-protocol/first-party-emission.md` — first-party Write-tool contract, path rules, and iron-law insertion source.
- structure.md ### `skills/reviewer-protocol/codex-emission-override.md` → `skills/reviewer-protocol/third-party-emission.md` — verified rename block for the third-party stdout-boundary contract and splitter requirements.
- structure.md ### `tests/unit/test-per-finding-file-emission.bats` — unit coverage surface for per-finding files, clean sentinel, third-party materialization, and wrong-channel failure reporting.

### Task 04: G8 reviewer frontmatter emits `change_type` not `category`

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G8]
- **Task type:** code
- **Model:** opus
- **Target files:** skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
- **Dependencies:** Task 03. **Blocks:** T05 (G13 enum drift hardening consumes the missing-field behavior and shared test surface introduced here).
- **LOC estimate:** ~90

**Overview**

Centralize `change_type:` as the required reviewer finding-file frontmatter key in the reviewer protocol, then pin the field-name contract with regression coverage so `category:` cannot be accepted or silently default-routed. This protects verifier fan-in, scope routing, and apply-fix behavior from the G8 field-name drift while leaving enum hardening to the dependent task. (Why: see goals.md ### G8. Approach: see design.md ## G8 and design.md ### CD-4.)

**Scope**

- **In:**
  - Update `skills/reviewer-protocol/SKILL.md` so the required finding-file frontmatter schema names `change_type:` and does not present `category:` as an allowed synonym.
  - Add regression coverage in `tests/unit/test-change-type-partition.bats` for a finding file that has `category:` but no `change_type:`, asserting it is malformed with a missing-field diagnostic rather than accepted or silently routed.
  - Add/keep coverage in `tests/unit/test-change-type-partition.bats` for a well-formed finding with `change_type:`, asserting acceptance and routing by that field name.
  - Audit the touched protocol examples and test fixtures so valid finding-frontmatter examples do not use `category:`.

- **Out:**
  - Out-of-enum `change_type:` validation, canonical enum drift hardening, and script/protocol enum lock-step — T05 owns.
  - Creating or expanding `scripts/verifier-fan-in.sh` beyond the missing-field behavior exercised by this task — T05 owns the dependent script-side enum hardening surface.
  - Editing individual reviewer agent bodies or transport-specific emission files beyond the central reviewer-protocol contract — outside this task's target-file set.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` documents `change_type:` as the required finding-file frontmatter key for reviewer findings.
- `skills/reviewer-protocol/SKILL.md` does not describe `category:` as an accepted alias or synonym for `change_type:`.
- `tests/unit/test-change-type-partition.bats` contains a failing-first fixture/assertion where `category:` without `change_type:` produces a missing-field diagnostic and is not accepted, silently kept, silently dropped, or default-routed.
- `tests/unit/test-change-type-partition.bats` asserts a well-formed finding with `change_type:` is accepted and routed by the `change_type:` field name.
- Repository search over reviewer-output schema examples and test fixtures in the touched files finds no valid finding-frontmatter example using `category:`.

**Test expectations**

- Run the targeted `tests/unit/test-change-type-partition.bats` test and confirm the missing-`change_type:` / legacy-`category:` fixture fails loudly with the expected missing-field diagnostic.
- Run the same targeted test and confirm the well-formed `change_type:` fixture is accepted and routed by that field name.
- Grep `skills/reviewer-protocol/SKILL.md` for the required `change_type:` schema wording and verify no nearby protocol wording permits `category:` as an alias.
- Grep `skills/reviewer-protocol/SKILL.md` and `tests/unit/test-change-type-partition.bats` for valid finding-frontmatter examples using `category:`; the audit must find none.

**References**

- goals.md ### G8 — problem framing for reviewer findings drifting from schema-required `change_type:` to free-text `category:`.
- design.md ## G8 — CD-4 resolution summary: centralize `change_type:` in reviewer protocol and halt with a named cause when missing.
- design.md ### CD-4 — verifier-fan-in component shape, missing-`change_type:` loud-failure path, and G8 acceptance mapping.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — Slice 1.1 per-file block for centralizing the `change_type:` field name in the reviewer protocol.
- structure.md ### `tests/unit/test-change-type-partition.bats` — per-file block for pinning the `change_type:` field-name requirement and loud failure on missing/out-of-contract values.

### Task 05: G13 `change_type` enum drift hardening on both reviewer-emit and orchestrator-consume sides

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G13]
- **Task type:** code
- **Model:** opus
- **Target files:** scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
- **Dependencies:** Task 02, Task 04
- **LOC estimate:** ~110
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Harden the reviewer finding `change_type` enum on both sides of the fan-in boundary: reviewer-facing protocol prose must emit only the canonical values, and `scripts/verifier-fan-in.sh` must fail loudly on any out-of-enum value instead of silently keeping or dropping it. This preserves deterministic confidence gating and a reproducible audit trail. (Why: see goals.md ### G13. Approach: see design.md ## G13 and design.md ### CD-4.)

**Scope**

- **In:**
  - Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header and use that single script-side set for validation.
  - Make `scripts/verifier-fan-in.sh` treat an out-of-enum `change_type:` as a contract violation: exit non-zero, write `.verifier-fan-in-audit.json`, record `cause: change_type_out_of_enum`, identify the offending finding, and avoid successful kept-finding fan-in.
  - Preserve the existing missing-field path as a distinct `missing_change_type` schema failure.
  - Update `skills/reviewer-protocol/SKILL.md` so the reviewer emission contract documents the same canonical enum once and describes out-of-enum emission as a fan-in-consumed contract violation.
  - Extend `tests/unit/test-change-type-partition.bats` with failing and passing fixtures for out-of-enum rejection, all canonical enum values, missing-field distinction, single script-side enum use, and no duplicated skill-side enum alternations.

- **Out:**
  - Baseline verifier-fan-in script creation, well-formed-round success behavior, generic halt plumbing, and verifier-dispatch prose — T02 owns.
  - Renaming reviewer frontmatter from `category:` to required `change_type:` and rejecting missing `change_type:` as the field-name defect — T04 owns.
  - Verifier sidecar extension and score-sidecar output contract — T06 owns.
  - Informational-finding message-prefix semantics and verifier rubric handling — T07 owns.

**Definition of done**

- `scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and uses that same definition for all `change_type` membership checks.
- A finding with `change_type:` outside the canonical enum causes `scripts/verifier-fan-in.sh` to exit non-zero and write `.verifier-fan-in-audit.json` with a `halts[]` entry containing `cause: change_type_out_of_enum` and the offending finding identifier.
- Out-of-enum findings do not produce a successful `kept-findings.txt` fan-in result and are not silently default-kept, silently kept, or silently dropped.
- A fixture covering every canonical value (`style`, `clarity`, `correctness`, `scope`, `intent`) succeeds through the same parser path, emits `kept-findings.txt`, and records an audit with no halts.
- Missing `change_type:` still reports the dependency-introduced `missing_change_type` behavior, distinct from `change_type_out_of_enum`.
- `skills/reviewer-protocol/SKILL.md` documents the canonical enum once as the reviewer emission contract and says out-of-enum emission is a contract violation consumed by the fan-in script.
- Repository grep coverage confirms duplicated skill-side enum alternations are not introduced outside `skills/reviewer-protocol/SKILL.md`.

**Test expectations**

- `tests/unit/test-change-type-partition.bats` includes a fixture round with an out-of-enum `change_type:` value and asserts `scripts/verifier-fan-in.sh` exits non-zero, writes `.verifier-fan-in-audit.json`, records `cause: change_type_out_of_enum`, identifies the offending finding, and does not proceed as a successful kept-finding fan-in.
- The same bats file includes a well-formed fixture covering every canonical enum value (`style`, `clarity`, `correctness`, `scope`, `intent`) and asserts success, `kept-findings.txt` emission, and an audit with no halts.
- A missing-`change_type:` fixture asserts `missing_change_type`, not `change_type_out_of_enum`, preserving the dependency task's distinct schema failure.
- A script audit asserts `scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and validation uses that single set, so tests fail if unknown values are silently defaulted, silently kept, or silently dropped.
- A reviewer-protocol audit asserts `skills/reviewer-protocol/SKILL.md` documents the same canonical enum once as the reviewer emission contract and describes out-of-enum emission as a fan-in contract violation.
- A repository grep assertion confirms duplicated skill-side enum alternations are absent outside `skills/reviewer-protocol/SKILL.md`.

**References**

- goals.md ### G13 — problem framing for out-of-enum reviewer emissions bypassing confidence gating and breaking reproducible audit decisions.
- design.md ## G13 — resolved approach: canonical enum in the fan-in script and reviewer protocol, with named out-of-enum halt and no silent default-keep.
- design.md ### CD-4 — end-to-end verifier fan-in flow, loud-failure paths, script component shape, reviewer update surface, and G13 acceptance row.
- structure.md ### `scripts/verifier-fan-in.sh` — script header constants, enum validation, halt causes, audit output, and `test-change-type-partition.bats` coverage.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer protocol responsibility for the canonical `change_type:` field name and enum, plus the single SKILL-side source requirement.
- structure.md ### `tests/unit/test-change-type-partition.bats` — test responsibility for field-name, enum-membership, partition-routing, and loud-failure coverage.

### Task 06: G11 verifier sidecar extension correction and orchestrator-bypass fix

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G11]
- **Task type:** code
- **Model:** sonnet
- **Target files:** agents/qrspi-finding-verifier.md (modify), tests/unit/test-verifier-agent-file.bats (modify)
- **Dependencies:** Task 02. **Blocks:** T07 (G14 verifier rubric correction extends the same verifier agent and verifier-agent test file).
- **LOC estimate:** ~80

**Overview**

Lock the verifier's disk sidecar output to the single `.score.md` path consumed by the fan-in script, and make any chat-side score report non-load-bearing telemetry so verifier filtering cannot silently bypass the canonical disk contract. The paired verifier-agent test pins the extension, required `score:` field, and wrong-extension rejection behavior before later verifier-rubric work builds on the same files. (Why: see goals.md ### G11. Approach: see design.md ## G11 and design.md ### CD-4 — Verifier-Fan-In Pipeline (end-to-end flow specification) → B. Verifier sidecar.)

**Scope**

- **In:**
  - Constrain `agents/qrspi-finding-verifier.md` to write exactly one sidecar per finding at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md`.
  - Remove any instruction path, example, or allowed alternative that mentions `.score.yml` for verifier score sidecars.
  - Require verifier sidecar frontmatter to contain `score:` as an integer from 0 through 100, with human-readable verifier reasoning kept in the markdown body.
  - Mark any chat-side score summary as non-load-bearing telemetry; the disk sidecar is the canonical output consumed by the fan-in path.
  - Extend `tests/unit/test-verifier-agent-file.bats` to pin the locked extension, required `score:` field, absence of `.score.yml` allowance, and rejection of wrong-extension sidecar references through the fan-in-side contract.

- **Out:**
  - Creating or changing `scripts/verifier-fan-in.sh` itself — T02 owns the fan-in consumer that T06 aligns the verifier agent against.
  - Adding the G14 `Informational:` verifier rubric carve-out or reviewer-protocol convention — T07 owns.
  - Creating the interaction-mode detection helper for apply-fix orchestration — T24 owns the shared G11/G12/G6 helper surface.
  - Adding later verifier rubric calibration fields or cite-check behavior — T08-T10 own those downstream verifier-agent extensions.

**Definition of done**

- `agents/qrspi-finding-verifier.md` instructs the verifier to write exactly one sidecar per finding at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md`.
- No verifier instruction path, example, or allowed alternative in the target agent file mentions `.score.yml`.
- The verifier sidecar contract requires frontmatter containing `score:` as an integer from 0 through 100.
- The verifier sidecar contract leaves verifier reasoning in the markdown body for audit/debug reading.
- Any chat-side score summary, if still present, is explicitly described as non-load-bearing telemetry rather than the canonical filtering input.
- `tests/unit/test-verifier-agent-file.bats` asserts the locked extension, required `score:` field, absence of `.score.yml` allowance, and wrong-extension rejection behavior.
- Existing sidecar-extension assertions remain intact for T07 to extend without weakening this contract.

**Test expectations**

- Pre-implementation RED check: `tests/unit/test-verifier-agent-file.bats` fails while `agents/qrspi-finding-verifier.md` does not require sidecars at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` with no `.score.yml` alternative.
- Post-implementation run of `tests/unit/test-verifier-agent-file.bats` passes only when the verifier agent file pins `.score.md`, requires `score:` in sidecar frontmatter, and contains no `.score.yml` allowance.
- Grep audit of `agents/qrspi-finding-verifier.md` confirms the canonical path shape `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` is present and `.score.yml` is absent.
- Test inspection confirms chat-side score output is non-load-bearing telemetry and the disk sidecar is the canonical fan-in input.
- Regression assertion confirms wrong-extension sidecar references remain rejected by the fan-in-side contract rather than accepted as a fallback.

**References**

- goals.md ### G11 — problem framing for extension drift plus orchestrator bypass of disk sidecars.
- design.md ## G11 — maps the goal to CD-4's locked `.score.md` sidecar and script-consumed disk contract.
- design.md ### CD-4 — Verifier-Fan-In Pipeline (end-to-end flow specification) → B. Verifier sidecar — exact verifier sidecar path, schema, and non-load-bearing chat-output rule.
- structure.md ### `agents/qrspi-finding-verifier.md` — Slice 1.1 verifier-agent responsibility for G11 sidecar path/extension and `score:` frontmatter.
- structure.md ### `tests/unit/test-verifier-agent-file.bats` — Slice 1.1 test responsibility for sidecar extension, required fields, and verifier-agent prose pins.

### Task 07: G14 verifier rubric correction for `Informational` findings

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G14]
- **Task type:** code
- **Model:** opus
- **Target files:** `skills/reviewer-protocol/SKILL.md` (modify), `agents/qrspi-finding-verifier.md` (modify), `tests/unit/test-verifier-agent-file.bats` (modify)
- **Dependencies:** Task 06. **Blocks:** T08 (G19 verifier wholesale-hallucination rubric work extends the same verifier file after this carve-out is in place).
- **LOC estimate:** ~100

**Overview**

Formalize the reviewer `Informational:` message-prefix convention and add the matching verifier rubric branch so informational observations are scored on structural confidence instead of the false-positive rubric. This keeps real informational observations in the audit trail while still dropping informational claims whose premise is wrong. (Why: see goals.md ### G14. Approach: see design.md ## G14.)

**Scope**

- **In:**
  - Add `## Informational Findings` to `skills/reviewer-protocol/SKILL.md`, documenting the literal case-sensitive `Informational:` prefix at the start of the first non-blank `message` line, intended use for real observations with no demanded action, downstream structural-confidence scoring, log-only behavior, and unchanged behavior for findings without the prefix.
  - Insert the G14 Informational-carve-out clause in `agents/qrspi-finding-verifier.md` immediately before the existing false-positive-pattern list so first-non-blank-line `Informational:` findings bypass false-positive scoring and receive structural-confidence anchors of 75 / 50 / 25.
  - Extend `tests/unit/test-verifier-agent-file.bats` to pin both prose surfaces: the verifier carve-out and the reviewer-protocol section.
  - Preserve the existing verifier sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` while adding the G14 assertions.

- **Out:**
  - Changing the verifier sidecar path, `.score.md` extension, or required sidecar fields — T06 owns; this task only preserves those existing assertions.
  - Adding hallucination / citation-mismatch screening to the verifier rubric — T08 owns.
  - Adding a structured sixth finding field such as `actionability:` or changing the canonical 5-field finding schema — design.md ## G14 defers that option to v0.7.3 signal.
  - Updating reviewer agent bodies to emit the prefix automatically; this task documents the convention and verifier behavior, but reviewers opt in by using the prefix.
  - Reworking the acknowledged-and-silenced false-positive case; existing CLAUDE.md / feedback silencing remains in the false-positive rubric.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains a `## Informational Findings` section in the G14-specified location and documents prefix shape, intended use, downstream behavior, log-only handling, and backward compatibility for unprefixed findings.
- `agents/qrspi-finding-verifier.md` contains the G14 Informational-carve-out before the false-positive-pattern list, with literal `Informational:` detection on the first non-blank `message` line and structural-confidence scoring anchors for structurally verifiable, partially verifiable, and premise-wrong findings.
- `tests/unit/test-verifier-agent-file.bats` fails against the pre-change verifier/protocol prose and passes only when both G14 prose surfaces are present with the required anchors.
- Existing verifier sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` remain intact.
- No changes are made to the canonical 5-field finding schema or to reviewer agent bodies.

**Test expectations**

- RED check: the added `tests/unit/test-verifier-agent-file.bats` assertions fail before implementation when the verifier lacks the `Informational:` carve-out before the false-positive-pattern list.
- Verifier-prose audit: the test passes only when `agents/qrspi-finding-verifier.md` contains the literal case-sensitive `Informational:` token, the first-non-blank-line detection rule, and the 75 / 50 / 25 structural-confidence anchors for structurally verifiable, partially verifiable, and premise-wrong informational findings.
- Reviewer-protocol audit: the test passes only when `skills/reviewer-protocol/SKILL.md` contains `## Informational Findings` and documents the prefix shape, intended use, downstream structural-confidence scoring, log-only handling, and unchanged behavior for findings without the prefix.
- Regression guard: existing `.score.md` sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` still pass after the informational-rubric assertions are added.

**References**

- goals.md ### G14 — problem framing for the verifier's wrong-rubric treatment of reviewer-labeled informational observations.
- design.md ## G14 — selected prose-prefix convention, verifier carve-out text, placement rules, acceptance criteria, and schema-migration deferral.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer-protocol placement and required Informational section contents.
- structure.md ### `agents/qrspi-finding-verifier.md` — verifier insertion site and structural-confidence rubric anchors.
- structure.md ### `tests/unit/test-verifier-agent-file.bats` — test file responsibility for G14 rubric pins plus existing G11 sidecar assertions.

### Task 08: G19 verifier wholesale-hallucination rubric class

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G19]
- **Task type:** code
- **Model:** sonnet
- **Target files:** agents/qrspi-finding-verifier.md (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)
- **Dependencies:** Task 07. **Blocks:** Task 09 (G20 reviewer-model calibration for task-tool-substituted Codex model).
- **LOC estimate:** ~120

**Overview**

Extend the verifier with a Cite Check path that rejects findings whose cited files, line ranges, quoted content, or named anchors do not exist at the cited location, while preserving existing rubric behavior for findings with no concrete factual citation. Cover the behavior in the release acceptance path so hallucinated findings score integer zero, carry a greppable `HALLUCINATED: ` reason, and stay out of the kept-finding set. (Why: see goals.md ### G19. Approach: see design.md ## G19.)

**Scope**

- **In:**
  - Insert the new verifier Step 3.5 Cite Check in `agents/qrspi-finding-verifier.md` between the existing referenced-files read step and lazy upstream-read step, using the G19 wording for file-existence, line-range, quoted-content, and named-anchor checks.
  - Prepend the verifier rubric with the new `0 / HALLUCINATED` tier and document that Cite Check failures halt scoring with integer `score: 0`.
  - Document the sidecar reason-prefix convention so Cite Check score-0 sidecars begin `reason:` with the literal prefix `HALLUCINATED: `.
  - Add release acceptance coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` that drives fabricated citations through the verifier fan-in path and proves dropped hallucinations remain below the existing keep thresholds and out of `kept-findings.txt`.

- **Out:**
  - Reviewer-side hallucination prevention and model-calibration observability — Task 09 / G20 owns the source-side calibration surface.
  - Orchestrator changes, keep-threshold changes, new sidecar fields, or a new `HALLUCINATED` score sentinel — G19 uses existing integer score/drop semantics.
  - New verifier-adjacent subagents, a standalone citation extractor, cross-reviewer corroboration thresholds, or an automated hallucination repro harness — design.md ## G19 defers those to v0.7.3+ questions.
  - Rejecting pure-advisory or stylistic findings solely because they carry no concrete factual citation; those continue through the existing rubric unchanged.

**Definition of done**

- `agents/qrspi-finding-verifier.md` contains a Cite Check step between the current Step 3 and Step 4, before final scoring/lazy upstream context, and it checks only citations the finding actually makes.
- Missing cited files, out-of-range cited line references, quoted-content mismatches at cited locations, and absent named anchors in cited files all halt rubric work with integer `score: 0` and a `HALLUCINATED: ` reason.
- Findings whose prose carries no specific factual cite treat Cite Check as a no-op and proceed to the pre-existing rubric.
- The `0 / HALLUCINATED` rubric tier appears above the existing 0/25/50/75/100 confidence anchors, and the sidecar write step documents the literal reason-prefix convention.
- The acceptance fixture proves hallucinated sidecars fall below both existing keep thresholds and are excluded from `kept-findings.txt`; the test fails if a hallucinated finding reaches the kept set.

**Test expectations**

- Grep/diff audit of `agents/qrspi-finding-verifier.md` confirms the Step 3.5 Cite Check prose, the `0 / HALLUCINATED` rubric tier, and the `HALLUCINATED: ` sidecar reason-prefix sentence match the G19 design payload.
- Acceptance fixture audit confirms fabricated reviewer findings cover missing files, out-of-range lines, quoted-content mismatches, and missing named anchors that are actually cited by the finding.
- Acceptance assertions confirm each Cite Check mismatch emits `score: 0` and a `reason:` beginning with `HALLUCINATED: `.
- Acceptance assertions confirm a finding with no specific factual citation is not rejected by the new Cite Check solely because it is advisory or stylistic.
- Acceptance assertions confirm dropped hallucination sidecars fall below the existing correctness/style-clarity keep thresholds and do not appear in `kept-findings.txt`.

**References**

- goals.md ### G19 — problem framing for wholesale-hallucinated reviewer findings reaching the verifier filter.
- design.md ## G19 — Cite Check mechanism, halt-and-zero behavior, reason-prefix convention, and v0.7.3+ deferrals.
- structure.md ### `agents/qrspi-finding-verifier.md` → Slice 1.2 / G19 — verifier Step 3.5, rubric tier, and sidecar reason-prefix insertion deltas.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` → Slice 1.2 / G19 — release acceptance path for hallucination drop behavior.

### Task 09: G20 reviewer-model calibration for task-tool-substituted Codex model

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G20]
- **Task type:** code
- **Model:** opus
- **Target files:** agents/qrspi-finding-verifier.md (modify), skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), tests/unit/test-verified-file-shape.bats (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)
- **Dependencies:** Task 08. **Blocks:** T10 (G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation), T20 (G3 dispatch-script rename consumes this task's `scripts/run-codex-review.sh` `actual_model:` manifest edits).
- **LOC estimate:** ~160

**Overview**

Add observability for reviewer model calibration by carrying the already-resolved dispatch model into reviewer-facing prompts, dispatch metadata, and verifier sidecars without changing keep thresholds or mitigation behavior. This records whether task-tool-substituted review models behave differently while preserving the verifier filter as the load-bearing correctness gate. (Why: see goals.md ### G20. Approach: see design.md ## G20.)

**Scope**

- **In:**
  - Update `agents/qrspi-finding-verifier.md` so the verifier parses the `actual_model:` audit field from finding frontmatter, writes `actual_model:` in both success and `VERIFY_FAILED` sidecar frontmatter, copies supplied values verbatim, and falls back to `actual_model: unknown` for older or drifted findings that omit it.
  - Update `skills/using-qrspi/SKILL.md` reviewer-dispatch prompt prose to include `actual_model: <resolved model ID>` as a record-keeping parameter sourced from the already-resolved dispatch model.
  - Update `scripts/run-codex-review.sh` dispatch manifest persistence so each dispatch entry records host, vendor, and resolved model metadata, with the manifest `model` value matching the value reviewers are instructed to copy as `actual_model:`.
  - Update `tests/unit/test-verified-file-shape.bats` and `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` to pin sidecar `actual_model:` shape, reviewer-frontmatter-to-sidecar flow, clean-sentinel coverage, manifest metadata, and unchanged keep behavior.

- **Out:**
  - G19 cite-check / `HALLUCINATED:` verifier-rubric behavior — T08 owns and this task depends on it.
  - G28 `defect_class:` sidecar tagging, sub-threshold observations prose, and no-override assertions — T10 owns.
  - G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file`) on pre-rename `scripts/run-codex-review.sh` — T11 owns; this task touches the same dispatch manifest only for the `actual_model:` flow.
  - Reviewer-protocol schema/template edits outside the listed Target files; this task verifies the emitted `actual_model:` flow from reviewer frontmatter rather than expanding the target-file set.
  - Any substituted-model-specific threshold, mitigation, `model_routing:` schema extension, or aggregate `verified.md` header.

**Definition of done**

- Verifier sidecars always include `actual_model:` in frontmatter for both normal and `VERIFY_FAILED` outputs.
- When finding frontmatter supplies `actual_model:`, the verifier sidecar copies that value verbatim; when the finding omits it, the sidecar writes `actual_model: unknown` and does not fail solely because the audit field is absent.
- Reviewer dispatch prose in `skills/using-qrspi/SKILL.md` documents `actual_model: <resolved model ID>` as a prompt parameter sourced from the dispatch model resolution already performed by the orchestrator/dispatch path.
- Dispatch manifest entries written by `scripts/run-codex-review.sh` persist host, vendor, and model metadata per dispatch entry; the manifest `model` value is the same resolved value reviewers are instructed to emit as `actual_model:`.
- Acceptance coverage proves reviewer-frontmatter `actual_model:` flows through to verifier sidecars and `*.clean.md` sentinels carry the field.
- Existing keep behavior is unchanged: correctness findings still use the existing correctness floor, style and clarity findings still use the existing style/clarity floor, and no substituted-model-specific threshold or aggregate verified-file header is introduced.

**Test expectations**

- Unit coverage in `tests/unit/test-verified-file-shape.bats` proves verifier sidecar frontmatter always includes `actual_model:`, copies supplied finding-frontmatter values verbatim, and writes `actual_model: unknown` when the finding omits the field.
- Acceptance coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` proves reviewer-frontmatter `actual_model:` flows through to verifier sidecars and that `*.clean.md` sentinels also carry the field.
- Acceptance coverage proves the dispatch manifest records host, vendor, and model metadata per dispatch entry, and that the manifest `model` value is the value reviewers are instructed to copy as `actual_model:`.
- Acceptance or grep-based assertions prove existing keep behavior is unchanged: correctness findings still keep at the existing correctness floor, style and clarity findings still keep at the existing style/clarity floor, and no substituted-model-specific threshold or aggregate verified-file header is introduced.
- Grep-based assertion proves the reviewer dispatch prompt documented in `skills/using-qrspi/SKILL.md` includes `actual_model: <resolved model ID>` as a record-keeping parameter sourced from the already-resolved dispatch model.

**References**

- goals.md ### G20 — problem framing for substituted-model calibration data and why the verifier remains the current defense.
- design.md ## G20 — observability-only scope, sub-decisions A1/B1/D1, and deliverables for `actual_model:` flow.
- structure.md ### `agents/qrspi-finding-verifier.md` — verifier-side `actual_model:` parse and sidecar frontmatter additions, including `unknown` fallback.
- structure.md ### `skills/using-qrspi/SKILL.md` — reviewer dispatch prompt parameter addition for `actual_model: <resolved model ID>`.
- structure.md ### `scripts/run-codex-review.sh` — dispatch manifest host/vendor/model persistence and model-to-`actual_model:` audit-field flow.
- structure.md ### `tests/unit/test-verified-file-shape.bats` — unit-side sidecar shape coverage for `actual_model:`.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — release-level actual-model flow, clean-sentinel coverage, manifest metadata, and unchanged threshold behavior.

### Task 10: G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G28]
- **Task type:** code
- **Model:** opus
- **Target files:** agents/qrspi-finding-verifier.md (modify), skills/using-qrspi/SKILL.md (modify), tests/unit/test-verified-file-shape.bats (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)
- **Dependencies:** Task 09
- **LOC estimate:** ~150

**Overview**

Add verifier-side `defect_class:` instrumentation and an informational sub-threshold-observations disposition surface while preserving the existing verifier fan-in threshold filter as the only kept-set path. This records convergent dropped-finding evidence for future calibration without allowing orchestrator overrides in v0.7.2. (Why: see goals.md ### G28. Approach: see design.md ## G28.)

**Scope**

- **In:**
  - Update `agents/qrspi-finding-verifier.md` so verifier rubric prose emits a `defect_class:` tag after scoring and before sidecar write, with documented lowercase kebab-case shape, ≤30-character limit, examples, and `unspecified` fallback.
  - Update verifier sidecar examples/prose so `defect_class:` is present in sidecar frontmatter alongside the existing scoring fields, without changing keep/drop behavior.
  - Update `skills/using-qrspi/SKILL.md` dispositions writer prose to forbid keeping sub-threshold findings via manual/orchestrator override and to document the optional `## Sub-Threshold Observations` H2 section as informational only.
  - Update `tests/unit/test-verified-file-shape.bats` to pin non-empty well-formed `defect_class:` tokens, including `unspecified` as the documented absence-of-signal value.
  - Update `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` to pin that sub-threshold findings do not reach `kept-findings.txt` through an override path and that a present observations section is well-formed.

- **Out:**
  - Changing `scripts/verifier-fan-in.sh`, its audit JSON shape, `kept-findings.txt` semantics, `verifier_enabled`, or per-skill review-loop wiring.
  - Adding automated convergent-evidence detection, cluster promotion, or threshold changes in v0.7.2 — future calibration is explicitly deferred.
  - Changing reviewer subagent schemas or making `defect_class:` reviewer-emitted; the classification is verifier-side instrumentation only.
  - Applying patches for dropped findings as part of apply-fix work; dropped findings may be recorded only as observations.

**Definition of done**

- Verifier sidecar examples and rubric prose require a `defect_class:` frontmatter field emitted after scoring and before sidecar write, using lowercase kebab-case letters, digits, and hyphens, no more than 30 characters.
- Sub-threshold clarity and correctness findings require `defect_class:`; findings without a meaningful category emit `defect_class: unspecified` rather than omitting the field.
- Above-threshold findings may carry `defect_class:` without changing keep/drop behavior.
- Orchestration prose forbids keeping sub-threshold findings by manual override; dropped findings can be recorded as observations but must not be patched as part of round apply-fix work.
- Dispositions prose documents an optional `## Sub-Threshold Observations` section containing a YAML-fenced block with an observation summary, contributing finding paths relative to the artifact directory, each finding's defect class, each score, and the threshold that dropped it.
- The documented observations section is explicitly informational and not consumed by scripts in this release.
- No changes are made to `scripts/verifier-fan-in.sh`, its audit JSON shape, `kept-findings.txt` semantics, `verifier_enabled`, or per-skill review-loop wiring.
- Unit tests assert verifier sidecars carry a non-empty `defect_class:` token matching the documented shape and accept `unspecified` as the documented absence-of-signal value.
- Acceptance tests assert sub-threshold findings do not reach `kept-findings.txt` through any override path and that a present `## Sub-Threshold Observations` section is well-formed.

**Test expectations**

- Grep `agents/qrspi-finding-verifier.md` for the new Defect-class tag rubric step and `defect_class:` sidecar frontmatter example; assert the documented token shape, ≤30-character limit, examples, and `unspecified` fallback are present.
- Fixture-backed unit coverage in `tests/unit/test-verified-file-shape.bats` asserts verifier sidecars carry a non-empty `defect_class:` token matching lowercase kebab-case letters, digits, and hyphens, and accepts `unspecified` as the absence-of-signal value.
- Unit or grep coverage asserts sub-threshold clarity/correctness prose requires `defect_class:` while above-threshold findings may carry it without changing keep/drop behavior.
- Grep `skills/using-qrspi/SKILL.md` for the sub-threshold override prohibition: dropped findings must not be kept by manual/orchestrator override and must not be patched as part of apply-fix work.
- Grep `skills/using-qrspi/SKILL.md` for the optional `## Sub-Threshold Observations` H2 section template and YAML-fenced fields: observation summary, contributing finding paths relative to the artifact directory, `defect_class` tags, scores, and threshold.
- Acceptance coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` asserts sub-threshold findings do not reach `kept-findings.txt` through any override path.
- Acceptance coverage asserts a present `## Sub-Threshold Observations` section is well-formed and remains informational only.
- Grep/audit confirms no changes to `scripts/verifier-fan-in.sh`, its audit JSON shape, `kept-findings.txt` semantics, `verifier_enabled`, or per-skill review-loop wiring.

**References**

- goals.md ### G28 — problem framing for sub-threshold convergent evidence and the missing protocol carve-out.
- design.md ## G28 — locked outcome: verifier-side instrumentation, informational observations, no orchestrator override, no fan-in script behavior change.
- structure.md ### `agents/qrspi-finding-verifier.md` → Slice 1.2 — verifier rubric insertion, sidecar example update, and iron-rule consistency notes for `defect_class:`.
- structure.md ### `skills/using-qrspi/SKILL.md` → Slice 1.2 — dispositions template for optional `## Sub-Threshold Observations` and informational-only behavior.
- structure.md ### `tests/unit/test-verified-file-shape.bats` — unit-level sidecar shape assertions for `defect_class:`.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` → Slice 1.2 — release-level acceptance for defect-class emission, no override path to `kept-findings.txt`, and observations-section shape.

### Task 11: G3 dispatch-manifest provenance fields (`subagent_type` / `host` / `vendor` / `model` / `prompt_file` in `.dispatch-manifest.json`)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G3]
- **Task type:** code
- **Model:** sonnet
- **Target files:** skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)
- **Dependencies:** none. **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/run-codex-review.sh` dispatch-manifest provenance edits).
- **LOC estimate:** ~110
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

CD-1's universal dispatch architecture needs the `.dispatch-manifest.json` schema extended with resolved per-dispatch provenance so the off-LLM dispatch path is auditable end-to-end. This task lands the schema and write-side wiring on the pre-rename `scripts/run-codex-review.sh` so the changes are in place before T20 hard-renames the script to `scripts/dispatch-agent.sh`. (Why: see design.md ## CD-1 → "Dispatch manifest schema" subsection. Goal G3 is the dispatch-architecture umbrella; this task lands one of its CD-1 schema deliverables. G29 — the formerly-planned large-artifact escape-hatch goal — is moot per design.md ## G29 (absorbed by CD-1, no separate task ships).)

**Scope**

- **In:**
  - Persist resolved reviewer-dispatch provenance in `<round-dir>/.dispatch-manifest.json` entries emitted by the reviewer dispatch script under a `dispatch_spec` object: `subagent_type`, `host`, `vendor`, `model`, and first-party `prompt_file`.
  - Persist equivalent third-party dispatch provenance plus the job metadata needed to await and split third-party results.
  - Keep first-party orchestrator-facing dispatch payloads to the emitted spec line / `DISPATCH_FILE=<PROMPT_FILE>` reference shape; reviewer prompt assembly remains outside orchestrator tool-call arguments.
  - Make manifest writes atomic and append-safe for repeated invocations and multiple reviewer tags in the same round.

- **Out:**
  - Renaming `scripts/run-codex-review.sh` to `scripts/dispatch-agent.sh` and migrating consumer SKILLs — T20 owns under G3.
  - Adding host/vendor matrix branching inside the dispatch script — T20 owns under G3 (this task only records what the matrix resolved to).
  - Authoring a threshold rule or reviewer-side `artifact_path` parser contract — explicit non-goal per design.md ## G29 (G29 absorbed-by-CD-1).
  - Adding cleanup or regression-prevention prose to `skills/using-qrspi/SKILL.md` for the absorbed G29 surface — explicit non-goal per design.md ## G29 ("no separate v0.7.2 task ships under the G29 ID").

**Definition of done**

- First-party manifest entries written by the dispatch script include `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file` for every emitted first-party dispatch.
- Third-party manifest entries include the same resolved `host` / `vendor` / `model` provenance plus the third-party job metadata needed by the await-and-split path.
- Manifest append behavior is atomic and append-safe across multiple reviewer tags in one round and repeated invocations for the same output directory; no entries are lost or malformed.
- Orchestrator-facing dispatch remains a prompt-file reference / spec-line flow; no reviewer artifact body is assembled into orchestrator tool-call arguments.
- Acceptance coverage proves a reviewer dispatch is auditable end-to-end through `.dispatch-manifest.json`'s `dispatch_spec` object.

**Test expectations**

- Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object containing `subagent_type`, `host`, `vendor`, `model`, and `prompt_file`.
- Exercise a third-party/background dispatch path and inspect `.dispatch-manifest.json` for resolved `host`, `vendor`, `model`, plus the job metadata consumed by the await-and-split flow.
- Run repeated dispatch-script invocations against the same round output directory with multiple reviewer tags, then validate the manifest remains well-formed JSON with all expected entries present.
- Acceptance coverage verifies the orchestrator-facing dispatch payload stays a prompt-file reference while the manifest records resolved host/vendor/model provenance.

**References**

- goals.md ### G3 — dispatch-architecture umbrella goal (shell-pipeline splitter collapse + third-party renaming + provenance recording).
- design.md ## CD-1 → "Dispatch manifest schema" — locked first-party and third-party `dispatch_spec` shapes consumed by this task.
- design.md ## G29 — locked disposition that G29 is moot/absorbed by CD-1 with no standalone task; this task supplies the CD-1 schema fields that obviate G29's escape-hatch framing.
- structure.md ### `scripts/run-codex-review.sh` — Slice 1.2 manifest-provenance persistence, atomic append behavior, and cross-slice rename note.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — Slice 1.2 acceptance coverage for the manifest-auditable dispatch path.
- structure.md ### 10. Dispatch manifest schema — canonical first-party and third-party manifest entry shapes.

### Task 12: G4 canonical cumulative diff helper (`round-prepare.sh` + `await-round.sh` + section-anchor manifest + per-skill anchors JSON)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G4]
- **Task type:** code
- **Model:** opus
- **Target files:** scripts/round-prepare.sh (create), scripts/await-round.sh (create), scripts/g4-section-anchor-manifest.json (modify), skills/using-qrspi/SKILL.anchors.json (modify), skills/reviewer-protocol/SKILL.anchors.json (modify), skills/plan/SKILL.anchors.json (modify)
- **Dependencies:** none. **Blocks:** T13 (per-task review orchestration consumes `round-prepare.sh` diff / scope / commit-anchor artifacts), T20 (dispatch-script rename and reviewer-dispatch migration update `await-round.sh` and consume the round-drain primitive).
- **LOC estimate:** ~280
- **Sizing exception:** reusable primitives

**Overview**

Create the canonical round-preparation and round-drain primitives that replace hand-reconstructed cumulative diff bases, stale in-memory round bookkeeping, and repeated reviewer-dispatch cleanup rituals. The task also refreshes the G4 section-anchor manifest and per-skill anchor JSON tables so narrow-read lookups remain current for the dispatch, round-preparation, reviewer-protocol, and plan-classification sections touched by this release. (Why: see goals.md ### G4. Approach: see design.md ## G4.)

**Scope**

- **In:**
  - Create `scripts/round-prepare.sh` as the deterministic owner for commit-anchor capture, prior-round bookkeeping validation, convergence-based narrow-or-broaden decisions, backward-loop flag consumption, safe diff-file creation, and `.round-prepare.json` sidecar emission before reviewer dispatch consumes round inputs.
  - Create `scripts/await-round.sh` as the uniform post-dispatch drain step that reads the dispatch manifest, awaits background entries, invokes split commands, updates manifest status, writes `.round-complete.json`, removes round-scoped dispatch prompt files after completion, and succeeds with zero background entries.
  - Update `scripts/g4-section-anchor-manifest.json` and the three per-skill anchor JSON files so refreshed windows cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

- **Out:**
  - Adding per-task scope-tagger dispatch, Implement-phase orchestration prose, and tests that consume the new per-task round artifacts — T13 owns.
  - Renaming the dispatch / companion / splitter scripts, migrating review-producing skills to shared reviewer-dispatch prose, and updating renamed dispatch call sites — T20 owns.
  - Creating and including the Evergreen-Output Rule snippet in artifact-producing skills — T27 owns.
  - Re-authoring the G4 problem statement or redesigning the narrow/broaden convergence table — goals.md ### G4 and design.md ## G4 are authoritative.

**Definition of done**

- `scripts/round-prepare.sh` exists and writes `round-NN.diff`, `.round-prepare.json`, and the round commit anchor on valid inputs, with deterministic repeated output and no sidecar corruption under parallel dispatch.
- Per-task preparation rejects partial commit provenance with exit 10, mismatched worktree head with exit 11, and an unadvanced implementer commit with exit 12, each with diagnostics that identify the documented recovery path.
- Prior-round validation fails loudly when the previous commit anchor is missing or malformed, or when a required prior scope-set is missing or empty; reviewer dispatch cannot proceed from stale or absent bookkeeping.
- Convergence handling broadens on missing, empty, full-artifact, superset, overlap, or disjoint scope sets; narrows only for equal sets or proper-subset-with-safety-margin cases; and broadens if the previous commit anchor no longer matches `HEAD~1`.
- Backward-loop flag handling is consume-once: a present flag forces base-branch preparation for the next round, deletes the flag when possible, and surfaces a diagnostic if deletion fails.
- Non-git workspaces return the documented no-diff status without fabricating a diff path or scope hint.
- `scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior.
- `scripts/await-round.sh` never echoes captured reviewer payloads or prompt bodies to stdout or stderr; terminal output remains bounded to a short status summary and diagnostics.
- The anchor manifest and per-skill anchor JSON files remain valid JSON and contain refreshed windows for the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**Test expectations**

- Run file-existence checks for `scripts/round-prepare.sh` and `scripts/await-round.sh`; run JSON validation for `scripts/g4-section-anchor-manifest.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/reviewer-protocol/SKILL.anchors.json`, and `skills/plan/SKILL.anchors.json`.
- Exercise `round-prepare.sh` happy-path inputs and verify it writes `round-NN.diff`, `.round-prepare.json`, and the round commit anchor; rerun with the same inputs and verify deterministic output without corrupting sidecars under parallel dispatch.
- Exercise per-task preparation failure fixtures for partial commit provenance (exit 10), implementer SHA / worktree HEAD mismatch (exit 11), and unadvanced implementer commit (exit 12), verifying each diagnostic names the correct recovery path.
- Exercise prior-round validation fixtures for missing / malformed `round-(NN-1)-commit.txt` and missing / empty required `round-(NN-1)-scope-set.txt`; verify reviewer dispatch is blocked on each failure.
- Exercise convergence fixtures for missing, empty, full-artifact, superset, overlap, disjoint, equal, and proper-subset-with-safety-margin scope sets, plus the `HEAD~1` mismatch fallback case.
- Exercise backward-loop flag handling and verify the next round is forced to base-branch preparation, the flag is consumed once, and deletion failure is diagnosed.
- Exercise a non-git workspace and verify the documented no-diff status returns without a fabricated diff path or scope hint.
- Exercise `await-round.sh` against pending background entries and zero-entry manifests; verify awaited entries are split, manifest statuses update, `.round-complete.json` is written, round-scoped dispatch prompt files are removed after completion, and zero-entry rounds exit successfully.
- Audit combined stdout and stderr from `await-round.sh` with captured reviewer payload and prompt-body fixtures; verify no captured payload or prompt body is echoed and output stays bounded to the short status / diagnostic surface.
- Grep or diff the refreshed anchor JSON windows to confirm they cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**References**

- goals.md ### G4 — problem framing for canonical cumulative `round-NN.diff` construction and avoiding hand-computed merge-base drift.
- design.md ## G4 — detailed `round-prepare.sh` solution, exit-code recovery table, prior-bookkeeping validation, convergence behavior, sidecar shape, and acceptance criteria.
- structure.md ### `scripts/round-prepare.sh` — Slice 1.4 creation block for the canonical preparation helper and its HEAD-correctness contract.
- structure.md ### `scripts/await-round.sh` — Slice 1.4 creation block for the manifest-driven async drain helper and output-bound contract.
- structure.md ### `scripts/g4-section-anchor-manifest.json` — manifest refresh responsibility for narrow-read section anchors.
- structure.md ### `skills/using-qrspi/SKILL.anchors.json` — per-skill anchor refresh for using-qrspi windows touched by this release.
- structure.md ### `skills/reviewer-protocol/SKILL.anchors.json` — per-skill anchor refresh around reviewer-protocol windows touched by this release.
- structure.md ### `skills/plan/SKILL.anchors.json` — per-skill anchor refresh around Plan classification and reviewer-dispatch windows.

### Task 13: G9 per-task review orchestration fires scope-tagger, `round-NN.diff`, and `round-NN-commit.txt` artifacts

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G9]
- **Task type:** code
- **Model:** opus
- **Target files:** scripts/round-prepare.sh (modify), skills/implement/SKILL.md (modify), tests/unit/test-scope-tagger-dispatch.bats (modify)
- **Dependencies:** Task 12. **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).
- **LOC estimate:** ~120
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Make per-task review rounds leave the durable bookkeeping required for the next reviewer dispatch: scope-set emission, per-round diff emission, and commit-anchor capture with loud recovery-coded failures when the sequence is missing or malformed. This is a G9 hardening task layered on top of the Task 12/G4 round-preparation helper so the orchestrator keeps first-party Task dispatch in main chat while deterministic scripts enforce file-state invariants. (Why: see goals.md ### G9. Approach: see design.md ## G9.)

**Scope**

- **In:**
  - Extend `scripts/round-prepare.sh` per-task behavior so task-branch mode writes `round-NN-commit.txt` with the passed implementer SHA plus trailing newline, emits `round-NN.diff` through the canonical preparation path, and fails with distinct documented recovery codes for missing SHA, worktree/self-reported SHA mismatch, and non-advanced implementer SHA.
  - Add prior-round loud-failure checks in `round-prepare.sh` for missing or malformed `round-(NN-1)-commit.txt`, and for missing or empty `round-(NN-1)-scope-set.txt` when later-round narrowing is eligible and scope tagging is enabled.
  - Insert the G9 between-round checklist into `skills/implement/SKILL.md` at the per-task reviewer fan-out site, covering scope-tagger dispatch, implementer `commit_sha:` extraction, `dispatch-agent.sh --implementer-commit` invocation, and exit-code branches for success, orchestrator bug, worktree integrity break, and implementer re-dispatch.
  - Update `tests/unit/test-scope-tagger-dispatch.bats` to prove scope-tagger dispatch against kept finding files, sibling `round-NN-scope-set.txt` artifact creation, commit-anchor writing, per-round diff production, and the grep-style guard that scripts do not dispatch first-party Task-tool subagents or capture Task-tool return values.

- **Out:**
  - Creating the canonical `round-prepare.sh` / `await-round.sh` helper scaffolding and the general G4 diff/ref-selection behavior — T12 owns.
  - Artifact-level review-loop orchestration in `using-qrspi/SKILL.md` Standard Review Loop — explicitly out of G9 per design.md ## G9.
  - Moving first-party Task-tool subagent dispatch or Task-tool return capture into bash scripts — main chat remains the owner of those actions.

**Definition of done**

- `round-prepare.sh` writes `round-NN-commit.txt` containing exactly the passed implementer SHA plus a trailing newline when task-branch mode receives a fresh SHA matching the worktree HEAD.
- `round-prepare.sh` preserves canonical `round-NN.diff` emission in task-branch mode.
- `round-prepare.sh` exits with distinct documented recovery codes for missing implementer SHA, implementer SHA not matching worktree HEAD, and implementer SHA not advancing beyond the prior round anchor.
- Round-one non-advance detection compares against the task base commit and names that base condition in the diagnostic instead of referencing a prior round anchor.
- Later-round preparation fails loudly when the prior `round-(NN-1)-commit.txt` file is missing or malformed.
- Narrowing-eligible later-round preparation with scope tagging enabled fails loudly when the prior `round-(NN-1)-scope-set.txt` file is missing or empty.
- `skills/implement/SKILL.md` contains the between-round checklist in the per-task reviewer fan-out section and no longer tells main chat to run its own worktree HEAD comparison there.
- Unit coverage proves scope-tagger dispatch produces sibling `round-NN-scope-set.txt` artifacts for reviewed rounds and scripts do not dispatch first-party Task-tool subagents or capture Task-tool returns.

**Test expectations**

- Bats fixture: happy-path task-branch invocation writes `round-NN-commit.txt` with the passed SHA and trailing newline when that SHA matches worktree HEAD and advances past the prior anchor.
- Bats fixtures: missing implementer SHA, mismatched worktree HEAD, unadvanced later-round SHA, and unadvanced round-one task-base SHA each return the documented distinct recovery code and diagnostic language.
- Bats fixtures: later-round invocation fails loudly for missing or malformed `round-(NN-1)-commit.txt`; narrowing-eligible later-round invocation with scope tagging enabled fails loudly for missing or empty `round-(NN-1)-scope-set.txt`.
- Bats or file assertions: task-branch mode still emits `round-NN.diff` through the inherited canonical preparation path.
- Grep audit on `skills/implement/SKILL.md`: the per-task reviewer fan-out section contains the checklist items for scope-tagger dispatch, implementer `commit_sha:` extraction, `dispatch-agent.sh --implementer-commit`, and exit-code branches 0/10/11/12.
- Grep audit on `skills/implement/SKILL.md`: the per-task review section no longer contains main-chat-side `rev-parse HEAD` comparison instructions; the residual responsibility is reading the implementer SHA, passing it to the dispatcher, and branching on script exit code.
- Unit assertion: `qrspi-scope-tagger` is dispatched against kept finding files between rounds and writes `round-NN-scope-set.txt` as a sibling artifact for every reviewed round.
- Grep-style script guard: `scripts/` contains no first-party Task-tool subagent dispatch or direct Task-tool return capture patterns.

**References**

- goals.md ### G9 — problem framing for silent per-task review-loop drift and missing scope-set / commit-anchor / diff artifacts.
- design.md ## G9 — four-layer per-task arrangement, between-round checklist, out-of-scope artifact-level boundary, and acceptance criteria.
- structure.md ### `scripts/round-prepare.sh` — G9 Slice 1.3 per-file block for per-task SHA checks, commit-anchor write, prior-artifact assertions, and diff inheritance.
- structure.md ### `skills/implement/SKILL.md` — G9 Slice 1.3 per-file block for the between-round checklist insertion and main-chat residual narrowing.
- structure.md ### `tests/unit/test-scope-tagger-dispatch.bats` — G9 Slice 1.3 per-file block for scope-tagger dispatch, scope-set artifact, commit-anchor, and diff tests.

### Task 14: G15 Plan sweep-task contract with dependent-test scope

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G15]
- **Task type:** code
- **Model:** opus
- **Target files:** modify `skills/plan/SKILL.md`; modify `agents/qrspi-plan-reviewer.md`; modify `skills/using-qrspi/SKILL.md`; modify `tests/integration/test-reference-gate-pause.bats`
- **Dependencies:** none. **Blocks:** Task 15 (G18 Plan cross-task consumer surface builds on the same Plan/reviewer/test surfaces).
- **LOC estimate:** ~110
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Add the Plan-time sweep-task contract that makes a producing sweep task enumerate dependent tests, or prove none exist, before implementation begins. The Plan skill authors the contract, the Plan reviewer enforces it, shared pipeline guidance routes findings through the existing re-spec loop, and the integration test pins the pause behavior. (Why: see goals.md ### G15. Approach: see design.md ## G15.)

**Scope**

- **In:**
  - Add `skills/plan/SKILL.md` `### Sweep Task Contract` at the end of the Test Expectations section, using the design's required contract language for sweep-task definition, `dependent_tests:` path-list shape, and `dependent_tests: none` plus `grep -rn '<pattern>' tests/` zero-match proof shape.
  - Add the two worked examples under that subsection: one sweep-task excerpt with explicit dependent test paths and per-file dispositions, and one excerpt using the `none` plus grep shape.
  - Add the `agents/qrspi-plan-reviewer.md` sweep-task detection rubric: >5 files of the same extension plus one of the required sweep keywords in title or description, with case-insensitive word-boundary matching.
  - Make the Plan reviewer emit a high-severity correctness finding when a sweep-shaped task lacks `dependent_tests:`, lists malformed paths, omits the required `none` plus grep proof, or provides a grep proof that returns one or more matches from the repository root.
  - Add the `skills/using-qrspi/SKILL.md` backstop note that sweep-task dependent-test findings are ordinary Plan review findings handled by the existing plan re-spec loop.
  - Extend `tests/integration/test-reference-gate-pause.bats` for the positive sweep detection case and malformed `dependent_tests:` variants already named in the existing spec.

- **Out:**
  - Cross-task consumer-surface authoring and reviewer enforcement for `cross_task_consumers:` — Task 15 owns.
  - Consumer-surface-specific assertions in `tests/integration/test-reference-gate-pause.bats` — Task 15 owns.
  - Automated gate-time test discovery, per-task gate script changes, test-runner behavior changes, and `implementer-protocol/SKILL.md` changes — explicitly deferred / excluded by design.md ## G15.

**Definition of done**

- `skills/plan/SKILL.md` contains the new `### Sweep Task Contract` subsection at the end of `## Test Expectations` and preserves the required two valid `dependent_tests:` shapes.
- The Sweep Task Contract includes both worked examples: explicit dependent test paths with per-file dispositions, and `dependent_tests: none` followed by a reproducible zero-match `grep -rn '<pattern>' tests/` command.
- `agents/qrspi-plan-reviewer.md` treats a task as sweep-shaped only when `files_in_scope` lists strictly more than five files of the same extension and the title or description contains one of `all`, `every`, `strip`, `remove`, `rename`, `replace`, `delete`, or `sweep` using case-insensitive word-boundary matching.
- `agents/qrspi-plan-reviewer.md` emits `severity: high, change_type: correctness` for missing or malformed `dependent_tests:` fields, including `none` claims whose grep proof returns one or more matches from the repository root.
- `skills/using-qrspi/SKILL.md` states that sweep-task dependent-test findings route through the normal Plan review and re-spec loop, without introducing a new implementation gate or test-runner behavior.
- `tests/integration/test-reference-gate-pause.bats` covers the positive detection case for more-than-five same-extension files plus a sweep keyword and verifies the missing-field finding pauses the Plan gate.
- `tests/integration/test-reference-gate-pause.bats` covers malformed field variants: no file paths, `none` without the grep command, and `none` with a grep command that returns at least one hit.

**Test expectations**

- Inspect `skills/plan/SKILL.md` to confirm `### Sweep Task Contract` appears at the end of `## Test Expectations`, with the sweep definition, both valid `dependent_tests:` shapes, and both worked examples.
- Inspect `agents/qrspi-plan-reviewer.md` to confirm the sweep heuristic uses strict `>5` same-extension files and the exact eight-keyword list with case-insensitive word-boundary matching.
- Inspect `agents/qrspi-plan-reviewer.md` to confirm missing, malformed, and non-zero-grep `dependent_tests:` cases all produce the existing high-severity correctness finding shape.
- Inspect `skills/using-qrspi/SKILL.md` to confirm the backstop note routes sweep findings through normal Plan review / re-spec handling only.
- Run the targeted `tests/integration/test-reference-gate-pause.bats` cases added for G15 and confirm they cover both the positive missing-field pause and the malformed-field variants.

**References**

- goals.md ### G15 — problem framing for sweep tasks whose dependent tests are outside the producing task's file scope.
- design.md ## G15 — required contract wording, reviewer heuristic, deliverables, exclusions, and v0.7.3 automated-discovery deferral.
- structure.md ### `skills/plan/SKILL.md` — Slice 1.3 Plan authoring block for the Sweep Task Contract and worked examples.
- structure.md ### `agents/qrspi-plan-reviewer.md` — Slice 1.3 reviewer rubric block for sweep-task detection and high-severity findings.
- structure.md ### `skills/using-qrspi/SKILL.md` — existing shared pipeline guidance surface targeted by this task's backstop note.
- structure.md ### `tests/integration/test-reference-gate-pause.bats` — G15 integration coverage for dependent-test pause behavior.

### Task 15: G18 Plan cross-task consumer surface

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G18]
- **Task type:** code
- **Model:** opus
- **Target files:** skills/plan/SKILL.md (modify), agents/qrspi-plan-reviewer.md (modify), tests/integration/test-reference-gate-pause.bats (modify)
- **Dependencies:** Task 14
- **LOC estimate:** ~130
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Add the Plan authoring contract and plan-reviewer enforcement for `cross_task_consumers:` so contract-carrier changes enumerate downstream consumers before implementation, then pin the trigger/no-trigger and malformed-field cases in the existing reference-gate integration test. This preserves G15's separate sweep-task contract while generalizing the under-scoping prevention pattern to named consumer surfaces. (Why: see goals.md ### G18. Approach: see design.md ## G18.)

**Scope**

- **In:**
  - Document a `### Cross-Task Consumer Surface` subsection in `skills/plan/SKILL.md` under task-definition guidance, including the five consumer-surface trigger classes, body-only/prose-only non-trigger guidance, and the two valid `cross_task_consumers:` shapes.
  - Add worked examples in `skills/plan/SKILL.md`: a public-symbol rename with three consumers using `co-edit`, `co-edit`, and `no change` dispositions, plus a body-only bug fix where the field is not required.
  - State in `skills/plan/SKILL.md` that tasks satisfying both the sweep-task trigger and consumer-surface trigger carry both `dependent_tests:` and `cross_task_consumers:` as separate fields.
  - Extend `agents/qrspi-plan-reviewer.md` with the Cross-Task Consumer Surface Detection rubric clause, enforcing field presence, shape, `none` search re-verification, allowed disposition vocabulary, and existing follow-up task IDs for `break-and-fix-task`.
  - Extend `tests/integration/test-reference-gate-pause.bats` to cover the missing-field pause, false `none` claim, disposition vocabulary and follow-up-task validation, and independent findings when a task is both sweep-shaped and consumer-surface-touching.

- **Out:**
  - Changing G15's `dependent_tests:` sweep-task contract — T14 owns the Plan sweep-task contract, and this task only preserves its separate composition with G18.
  - Adding a standalone Plan-phase scope-completeness reviewer subagent or automated grep gate beyond the plan-reviewer rerun of author-supplied `none` commands — design.md ## G18 defers those mechanisms to v0.7.3+.
  - Modifying `implementer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, the Standard Plan loop, per-task gate runner, or broader test infrastructure — design.md ## G18 explicitly leaves downstream phases to consume the enriched plan unchanged.

**Definition of done**

- `skills/plan/SKILL.md` contains a `### Cross-Task Consumer Surface` subsection at the end of task-definition guidance with all five trigger classes from design.md ## G18 and the non-trigger case for body-only callable changes, prose edits without anchor-name changes, and formatting fixes.
- The `cross_task_consumers:` contract in `skills/plan/SKILL.md` accepts exactly two shapes: consumer paths with one-sentence dispositions, or `none` followed by a reproducible zero-result search command.
- The allowed consumer dispositions are exactly `no change`, `pass-through`, `co-edit`, and `break-and-fix-task`, with `break-and-fix-task` requiring a cited existing follow-up task ID.
- `skills/plan/SKILL.md` includes the two worked examples named in design.md ## G18 and states that sweep-shaped consumer-surface-touching tasks carry both `dependent_tests:` and `cross_task_consumers:` as separate fields.
- `agents/qrspi-plan-reviewer.md` detects consumer-surface-touching tasks using the Plan contract and emits `severity: high, change_type: correctness` findings for missing fields, malformed fields, non-zero-hit `none` claims, invalid dispositions, or missing follow-up task IDs.
- `tests/integration/test-reference-gate-pause.bats` covers the G18 trigger/no-trigger enforcement surfaces listed in the original task expectations, including the independent-finding case for tasks that satisfy both G15 and G18 triggers.

**Test expectations**

- Grep `skills/plan/SKILL.md` for `### Cross-Task Consumer Surface`, the five trigger-class anchor phrases, the non-trigger sentence, both `cross_task_consumers:` shapes, all four disposition strings, and the sweep-plus-consumer composition note.
- Inspect the worked examples in `skills/plan/SKILL.md` to verify one public-symbol rename example lists three consumers with `co-edit` / `co-edit` / `no change`, and one body-only bug-fix example explains why the trigger does not fire.
- Grep `agents/qrspi-plan-reviewer.md` for the Cross-task consumer surface detection rubric and verify it checks field presence/shape, reruns `none` search commands from repo root, validates disposition vocabulary, validates `break-and-fix-task` follow-up task IDs, and emits `severity: high, change_type: correctness` findings.
- Run the targeted `tests/integration/test-reference-gate-pause.bats` cases covering a consumer-surface-touching task without `cross_task_consumers:`, a false `cross_task_consumers: none` claim, invalid dispositions / missing follow-up task IDs, and a task missing both `dependent_tests:` and `cross_task_consumers:`.
- Confirm the G18 changes do not merge or rename G15's `dependent_tests:` contract and do not require changes outside the three target files.

**References**

- goals.md ### G18 — problem framing for Plan-phase under-scoping of cross-task consumer surfaces.
- design.md ## G18 — author-side template extension, reviewer-side heuristic, worked examples, and G15/G18 composition rule.
- structure.md ### `skills/plan/SKILL.md` — target block for the Plan authoring contract, worked examples, and composition note.
- structure.md ### `agents/qrspi-plan-reviewer.md` — target block for reviewer enforcement of the Cross-Task Consumer Surface Detection clause.
- structure.md ### `tests/integration/test-reference-gate-pause.bats` — target block for integration coverage of G18 pause behavior and field-shape failures.

### Task 16: G22 `model_routing` config schema and agent-sweep migration

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G22]
- **Task type:** code
- **Model:** opus
- **Target files:** modify `config.md`; create/modify `scripts/_resolve-lib.sh`; create/modify `skills/_shared/config-validation-procedure.md`; modify `skills/using-qrspi/SKILL.md`; modify `skills/plan/SKILL.md`; modify `skills/implement/SKILL.md`; modify `skills/test/SKILL.md`; modify all `agents/qrspi-*.md`; modify `tests/unit/test-config-model-routing.bats`; modify `tests/unit/test-routing-matrix-application.bats`
- **Dependencies:** none. **Blocks:** T17 (G23 validation-table row and fail-loud cross-links depend on this task's canonical schema and stable fail-loud paragraphs).
- **LOC estimate:** ~320
- **Sizing exception:** schema-migration

**Overview**

Migrate routing to the unified vendor-neutral `model_routing:` schema and single agent/task `tier:` signal, covering config docs, resolver behavior, skill-prose cleanup, agent frontmatter, and routing tests in one coordinated schema-migration wave. This intentionally stays bundled so no dispatch path reads deleted `model_role:` / `model:` fields or silently falls through to stale hardcoded model defaults. (Why: see goals.md ### G22. Architecture: see design.md ### CD-1. Residual rubric/doc cleanup: see design.md ## G22.)

**Scope**

- **In:**
  - Update `config.md` to expose the five-tier vendor-neutral `model_routing:` shape (`extra-low`, `low`, `medium`, `high`, `extra-high`), `default_tier: medium`, and `extra-low: none` as the explicit operator opt-in surface.
  - Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → hardcoded `medium` with loud warning), tier-to-`(vendor, model)` lookup, host/vendor routing lookup, and halt-on-`none` behavior.
  - Create/update `skills/_shared/config-validation-procedure.md` so missing or malformed `model_routing:` configuration fails loudly with repair-or-abort guidance.
  - Rewrite the G22 surfaces in `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md`: remove the old per-host `haiku`/`sonnet`/`opus`/`inherit` schema, remove the role-keyed G5 matrix, emit per-task `tier:` instead of `model:`, and read per-task `tier:` for Implement-phase test-writer dispatch with the test-writer agent's medium default for Test-phase acceptance dispatch.
  - Sweep all `agents/qrspi-*.md` frontmatter to add exactly one `tier:` field using the G22 rubric, delete the four legacy `model_role:` declarations, and add the `DISPATCH_FILE=<path>` first-action instruction to reviewer agents.
  - Preserve the dispatch order contract: TDD test-writer dispatch runs first, then implementer dispatch after the RED-verification gate, and high-tier code tasks co-escalate both dispatches to the same resolved `(vendor, model)` pair.
  - Update `tests/unit/test-config-model-routing.bats` and `tests/unit/test-routing-matrix-application.bats` to pin schema shape, validation, per-tag tier overrides, `none`-tier halt behavior, and implementer/test-writer co-escalation.

- **Out:**
  - Adding the `model_routing:` validation-table row and bidirectional fail-loud paragraph cross-links in `skills/using-qrspi/SKILL.md` — T17 owns.
  - Creating and including the Evergreen-Output Rule snippet across artifact-producing skills — T27 owns the shared G22-adjacent prose-quality surface.
  - Auto-escalating fix-retry-2/3 to `extra-high`, per-reviewer deep-mode tier escalation, and realized-tier telemetry — explicitly deferred by design.md ## G22 as future work.

**Definition of done**

- `config.md` documents the five-tier `model_routing:` block, includes `default_tier: medium`, and keeps `extra-low: none` as an operator opt-in surface.
- `_resolve-lib.sh` resolves tiers in the specified precedence order and halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model.
- The shared config-validation procedure fails missing or malformed `model_routing:` configuration with repair-or-abort guidance.
- Every `agents/qrspi-*.md` file has exactly one `tier:` frontmatter field; the five low-tier agents are `qrspi-finding-verifier`, `qrspi-implementer-lightweight`, `qrspi-research-collator`, `qrspi-research-specialist`, and `qrspi-scope-tagger`; all remaining agents are medium.
- The four legacy `model_role:` declarations are removed from agent frontmatter, and no dispatch prose instructs authors to use `model_role:` for routing.
- Every reviewer agent reads `DISPATCH_FILE=<path>` as its full dispatch before any other procedural step.
- `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md` no longer document or consume the superseded schema fields; Plan emits `tier:` using `lightweight → low`, ordinary code → `medium`, escalated code → `high`.
- A high-tier code task's per-task implementer dispatch and TDD test-writer dispatch resolve to the same `(vendor, model)` pair.
- Grep coverage confirms no `Agent({ ..., model: "sonnet" })` hardcoded dispatch argument remains in skill prose after migration.

**Test expectations**

- Inspect `config.md` for the five-tier vendor-neutral `model_routing:` block, `default_tier: medium`, and explicit `extra-low: none` row.
- Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and hardcoded-medium-with-warning precedence.
- Verify a dispatch resolving to a tier configured as `none` halts with a diagnostic naming the unresolved tier and does not fall back.
- Verify missing and malformed `model_routing:` configurations fail through the shared config-validation procedure with repair-or-abort guidance.
- Run an agent-frontmatter sweep: exactly five `tier: low` agents match the locked rubric, all other `agents/qrspi-*.md` files carry `tier: medium`, and no agent file carries `model_role:`.
- Grep reviewer agents for the `DISPATCH_FILE=<path>` first-action instruction.
- Grep skill prose to confirm the old per-host schema, role-keyed G5 routing matrix, `model:` task-routing field guidance, `test_writer_model`, and hardcoded `model: "sonnet"` dispatch arguments are gone from the migrated surfaces.
- Run/extend `tests/unit/test-config-model-routing.bats` for schema shape, missing `model_routing:` validation, malformed tier values, `none`-tier halt behavior, and fail-loud routing behavior.
- Run/extend `tests/unit/test-routing-matrix-application.bats` for per-tag `--tier-override` application in multi-agent dispatches and the implementer/test-writer co-escalation invariant.

**References**

- goals.md ### G22 — problem framing for contradictory `model_routing:` documentation and dead schema scaffolding.
- design.md ### CD-1 — universal dispatch architecture, tier precedence, config-owned model mapping, resolver behavior, and `DISPATCH_FILE` migration.
- design.md ## G22 — initial 41-agent tier rubric, doc-cleanup sweep, per-task `model:` → `tier:` migration, and acceptance criteria.
- structure.md ### `config.md` — schema-authority block for `model_routing:`, `default_tier:`, and `none` semantics.
- structure.md ### `scripts/_resolve-lib.sh` — shared resolver library responsibilities and precedence chain.
- structure.md ### `skills/_shared/config-validation-procedure.md` — repair-or-abort validation procedure for routing configuration.
- structure.md ### `skills/using-qrspi/SKILL.md` — high-traffic documentation rewrite surface for schema, trusted path, precedence, and validation adjacency.
- structure.md ### `skills/plan/SKILL.md` — Plan Step 2 migration from `model:` to `tier:` and co-escalation source field.
- structure.md ### `skills/implement/SKILL.md` — removal of the old four-layer chain / role-keyed G5 matrix and replacement pointers.
- structure.md ### `skills/test/SKILL.md` — test-writer dispatch migration to per-task `tier:` with medium fallback.
- structure.md ### `agents/qrspi-implementer.md` — dedicated implementer frontmatter tier row.
- structure.md ### `agents/qrspi-code-quality-reviewer.md` — representative reviewer `tier:` plus `DISPATCH_FILE` first-action row.
- structure.md ### `agents/qrspi-plan-reviewer.md` — reviewer `tier:` plus `DISPATCH_FILE` first-action row.
- structure.md ### `agents/qrspi-test-writer.md` — test-writer `tier:` row and `model_role:` deletion.
- structure.md ### `agents/*.md` (sweep — all 41 files) — full agent-frontmatter sweep, reviewer-body instruction, and `model_role:` deletion.
- structure.md ### `tests/unit/test-config-model-routing.bats` — schema, validation, and `none`-tier halt tests.
- structure.md ### `tests/unit/test-routing-matrix-application.bats` — per-tag override and co-escalation routing tests.

### Task 17: G23 validation table covers `model_routing` and cross-links fail-loud paragraphs

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G23]
- **Task type:** code
- **Model:** opus
- **Target files:** `skills/using-qrspi/SKILL.md` (modify), `tests/unit/test-config-model-routing.bats` (modify)
- **Dependencies:** Task 16. **Blocks:** none.
- **LOC estimate:** ~80

**Overview**

Add the missing `model_routing:` validation-table row and bidirectional fail-loud paragraph cross-links so config authors see the required validated block before dispatch. Keep the change narrow: one documentation row, two one-sentence pointers, and the existing bats coverage for that contract. (Why: see goals.md ### G23. Approach: see design.md ## G23.)

**Scope**

- **In:**
  - Add exactly one `model_routing:` row to `skills/using-qrspi/SKILL.md` under `### Fields that affect pipeline behavior (must be validated)`.
  - Describe the row as a required top-level block using the post-Task-16 per-vendor five-tier map shape, and point readers to the schema-definition heading by literal heading text.
  - Point the row to the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text, not by line number.
  - Append one-sentence back-pointers from each post-Task-16 fail-loud paragraph to `### Fields that affect pipeline behavior (must be validated)`.
  - Add/adjust bats assertions in `tests/unit/test-config-model-routing.bats` that pin the validation-table row and the missing-block fail-loud behavior.

- **Out:**
  - Defining the `model_routing:` schema, dispatch chain, per-vendor tier resolution, or `none`-halt semantics — Task 16 owns.
  - Adding the top-level dispatch-routing fail-loud invariant paragraph — dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task ships under G25).
  - Replacing the validation table with a generated index, adding a canonical-source file, adding a validator framework, or adding rows for other config blocks (`providers:`, `trusted_path:`, `validators:`) — explicit non-goals in design.md ## G23.

**Definition of done**

- `skills/using-qrspi/SKILL.md` contains exactly one `model_routing:` row in the validation table.
- The row names the required per-vendor five-tier map shape and cross-references the schema-definition heading by literal heading text.
- The row cross-references the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text.
- Each post-Task-16 fail-loud paragraph points back to `### Fields that affect pipeline behavior (must be validated)` by literal heading text.
- A config missing `model_routing:` still fails loudly through the existing config-routing test path; no silent default or table-only documentation pass is introduced.
- The production-doc diff remains narrow: one table row plus the required one-sentence fail-loud paragraph pointers, with no generated index, new canonical-source file, or extra validator framework.

**Test expectations**

- Bats assertion verifies the `skills/using-qrspi/SKILL.md` validation table contains exactly one `model_routing:` row.
- Bats assertion verifies the row identifies the required per-vendor five-tier map shape and points to the schema-definition heading by literal heading text.
- Bats assertion verifies the row points to the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text, not by line number.
- Bats assertion verifies each post-Task-16 fail-loud paragraph points back to `### Fields that affect pipeline behavior (must be validated)` by literal heading text.
- Existing config-routing missing-block test path verifies a config missing `model_routing:` fails loudly.

**References**

- goals.md ### G23 — problem framing for validation-table discoverability and missing bidirectional links.
- design.md ## G23 — exact validation-table row contract, cross-link annotations, non-goals, and acceptance criteria.
- structure.md ### `skills/using-qrspi/SKILL.md` → Goal IDs {G3, G22, G23, G24, G25, G27, CD-2} — production documentation edit surface for the validation-table row and cross-link annotations.
- structure.md ### `tests/unit/test-config-model-routing.bats` — executable coverage for the schema shape, missing-block validation error, `none`-tier halt smoke test, and G23 validation-table row/cross-link verification.

### Task 19: G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G27]
- **Task type:** code
- **Model:** opus  (sizing_exception → opus)
- **Target files:** `scripts/second-reviewer-available.sh`, `scripts/_host-detect.sh`, `scripts/_resolve-lib.sh`, `skills/goals/SKILL.md`, `skills/using-qrspi/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, `tests/unit/test-second-reviewer-available.bats`, `tests/unit/test-dispatch-companion-availability.bats`, `tests/unit/test-routing-matrix-application.bats`
- **Dependencies:** none. **Blocks:** Task 20.
- **LOC estimate:** ~210
- **Sizing exception:** reusable primitives

**Overview**

Deliver the host-aware second-reviewer availability primitive and migrate the Goals-facing consumer prose away from the Claude-only Codex glob so Copilot CLI users are not silently opted out of second-model review. The task also centralizes host detection and the default second-reviewer matrix lookup so probe and dispatcher-facing tests use the same source of truth. (Why: see goals.md ### G27. Approach: see design.md ## G27.)

**Scope**

- **In:**
  - Create `scripts/_host-detect.sh` with a source-safe `detect_host` function that returns the canonical host identifiers for Copilot CLI, Claude Code, future Codex CLI support, and unknown hosts without filesystem probing or wrapper side effects.
  - Create executable `scripts/second-reviewer-available.sh` with no-arg default-vendor lookup, optional diagnostic vendor override, shared `_resolve-lib.sh` matrix consumption, and exactly one `[second-reviewer-unavailable]` stderr diagnostic on unavailable paths.
  - Extend `scripts/_resolve-lib.sh` with the host × vendor matrix and default-second-reviewer lookup helpers consumed by both the probe and dispatcher-facing routing tests, without a parallel hardcoded host table in the probe.
  - Migrate `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` from the Claude-only `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` glob to `bash scripts/second-reviewer-available.sh`, the vendor-neutral second-model-review question, and `second_reviewer: false` on probe failure.
  - Migrate `skills/reviewer-protocol/SKILL.md` same-surface prose and Expected-Reviewer Matrix field naming from `codex_reviews:` to `second_reviewer:` and make config-validation prose reject stray legacy `codex_reviews:` loudly rather than aliasing it.
  - Add or update the three named bats surfaces to pin probe behavior, shared-matrix use, dispatcher-facing second-reviewer fan-out coverage, and unavailable-second-reviewer halt behavior.

- **Out:**
  - Dispatch script renames, the shared reviewer-dispatch prose include, `await-round.sh` draining, and the twelve review-producing skill dispatch migrations — Task 20 owns that rename-and-dispatch surface.
  - Evergreen-output-rule snippet creation and include-site migration across artifact-producing skills — Task 27 owns that shared G27 sibling surface.
  - Multi-second-reviewer fan-out, per-reviewer-agent second-reviewer toggles, realized-dispatch telemetry, and DeepSeek or other v0.7.3+ default second-reviewer choices — explicitly out of G27 v0.7.2 scope.
  - Enforcing primary-vendor versus second-vendor distinctness inside `second-reviewer-available.sh`; dispatch-time code owns that invariant.

**Definition of done**

- `scripts/_host-detect.sh` is safe to source under `QRSPI_SOURCE_ONLY=1`, performs no filesystem probes or wrapper side effects, and returns `copilot-cli`, `claude-code`, future `codex-cli`, or `unknown` for the supported environment signals.
- `scripts/second-reviewer-available.sh` exists, is executable, accepts an optional vendor override, and uses `_host-detect.sh` plus `_resolve-lib.sh` matrix helpers rather than local host-detection or host × vendor tables.
- The probe exits 0 for Copilot CLI and Claude Code defaults because the shared matrix names `openai-codex` as the default second-reviewer vendor for both hosts.
- Unknown host, missing default vendor, unknown vendor, and unavailable vendor all exit non-zero with exactly one stderr line beginning `[second-reviewer-unavailable]` and naming the detected host plus requested/default vendor.
- `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` contain no live Claude-only Codex availability glob and describe the vendor-neutral second-model-review flow using `bash scripts/second-reviewer-available.sh`.
- `skills/using-qrspi/SKILL.md` documents `second_reviewer:` as the canonical config field and the config-validation prose rejects legacy `codex_reviews:` with a rename-naming diagnostic instead of aliasing it.
- `skills/reviewer-protocol/SKILL.md` no longer contains `codex_reviews` and its Expected-Reviewer Matrix / same-surface prose uses `second_reviewer: true|false`.
- Routing-matrix coverage demonstrates that `second_reviewer: true` can emit primary and second-reviewer entries at the same tier, and unavailable second-reviewer resolution halts with `[second-reviewer-unavailable]` instead of silently falling back to single-reviewer dispatch.

**Test expectations**

- Source-safety and host-signal tests for `_host-detect.sh`: `COPILOT_CLI=1` returns `copilot-cli`, `CLAUDE_PROJECT_DIR` returns `claude-code`, the future Codex signal returns `codex-cli` when implemented, and no known signal returns `unknown`.
- Executability and behavior tests for `scripts/second-reviewer-available.sh`: Copilot CLI and Claude Code default paths exit 0; unknown host, missing default vendor, unknown vendor, and unavailable vendor exit non-zero with one `[second-reviewer-unavailable]` diagnostic containing host and vendor.
- Override-boundary tests prove `second-reviewer-available.sh <vendor>` supports diagnostic vendor override but does not read `model_routing:` or enforce primary/second vendor distinctness.
- Shared-source tests fail if the probe carries a parallel hardcoded host table instead of using `_resolve-lib.sh` host × vendor/default-second-reviewer lookup helpers.
- Grep audits confirm `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` no longer contain `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`.
- Grep audit confirms `grep -nE 'codex_reviews' skills/reviewer-protocol/SKILL.md` returns no matches after the migration.
- Config-validation tests or grep-pinned prose confirm a stray legacy `codex_reviews:` field is rejected loudly with the rename-naming diagnostic and is not aliased to `second_reviewer:`.
- `tests/unit/test-routing-matrix-application.bats` proves same-tier primary + second-reviewer dispatch coverage under `second_reviewer: true` and `[second-reviewer-unavailable]` halt behavior when no eligible second reviewer exists.

**References**

- goals.md ### G27 — problem framing for the Claude-only availability glob and Copilot CLI silent opt-out.
- design.md ## G27 — D1-D6 config rename, probe script, SKILL prose rewrite, runtime routing, matrix extension, and reviewer-protocol matrix sweep.
- structure.md ### `scripts/_resolve-lib.sh` — shared host × vendor matrix and default-second-reviewer lookup helpers.
- structure.md ### `scripts/second-reviewer-available.sh` — probe interface, diagnostic boundary, and tests.
- structure.md ### `scripts/_host-detect.sh` — source-safe canonical host-detection primitive.
- structure.md ### `skills/using-qrspi/SKILL.md` — second-reviewer probe prose and `second_reviewer:` config documentation surface.
- structure.md ### `skills/goals/SKILL.md` — Goals reviewer/second-reviewer consumer surface touched by this migration.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer contract file whose Expected-Reviewer Matrix field naming is swept by G27.
- structure.md ### `tests/unit/test-second-reviewer-available.bats` — direct probe-unit coverage.
- structure.md ### `tests/unit/test-codex-review-codex-availability.bats` — rename-source block for `tests/unit/test-dispatch-companion-availability.bats` availability coverage.
- structure.md ### `tests/unit/test-routing-matrix-application.bats` — same-tier second-reviewer fan-out and unavailable-second-reviewer halt coverage.

### Task 20: G3 dispatch-script rename collapse (`run-codex-review.sh` → `dispatch-agent.sh`; `run-third-party-llm.sh` → `dispatch-companion.sh`; `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`) and per-skill prose migration

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G3]
- **Task type:** code
- **Model:** opus  (sizing_exception → opus)
- **Target files:** rename `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`; rename `scripts/run-third-party-llm.sh` → `scripts/dispatch-companion.sh`; rename `scripts/codex-finding-splitter.sh` → `scripts/third-party-finding-splitter.sh`; modify `scripts/await-round.sh`; create `skills/_shared/reviewer-dispatch-prose.md`; modify `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/structure/SKILL.md`, `skills/phasing/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, `skills/test/SKILL.md`; rename/update `tests/unit/test-run-codex-review.bats` → `tests/unit/test-dispatch-agent.bats`; modify `tests/unit/test-dispatch-sites.bats`
- **Dependencies:** Task 09, Task 11, Task 12, Task 13, Task 19. **Blocks:** T21 (G16 path-filter exfil hardening in `dispatch-agent.sh`).
- **LOC estimate:** ~260
- **Sizing exception:** reusable primitives

**Overview**

Collapse the Codex-named shell review path into vendor-neutral dispatch primitives and one shared reviewer-dispatch prose include, so reviewer output persistence stays inside the script chain instead of repeated orchestrator-side prose. The hard rename and 12-skill consumer migration must land atomically to avoid mixed old/new dispatch paths. (Why: see goals.md ### G3. Approach: see design.md ### CD-1 and design.md ## G3.)

**Scope**

- **In:**
  - Hard-rename the three dispatch scripts to `scripts/dispatch-agent.sh`, `scripts/dispatch-companion.sh`, and `scripts/third-party-finding-splitter.sh` with no compatibility shim or live caller left on the old names.
  - Preserve the universal dispatcher contract: `dispatch-agent.sh` emits one `MODE=first_party ... PROMPT_FILE=<absolute-path>` spec line per first-party reviewer, records third-party entries in `.dispatch-manifest.json`, and routes background jobs through `dispatch-companion.sh`.
  - Implement the companion/splitter chain so `dispatch-companion.sh` launch prints only `JOB_ID=<id>`, `await <job-id>` captures raw reviewer output under `<round-dir>/.dispatch/`, and `third-party-finding-splitter.sh` materializes stable `F01`, `F02`, ... finding files or a clean sentinel.
  - Update `await-round.sh` to drain every pending background manifest entry, invoke `third-party-finding-splitter.sh`, update manifest statuses, write `.round-complete.json`, remove `.dispatch/` only after completion, and remain no-op-safe for first-party-only rounds.
  - Create `skills/_shared/reviewer-dispatch-prose.md` with the locked dispatch-agent invocation, spec-line parsing contract, one-Task-call-per-spec-line iron law, `DISPATCH_FILE=<path>` prompt rule, and unconditional `await-round.sh --round-dir` follow-up.
  - Migrate the 12 listed review-producing `SKILL.md` files to a thin per-skill `$REVIEW_*` preamble plus `!cat skills/_shared/reviewer-dispatch-prose.md`, removing inline Claude/Codex dispatch blocks and old splitter pipe recipes.
  - Rename/update `tests/unit/test-run-codex-review.bats` to `tests/unit/test-dispatch-agent.bats` and update `tests/unit/test-dispatch-sites.bats` for the new dispatch names and shared-include migration.

- **Out:**
  - Evergreen-output-rule snippet creation and include sites that overlap the artifact-producing skill files — T27 owns.
  - G16 path-filter exfil hardening and canonicalize-under-`$REPO_ROOT/` behavior inside `dispatch-agent.sh` — T21 owns after this rename lands.
  - Changing `round-prepare.sh`'s diff-anchor / commit-anchor logic — T12 owns; this task only consumes the existing dispatch-chain integration surface.
  - Adding new vendor transports beyond the renamed companion hook; the G3/CD-1 contract only requires the vendor-neutral dispatch surface.

**Definition of done**

- The old script names are gone as live entry points, and the renamed scripts are the only live dispatch-chain command names used by migrated skill prose and dispatch tests.
- `dispatch-agent.sh` accepts the renamed entry-point invocation, emits exactly one first-party spec line per first-party reviewer, appends first-party/background entries to `.dispatch-manifest.json`, and never requires callers to invoke `run-codex-review.sh`.
- `dispatch-companion.sh` launch writes only `JOB_ID=<id>` to stdout, while `dispatch-companion.sh await <job-id>` writes raw reviewer output to `<round-dir>/.dispatch/<tag>.raw` without echoing payload text to stdout or stderr.
- `third-party-finding-splitter.sh` reads `<round-dir>/.dispatch/<tag>.raw`, writes stable per-finding files or the `NO_FINDINGS` sentinel, and fails loudly for missing flags, missing raw output, missing boundaries, or write errors.
- `await-round.sh` resolves all pending background manifest entries, invokes the renamed splitter for each resolved entry, persists updated manifest and `.round-complete.json` state, removes `.dispatch/` only after completion, and is safe to call when the round is first-party-only.
- `skills/_shared/reviewer-dispatch-prose.md` contains the shared dispatch-agent invocation, spec-line parsing, parallel Task-call, `DISPATCH_FILE=<path>`, iron-law, and await-round follow-up contract.
- Each of the 12 listed `SKILL.md` consumers sets the required `$REVIEW_*` preamble and includes `skills/_shared/reviewer-dispatch-prose.md` at its reviewer-dispatch section, with no remaining inline per-reviewer Claude/Codex dispatch blocks or old splitter pipe recipes.
- The renamed/updated bats coverage pins the new command names, reviewer-dispatch include migration, first-party spec-line parsing, third-party split materialization, and payload-output bounding.

**Test expectations**

- File/rename audit: old script/test paths no longer exist as live files; `scripts/dispatch-agent.sh`, `scripts/dispatch-companion.sh`, `scripts/third-party-finding-splitter.sh`, `skills/_shared/reviewer-dispatch-prose.md`, and `tests/unit/test-dispatch-agent.bats` exist.
- Grep audit for `run-codex-review.sh`, `run-third-party-llm.sh`, and `codex-finding-splitter.sh` in migrated skill prose and dispatch tests returns no live call sites except historical fixtures that explicitly assert those names are absent.
- Dispatch-agent unit coverage verifies renamed entry-point invocation, first-party spec-line parsing, `.dispatch-manifest.json` entries, `PROMPT_FILE=<absolute-path>` emission, and no dependency on `run-codex-review.sh`.
- Companion/splitter fixture coverage verifies `JOB_ID=<id>` launch output, payload-silent await behavior, raw capture under `.dispatch/`, stable `F01`, `F02`, ... materialization, `NO_FINDINGS` sentinel writing, and loud failure for missing flags/raw output/boundaries/write errors.
- `await-round.sh` fixture coverage verifies manifest iteration, pending background drain, splitter invocation, manifest status updates, `.round-complete.json` writing, `.dispatch/` teardown after completion, and first-party-only no-op behavior.
- Shared-prose inspection verifies the locked dispatch-agent command, spec-line parse instructions, one Task call per emitted spec line, `prompt = "DISPATCH_FILE=<PROMPT_FILE-value>"`, and unconditional `scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"` follow-up.
- Consumer-skill grep/lint verifies all 12 listed `SKILL.md` files include `!cat skills/_shared/reviewer-dispatch-prose.md` at reviewer dispatch and no longer contain inline per-reviewer Claude/Codex dispatch blocks or old splitter pipe recipes.
- `tests/unit/test-dispatch-sites.bats` and the renamed `tests/unit/test-dispatch-agent.bats` cover the new command names, include migration, first-party dispatch parsing, third-party split materialization, and bounded stdout/stderr so raw third-party reviewer text cannot leak into orchestrator output.

**References**

- goals.md ### G3 — problem framing for shell-pipeline splitter collapse and silent finding-loss risk.
- design.md ### CD-1 — universal dispatch architecture, rename inventory, shared reviewer-dispatch prose body, and acceptance criteria.
- design.md ## G3 — G3-specific vendor-neutral outcome and acceptance layered on CD-1.
- structure.md ### `scripts/run-codex-review.sh` — rename source and post-rename `dispatch-agent.sh` responsibilities/interface.
- structure.md ### `scripts/run-third-party-llm.sh` — rename source and `dispatch-companion.sh` launch/await contract.
- structure.md ### `scripts/codex-finding-splitter.sh` — rename source and `third-party-finding-splitter.sh` raw-output split contract.
- structure.md ### `scripts/await-round.sh` — manifest-driven async drain and output-bound contract.
- structure.md ### `skills/_shared/reviewer-dispatch-prose.md` — shared snippet body and required hook-point include.
- structure.md ### `skills/goals/SKILL.md` — representative 12-consumer reviewer-dispatch preamble/include migration pattern.
- structure.md ### `tests/unit/test-dispatch-sites.bats` — consumer include-site regression coverage.
- structure.md ### `tests/unit/test-run-codex-review.bats` — test rename source for `tests/unit/test-dispatch-agent.bats`.

### Task 21: G16 path-filter exfil hardening in `dispatch-agent.sh`

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G16]
- **Task type:** code
- **Model:** opus
- **Target files:** `scripts/dispatch-agent.sh`; `tests/unit/test-dispatch-agent.bats`; `agents/qrspi-implementer.md`; `scripts/dispatch-companion.sh` (audit/comment only if the direct companion entry point can accept raw file paths)
- **Dependencies:** Task 20
- **LOC estimate:** ~120
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Harden the post-rename dispatch wrapper so every prompt-ingested file path is canonicalized under `$REPO_ROOT` before its content can enter a sanctioned LLM channel. The task also adds defense-in-depth implementer prose and audits the companion dispatcher for the same raw-path surface. (Why: see goals.md ### G16. Approach: see design.md ## G16.)

**Scope**

- **In:**
  - Add a single fail-closed `assert_path_under_repo_root <label> <abs-path>` guard in `scripts/dispatch-agent.sh`, inherited from the pre-rename `scripts/run-codex-review.sh` design, that canonicalizes with `realpath` / `readlink -f` and rejects paths whose canonical target is not under canonical `$REPO_ROOT/`.
  - Apply the guard after file-existence checks and before any prompt emission or `cat` read for the agent file and every `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` path family.
  - Preserve legitimate repo-local `--dry-run` behavior and the existing first-party spec-line / prompt-file contract.
  - Rename/extend the existing wrapper test coverage in `tests/unit/test-dispatch-agent.bats` to pin out-of-repo absolute paths, symlink-out-of-repo paths, readable out-of-repo companion files, guard coverage for all four path-argument families, canonicalization-failure diagnostics, and valid repo-local pass cases.
  - Insert the `## Orchestrator-Only Scripts (Bash Allowlist)` section at the top of `agents/qrspi-implementer.md`, using the post-rename script names `scripts/dispatch-agent.sh` and `scripts/dispatch-companion.sh`, and forbid relative, absolute, alias, or shell-expansion invocation shapes.
  - Audit `scripts/dispatch-companion.sh`: if it accepts raw file paths directly, share the same repo-boundary guard; otherwise document that it receives assembled prompt data rather than arbitrary file paths.

- **Out:**
  - Dispatch-script rename collapse, universal routing behavior, and per-skill prose migration — T20 owns; this task works against the post-rename `dispatch-agent.sh` / `dispatch-companion.sh` surface.
  - Broader all-`scripts/` sanctioned-channel exfil sweeps beyond the direct companion entry point — deferred to the v0.7.3+ open question in design.md ## G16.
  - Adding a full positive command-family allowlist to `agents/qrspi-implementer.md` — design.md ## G16 locks the narrow B1 restriction only.
  - Changes to `agents/qrspi-test-writer.md`, `skills/reviewer-protocol/SKILL.md`, or `skills/using-qrspi/SKILL.md` — design.md ## G16 explicitly excludes them from this remediation.

**Definition of done**

- `scripts/dispatch-agent.sh` rejects any canonicalized prompt-ingested path outside canonical `$REPO_ROOT/` with non-zero exit and a clear stderr diagnostic containing `resolves outside repository` where applicable.
- Symlinks whose lexical path appears allowed but whose canonical target is outside the repository are rejected before prompt files are emitted or file contents are read.
- Readable out-of-repo `--companion` paths fail by boundary check rather than by missing-file behavior.
- `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` all pass through the same repo-boundary enforcement point; valid repo-local inputs for each continue to pass `--dry-run`.
- Canonicalization failures fail closed with non-zero exit and a clear stderr diagnostic; no raw path is read with `cat` before existence and repo-boundary checks pass.
- `agents/qrspi-implementer.md` contains a top-of-body `## Orchestrator-Only Scripts (Bash Allowlist)` section forbidding implementers from invoking `scripts/dispatch-agent.sh` or `scripts/dispatch-companion.sh` under relative, absolute, alias, or shell-expansion path shapes.
- `scripts/dispatch-companion.sh` is audited for direct raw-file-path inputs and either shares the guard for any such inputs or documents that it receives assembled prompt data rather than arbitrary file paths.

**Test expectations**

- `tests/unit/test-dispatch-agent.bats` includes a regression where `bash scripts/dispatch-agent.sh ... --subject-code /etc/hosts --dry-run` exits non-zero and stderr contains `resolves outside repository`.
- Add a symlink regression proving a path whose lexical location looks allowed but whose canonical target is outside `$REPO_ROOT` exits non-zero with the same diagnostic before any prompt file is emitted.
- Add a readable out-of-repo `--companion` regression that exits non-zero with `resolves outside repository`, proving the guard is a boundary check rather than a missing-file side effect.
- Use tests or table-driven coverage to pin that `--artifact-body` and `--diff-file` receive the same `assert_path_under_repo_root` enforcement as `--subject-code` and `--companion`.
- Include valid repo-local artifact, companion, subject-code, and diff path dry-run cases that preserve the existing first-party spec-line / prompt-file contract.
- Include a canonicalization-failure check that fails closed with a clear stderr diagnostic and confirms no raw path is read before existence and repo-boundary checks pass.
- Grep/structure inspection confirms `agents/qrspi-implementer.md` has the required allowlist section using post-rename script names and covering relative, absolute, alias, and shell-expansion path shapes.
- Audit inspection confirms `scripts/dispatch-companion.sh` either uses the shared boundary guard for direct raw-file-path inputs or carries the documented no-raw-path comment.

**References**

- goals.md ### G16 — problem framing for sanctioned-channel exfil through arbitrary wrapper path inputs.
- design.md ## G16 — strict `$REPO_ROOT/` canonicalization, narrow implementer allowlist, regression tests, and companion audit decisions.
- structure.md ### `scripts/run-codex-review.sh` → Slice 1.4 rename to `scripts/dispatch-agent.sh`; responsibility includes G16 boundary guard on every prompt-ingested path.
- structure.md ### `tests/unit/test-run-codex-review.bats` → rename to `tests/unit/test-dispatch-agent.bats`; responsibility lists the G16 regression coverage.
- structure.md ### `agents/qrspi-implementer.md` — top-of-body orchestrator-only script allowlist insertion site and post-rename-name note.
- structure.md ### `scripts/run-third-party-llm.sh` → rename to `scripts/dispatch-companion.sh`; companion dispatcher surface to audit for raw-path inputs.

### Task 24: CD-4 `detect-interaction-mode.sh` helper

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G6, G11, G12]
- **Task type:** code
- **Model:** sonnet
- **Target files:** create `scripts/detect-interaction-mode.sh`; create `tests/unit/test-detect-interaction-mode.bats`
- **Dependencies:** Task 02
- **LOC estimate:** ~110

**Overview**

Create the round-start interaction-mode detector that centralizes host-specific auto/interactive detection behind a stdout-only helper and dedicated bats coverage. This lets apply-fix orchestration decide halt, rescue, or safe-default behavior without duplicating host signals in skill prose or agent bodies. (Why: see goals.md ### G6, goals.md ### G11, goals.md ### G12. Approach: see design.md ### CD-4 → I.7 and structure.md ### `scripts/detect-interaction-mode.sh`.)

**Scope**

- **In:**
  - Create `scripts/detect-interaction-mode.sh` as a no-argument helper that emits one `KEY=VALUE` pair per line and exits 0 for successful detection, including safe-default branches.
  - Implement the three documented detection protocols: `shell-verdict`, `llm-context`, and `user-override-only`, including Copilot CLI, Claude Code, unknown-host, override, and safe-default behavior from design.md ### CD-4 → I.7.
  - Enforce `QRSPI_INTERACTION_MODE=auto|interactive` as the explicit override; invalid override values and positional arguments fail loud with diagnostics.
  - Keep the helper stdout/stderr-only: it never writes `.interaction-mode-audit.json` or any other file.
  - Include the required script-header material: locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block.
  - Create `tests/unit/test-detect-interaction-mode.bats` to pin host branches, override behavior, invalid input failures, stdout parseability, no-file-write behavior, and grep regression coverage for host-specific literals.

- **Out:**
  - Verifier fan-in kept-set computation, `.verifier-fan-in-audit.json`, and verifier-dispatch prose — T02 owns.
  - Reviewer first-party / third-party emission contract splitting and wrong-channel reviewer output handling — T03 owns.
  - Verifier sidecar extension locking and score-sidecar canonicalization — T06 owns.
  - Writing `<round-dir>/.interaction-mode-audit.json` and caching the resolved tuple in orchestration — outside this helper; the script only returns the protocol the orchestrator consumes.
  - Adding host-specific auto-mode literals to SKILL prose, agent bodies, or shared snippets — explicitly prohibited by the encapsulation rule.

**Definition of done**

- `scripts/detect-interaction-mode.sh` exists, accepts no positional arguments, and fails non-zero with usage diagnostics when any argument is supplied.
- With `COPILOT_CLI=1`, the helper emits `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, and an instruction for inspecting the active context for the Copilot autopilot marker and sentence.
- With Claude Code host signals and no `COPILOT_CLI`, the helper emits `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, and an instruction for inspecting active context for the Claude auto-mode marker.
- With no recognized host and no override, the helper emits `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, and evidence naming the safe default.
- With `QRSPI_INTERACTION_MODE=auto` or `QRSPI_INTERACTION_MODE=interactive`, the override wins and the helper emits a direct `VERDICT` with evidence naming the override value.
- With any other `QRSPI_INTERACTION_MODE` value, the helper exits non-zero and names the allowed values; it does not silently coerce the value to interactive.
- The helper never writes `.interaction-mode-audit.json` or any other file.
- The script header contains the locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block required by design.md ### CD-4 → I.7.
- Shell output is parseable as one `KEY=VALUE` pair per line, contains no placeholder values, and uses only `shell-verdict`, `llm-context`, or `user-override-only` for `DETECTION_TYPE`.
- Host-specific auto-mode literals appear only in `scripts/detect-interaction-mode.sh` and this task's dedicated test fixtures; consumer skill prose and agent bodies do not gain those literals.

**Test expectations**

- Bats tests cover the Copilot CLI branch (`COPILOT_CLI=1`) and assert `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, and the expected Copilot context-inspection instruction.
- Bats tests cover the Claude Code branch with no `COPILOT_CLI` and assert `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, and the expected Claude context-inspection instruction.
- Bats tests cover unknown host with no override and assert `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, and safe-default evidence.
- Bats tests cover `QRSPI_INTERACTION_MODE=auto` and `QRSPI_INTERACTION_MODE=interactive` and assert the override verdict and evidence win.
- Bats tests cover invalid `QRSPI_INTERACTION_MODE` values and positional arguments as non-zero failures with diagnostics.
- Tests verify the helper is stdout/stderr-only by asserting no `.interaction-mode-audit.json` or other files are created during execution.
- Header inspection asserts the locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block are present.
- Grep-based regression coverage permits host-specific auto-mode literals only in `scripts/detect-interaction-mode.sh` and `tests/unit/test-detect-interaction-mode.bats` fixtures, and rejects those literals in consumer skill prose or agent bodies.
- Output-shape tests assert every stdout line is a `KEY=VALUE` pair, no placeholder values are present, and `DETECTION_TYPE` is one of `shell-verdict`, `llm-context`, or `user-override-only`.

**References**

- goals.md ### G6 — disk-write / chat-side fragility problem framing that CD-4 avoids extending into interaction-mode detection.
- goals.md ### G11 — sidecar pipeline drift problem framing; Task 24 stays limited to the interaction-mode helper used around CD-4 orchestration.
- goals.md ### G12 — fan-in automation motivation; Task 24 supports the orchestration mode decision around that automated path.
- design.md ### CD-4 → I.7 — locked platform directory, override chain, stdout protocol, audit-writer boundary, encapsulation rule, caching rule, and acceptance criteria for interaction-mode detection.
- design.md ## G6 — reviewer disk-write reliability context resolved structurally elsewhere; this task only prevents host-specific detection prose drift.
- design.md ## G11 — sidecar extension + orchestrator-bypass context resolved by CD-4 verifier fan-in, not by this helper.
- design.md ## G12 — verifier-fan-in script context that Task 02 owns; Task 24 only supplies the round-start mode detector.
- structure.md ### `scripts/detect-interaction-mode.sh` — per-file responsibility, interface, lifted header content, outline-only sections, and grep-lint surface.
- structure.md ### 12. Interaction-mode detector — cross-cutting schema for stdout shapes, override chain, locked platform directory pointer, and audit-file boundary.

### Task 25: G31 prompt-prose primitives (`prompt-prose-detection` + `-writer-addition` + `-reviewer-addition` + `prompt-design-rules` + new prompt-prose-writer SKILL + new prompt-prose-reviewer SKILL + docs rename)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G31]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** skills/_shared/prompt-prose-detection.md (create), skills/_shared/prompt-prose-writer-addition.md (create), skills/_shared/prompt-prose-reviewer-addition.md (create), skills/_shared/prompt-design-rules.md (create-via-migrate from docs/prompt-design-guide.md), skills/prompt-prose-writer/SKILL.md (create), skills/prompt-prose-reviewer/SKILL.md (create), docs/prompt-design-guide.md (delete post-migration)
- **Dependencies:** none. **Blocks:** T26 (G31 `!cat` include sites + skill-frontmatter preloads), T39 (G32 build pipeline's defensive copy of `skills/_shared/prompt-prose-detection.md`).
- **LOC estimate:** ~340
- **Sizing exception:** reusable primitives

**Overview**

Create the shared prompt-prose primitives — three import snippets, two wrapper SKILLs, and a migrated rules file — that make the G31 prompt-prose-coverage contract enforceable across the plugin. All downstream G31 tasks (T26-T31) consume these primitives; without them, every consumer site would duplicate prose inline or reference runtime contracts that do not exist yet. (Why: see goals.md ### G31. Approach: see design.md ## G31.)

**Scope**

- **In:**
  - Author the three new shared snippet files at the canonical `skills/_shared/` paths, with bodies lifted **verbatim** from design.md ## G31 File 1, File 2, and File 3 respectively.
  - Author the two wrapper SKILLs at `skills/prompt-prose-writer/SKILL.md` and `skills/prompt-prose-reviewer/SKILL.md` with `description:` frontmatter plus `!cat` preload chains in the order specified by design.md ## G31 File 4 / File 5 (cross-check against structure.md per-file blocks).
  - Migrate `docs/prompt-design-guide.md` to `skills/_shared/prompt-design-rules.md` using `git mv` so `git log --follow` traces history through the rename, then apply the 8 inline refresh edits A-H named in design.md ## G31 (modern-negation positive-substitute principle; CD-2 named antagonist patterns; Evergreen Litmus Test; Anchor phrases principle; vendor-neutral R5 wording; remove external `general2/...` source paths; refresh `Last applied:` / May 2026 model annotations; compaction-resilient prompt-design principle).
  - Delete the old `docs/prompt-design-guide.md` path in the same commit as the migration (single source of truth).

- **Out:**
  - Adding `!cat` include sites in Plan / Design / reviewer-agent consumers — T26 owns.
  - Wiring the wrapper SKILLs into agent frontmatter `skills:` preload lists — T27-T31 own per consumer.
  - Authoring new rule content beyond the 8 refresh edits A-H — the rules file body is otherwise migrated as-is.
  - Editing the fast-path glob list in design.md ## G31 — already authoritative there; not re-authored here.

**Definition of done**

- All 6 new files exist at their canonical paths; `docs/prompt-design-guide.md` is deleted.
- Snippet bodies (Files 1-3) match design.md ## G31 File 1 / File 2 / File 3 byte-for-byte (modulo any one-line header comment specified by the corresponding structure.md per-file block).
- Wrapper SKILLs (Files 4-5) carry `description:` frontmatter and the `!cat` preload directives in the exact order specified by design.md ## G31 + structure.md per-file blocks.
- `skills/_shared/prompt-design-rules.md` carries all 8 refresh edits A-H; `git log --follow` reaches the historical `docs/prompt-design-guide.md` commits.
- No stale `docs/prompt-design-guide.md` references remain in the repo (grep returns zero matches outside historical CHANGELOG entries).
- Each addition snippet (Files 2-3) pairs negative guidance with a positive substitute (per R5 / modern-negation).
- The detection snippet (File 1) clearly distinguishes universal content-semantic detection from the qrspi-plus-internal fast-path globs.
- References to the rules-file location use exactly the anchor phrase `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)`.

**Test expectations**

- File-existence checks for all 6 new files; deletion check for `docs/prompt-design-guide.md`.
- Verbatim diff of File 1 / File 2 / File 3 bodies vs design.md ## G31 File 1 / File 2 / File 3 — exact match.
- Frontmatter inspection of Files 4-5: `description:` field present; `!cat` directives appear in the expected order.
- `git log --follow skills/_shared/prompt-design-rules.md` reaches commits older than the rename.
- Grep-based audit confirms all 8 refresh edits A-H are present (anchor phrases per edit listed in design.md ## G31).
- Apply R1-R7 + cross-cutting principles from the migrated rules file to the new snippets themselves (meta-acceptance pass).
- Anchor-phrase audit: rules-file location references match the exact form named in DoD.

**References**

- goals.md ### G31 — problem framing (prompt-prose-coverage contract not yet enforceable).
- design.md ## G31 — Files 1-5 detailed solutions + Additions A-D + Distribution Table (single sweep point for completeness + drift detection).
- structure.md per-file blocks for the 6 new files (each tagged `**Goal IDs:** {G31}`).
- structure.md `## Hook-Point Cross-Slice Index` → G31 prompt-prose `!cat` include sites (downstream consumer context).

### Task 26: G31 prompt-prose include sites across Design, Plan, and reviewer agents

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G31]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** `skills/design/SKILL.md`, `skills/plan/SKILL.md`, `agents/qrspi-implementer-lightweight.md`, `agents/qrspi-design-reviewer.md`, `agents/qrspi-design-scope-reviewer.md`, `agents/qrspi-plan-test-coverage-reviewer.md`
- **Dependencies:** Task 25
- **LOC estimate:** ~140

**Overview**

Plumb the G31 prompt-prose primitives from T25 into the Design, Plan, lightweight-implementer, and reviewer surfaces that classify, author, or review prompt prose without copying the shared rule prose into each consumer. This task enforces the shared detection/writer/reviewer architecture at the listed include/preload sites while preserving prompt prose as a lightweight, non-TDD deliverable class. (Why: see goals.md ### G31. Approach: see design.md ## G31.)

**Scope**

- **In:**
  - Add the Design authoring-step includes in `skills/design/SKILL.md`: `!cat skills/_shared/prompt-prose-detection.md` followed by `!cat skills/_shared/prompt-prose-writer-addition.md` at the `<!-- prose-design: ... -->` prompt-prose authoring site.
  - Replace `skills/plan/SKILL.md` Per-Task Classification Step 1 with Addition A, including the canonical detection `!cat`, so prompt prose classifies as `task_type: lightweight` by content semantics rather than path-only heuristics.
  - Insert detection + writer-addition + Addition B at both `skills/plan/SKILL.md` writer-subagent dispatch payload sites before the standard Test-Expectations instructions, while leaving the post-approval-split sub-subagent outside this clause.
  - Append `prompt-prose-writer` to `agents/qrspi-implementer-lightweight.md` `skills:` frontmatter and avoid duplicate body prose for the shared writer rules.
  - Append `prompt-prose-reviewer` to `agents/qrspi-design-reviewer.md` `skills:` frontmatter and add Addition D in the review-procedure body as the design.md per-block refinement after preload-triggered shared reviewer context.
  - Keep `agents/qrspi-design-scope-reviewer.md` aligned with its structure-defined include behavior while not restating G31 prompt-prose rule prose verbatim.
  - Add Addition C at the top of `agents/qrspi-plan-test-coverage-reviewer.md` review procedure, keep `prompt-prose-reviewer` absent from its `skills:` frontmatter, and silently skip `task_type: lightweight` tasks.

- **Out:**
  - Creating or migrating the G31 primitive files (`prompt-prose-detection`, `prompt-prose-writer-addition`, `prompt-prose-reviewer-addition`, `prompt-design-rules`, and wrapper SKILLs) — T25 owns.
  - Refreshing the prompt-design rules file and deleting `docs/prompt-design-guide.md` — T25 owns.
  - Adding Evergreen-Output Rule include sites in overlapping Design/Plan skills — T27 owns.
  - Adding Multi-Actor Flow Check include sites in overlapping Plan surfaces — T28 owns.
  - Implementing the Design altitude-boundary primitive and scope-reviewer `!cat` insertion — T29 owns; this task only prevents duplicate G31 prompt-prose rule prose in `agents/qrspi-design-scope-reviewer.md`.
  - Adding prompt-prose reviewer preloads to reviewer agents not listed in this task's Target files.
  - Adding executable RED tests for prompt prose; prompt-prose verification is rules-application review, not TDD execution.

**Definition of done**

- `skills/design/SKILL.md` contains the two G31 authoring-step `!cat` directives in the required order: detection, then writer-addition.
- `skills/plan/SKILL.md` has Replacement-not-additive Addition A at Per-Task Classification Step 1 and both writer-subagent dispatch payload sites carry detection + writer-addition + Addition B before standard Test-Expectations instructions.
- `agents/qrspi-implementer-lightweight.md` frontmatter preloads `[implementer-protocol, prompt-prose-writer]` and does not duplicate the shared writer rules in its body.
- `agents/qrspi-design-reviewer.md` frontmatter preloads `prompt-prose-reviewer` and its body carries Addition D after the preload-triggered shared reviewer context.
- `agents/qrspi-design-scope-reviewer.md` does not restate G31 prompt-prose rule prose and remains compatible with its separately-owned structure-defined include behavior.
- `agents/qrspi-plan-test-coverage-reviewer.md` begins its review-procedure section with Addition C, has no `prompt-prose-reviewer` preload, and skips lightweight tasks instead of emitting missing-RED-test findings.
- Every consumer site uses canonical `!cat` directives or `skills:` preload of the appropriate wrapper SKILL; no consumer restates the shared prompt-prose rule prose verbatim.
- Each inline addition preserves the relevant anchor behavior from design.md ## G31: Plan Step 1 is replacement-not-additive, positive-substitute principle appears in inline additions, and agent files use `skills:` preload where `!cat` is not the mechanism.

**Test expectations**

- Grep `skills/design/SKILL.md` for `!cat skills/_shared/prompt-prose-detection.md` immediately followed by `!cat skills/_shared/prompt-prose-writer-addition.md` at the `<!-- prose-design: ... -->` authoring step.
- Grep/diff `skills/plan/SKILL.md` to verify the old path-glob-only Step 1 paragraph was replaced, not appended to, by Addition A including the canonical detection `!cat`.
- Grep both `skills/plan/SKILL.md` writer-subagent dispatch payload sites for detection + writer-addition + Addition B before the standard Test-Expectations instructions; verify the post-approval-split sub-subagent lacks Addition B.
- Inspect `agents/qrspi-implementer-lightweight.md` frontmatter for `skills: [implementer-protocol, prompt-prose-writer]` and grep the body to confirm it does not copy the shared writer-rule prose.
- Inspect `agents/qrspi-design-reviewer.md` frontmatter for `prompt-prose-reviewer`; grep the body for Addition D anchor phrases `one strong signal but not the only one` and `content semantics determine the call` after the preload context.
- Inspect `agents/qrspi-design-scope-reviewer.md` to confirm it has no verbatim G31 prompt-prose rule-prose copy while preserving its structure-defined include behavior.
- Inspect `agents/qrspi-plan-test-coverage-reviewer.md` to confirm Addition C's `Scope: only \`task_type: code\` tasks.` appears at the top of the review-procedure section and `prompt-prose-reviewer` is absent from `skills:` frontmatter.
- Run a grep audit across the six target files confirming shared prompt-prose bodies are consumed only by canonical `!cat` or `skills:` preload and not duplicated verbatim.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application, including R5 shared-spine/DRY, anchor-phrase usage for snippet/include paths, positive-substitute principle in inline additions, agent `skills:` preload use, and Plan Step 1 replacement-not-additive behavior per design.md ## G31.

**References**

- goals.md ### G31 — problem framing for prompt-prose review coverage gaps across SKILL.md files, agents, and `design.md` prose-design blocks.
- design.md ## G31 — shared prompt-prose architecture, Additions A-D, Distribution Table, explicit non-consumers, and TDD/lightweight boundary.
- structure.md ### `skills/design/SKILL.md` — Consumer #3 authoring-step detection + writer-addition include site.
- structure.md ### `skills/plan/SKILL.md` — Consumer #1 Addition A and Consumer #2 writer-subagent Addition B include sites.
- structure.md ### `agents/qrspi-implementer-lightweight.md` — Consumer #4 `prompt-prose-writer` frontmatter preload.
- structure.md ### `agents/qrspi-design-reviewer.md` — Consumer #6 `prompt-prose-reviewer` preload plus Addition D refinement.
- structure.md ### `agents/qrspi-design-scope-reviewer.md` — separately-owned scope-reviewer include behavior that must not be polluted with duplicated G31 rule prose.
- structure.md ### `agents/qrspi-plan-test-coverage-reviewer.md` — Consumer #9 Addition C standalone scope guard and no-wrapper-preload invariant.
- structure.md ## Hook-Point Cross-Slice Index → G31 prompt-prose `!cat` include sites — cross-file sweep point for prompt-prose include/preload drift detection.

### Task 27: CD-2 evergreen-output-rule shared snippet and include sites

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G3, G4, G22, G27]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** `skills/_shared/evergreen-output-rule.md` (create), `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/structure/SKILL.md`, `skills/phasing/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, `skills/using-qrspi/SKILL.md`
- **Dependencies:** none
- **LOC estimate:** ~120

**Overview**

Create the canonical Evergreen-Output Rule snippet and include it in every artifact-producing skill so approved run artifacts describe current decision state rather than dialogue exhaust, drafting history, or rationale-about-the-rationale. The shared snippet keeps this artifact-output quality rule DRY across the highest-volume authoring surfaces and prevents divergent paraphrases as prompt prose evolves. (Why and locked prose: see design.md ### CD-2. Related drift surfaces: see goals.md ### G3, goals.md ### G4, goals.md ### G22, goals.md ### G27.)

**Scope**

- **In:**
  - Create `skills/_shared/evergreen-output-rule.md` as the single source of truth for the Evergreen-Output Rule, using the locked prose from design.md ### CD-2 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
  - Add `!cat skills/_shared/evergreen-output-rule.md` to each artifact-producing consumer in the Target files list: goals, questions, research, design, structure, phasing, plan, parallelize, and replan.
  - Place each include at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location) per structure.md ## Hook-Point Cross-Slice Index → CD-2 evergreen-output-rule `!cat` include sites.
  - Preserve the load-bearing anchor phrases and rule shape: `Litmus test (apply to every paragraph before write)`, `dialogue exhaust`, `Named antagonist patterns — strip on sight, substitute as shown`, the two ordered filters, and the exclusions parenthetical.
  - Keep consumer SKILL.md files DRY: the rule text is included with `!cat`, not copied or paraphrased inline.
  - Author a one-line by-reference pointer to `skills/_shared/evergreen-output-rule.md` from the artifact-quality section of `skills/using-qrspi/SKILL.md` (pointer-only, NOT a `!cat` include, since `using-qrspi` is not an artifact-producing skill — per design.md ### CD-2 acceptance #5 and structure.md ### `skills/using-qrspi/SKILL.md` per-file block).
  - Author the reviewer-protocol enforcement clause in `skills/reviewer-protocol/SKILL.md` so reviewer subagents surface a finding when an artifact carries any of the CD-2 named antagonist patterns (session/drafting notes, version-history narration, inside baseball, compaction-loss recovery, failure-modes-prevented lists, and any other pattern named in the locked `evergreen-output-rule.md` snippet). The clause is inserted alongside (NOT replacing) existing finding-schema/`change_type` requirements and uses the canonical `change_type: style` or `change_type: clarity` enum value per the locked snippet's filter taxonomy.

- **Out:**
  - Canonical cumulative diff helpers, round preparation, and G4 anchor-manifest refreshes — T12 owns.
  - Unified `model_routing:` schema, agent `tier:` migration, and Plan/Test `model:` → `tier:` prose migration — T16 owns.
  - Host-aware second-reviewer availability helper and `second_reviewer:` consumer migration — T19 owns.
  - Dispatch script renames, shared reviewer-dispatch prose, and review-producing skill dispatch include migration — T20 owns.

**Definition of done**

- `skills/_shared/evergreen-output-rule.md` exists at the canonical path and contains the locked Evergreen-Output Rule prose from design.md ### CD-2 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
- The snippet preserves the required anchor phrases, the two ordered litmus-test filters, the exclusions parenthetical, and the named antagonist-pattern table.
- Every artifact-producing consumer in the Target files list contains a `!cat skills/_shared/evergreen-output-rule.md` include at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location).
- No consumer SKILL.md in scope embeds a copied or paraphrased version of the Evergreen-Output Rule; the shared snippet is the only inclusion path.
- The snippet states the rule positively as current-state artifact writing, not only as a ban on history narration.
- The implementation satisfies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), including R5 DRY and positive-substitute guidance.
- `skills/using-qrspi/SKILL.md` carries exactly one by-reference pointer line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality section, with no `!cat` include of the snippet body (per CD-2 acceptance #5).
- `skills/reviewer-protocol/SKILL.md` requires reviewer subagents to surface a finding when an artifact carries any CD-2 named antagonist pattern, alongside (NOT replacing) the existing finding-schema/`change_type` requirements.

**Test expectations**

- File-existence check confirms `skills/_shared/evergreen-output-rule.md` exists.
- Verbatim content check compares `skills/_shared/evergreen-output-rule.md` against the locked prose in design.md ### CD-2 component 3 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
- Grep audit confirms each target consumer contains exactly the shared include line `!cat skills/_shared/evergreen-output-rule.md` at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location).
- Grep audit confirms the in-scope consumer SKILL.md files do not inline-copy the rule's anchor phrases (`Litmus test (apply to every paragraph before write)`, `dialogue exhaust`, `Named antagonist patterns — strip on sight, substitute as shown`) outside the shared snippet include path.
- Anchor-phrase audit confirms the snippet preserves the required phrases, the two ordered filters, and the exclusions parenthetical.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` to verify R5 DRY, positive-substitute framing, anchor-phrase preservation, and load-bearing clarity for the ordered filters and exclusions parenthetical.
- Grep audit of `skills/using-qrspi/SKILL.md` confirms exactly one pointer line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality section and zero occurrences of `!cat skills/_shared/evergreen-output-rule.md` (pointer-only contract per CD-2 acceptance #5).
- Grep audit of `skills/reviewer-protocol/SKILL.md` confirms the antagonist-pattern enforcement clause is present and references the CD-2 named patterns vocabulary from the locked `skills/_shared/evergreen-output-rule.md` snippet (no duplicated antagonist-pattern list — the reviewer clause cites the snippet rather than copying it).

**References**

- goals.md ### G3 — shell-pipeline splitter collapse drift surface that motivates shared, vendor-neutral skill prose instead of repeated inline rituals.
- goals.md ### G4 — canonical diff-helper drift surface that motivates replacing repeated orchestrator prose with reusable primitives.
- goals.md ### G22 — model-routing schema drift surface that motivates single-source prose across multiple consumers.
- goals.md ### G27 — Goals-side consumer drift surface that motivates canonical helper/prose reuse.
- design.md ### CD-2 — Evergreen-Output Rule scope, locked snippet prose, consumer list, and acceptance criteria.
- design.md ## G3 / design.md ## G4 / design.md ## G22 / design.md ## G27 — related design context for the Goal IDs carried by this cross-cutting task.
- structure.md ### `skills/_shared/evergreen-output-rule.md` — source file block and full-file-body lift from design.md ### CD-2.
- structure.md ## Hook-Point Cross-Slice Index → CD-2 evergreen-output-rule `!cat` include sites — consumer placement table for the nine artifact-producing SKILL.md files.

### Task 28: CD-3 multi-actor-flow-check shared snippet and include sites

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G1, G30, G33]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** create `skills/_shared/multi-actor-flow-check.md`; modify `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/implement/SKILL.md`
- **Dependencies:** none
- **LOC estimate:** ~110

**Overview**

Create the shared Multi-Actor Flow Check snippet and include it in the four downstream skills that turn design decisions into file maps, task specs, parallelization plans, or implementation dispatches. The task makes missing multi-actor choreography a hard stop instead of letting downstream consumers invent hand-offs. (Why: see goals.md ### G1 and design.md ## G1 → Altitude Sub-Rule C. Contract: see design.md ### CD-3.)

**Scope**

- **In:**
  - Author `skills/_shared/multi-actor-flow-check.md` as the canonical shared snippet, with the locked body from design.md ### CD-3 / structure.md ### `skills/_shared/multi-actor-flow-check.md`.
  - Preserve the snippet's self-contained actor definition, six choreography elements, STOP diagnostic, Backward Loops / documented-assumption alternatives, and Iron law.
  - Add exactly one `!cat skills/_shared/multi-actor-flow-check.md` include to each consumer: `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, and `skills/implement/SKILL.md`.
  - Place each include at that skill's `## Multi-Actor Flow Check` / per-decision authoring gate so Structure, Plan, Parallelize, and Implement each run the check independently.

- **Out:**
  - Replacing the Design skill template, including G1's per-goal block shape and Altitude Sub-Rules A-D — T30 owns.
  - Adding the Design simple-language dialogue rule and its unit-test assertions — T31 owns.
  - Adding Goals/Design incremental persistence, resume-after-compaction behavior, and finalize semantics — T32 owns.
  - Refactoring G1 Sub-Rule C itself to `!cat` this snippet — explicitly optional follow-up in design.md ### CD-3, not required for v0.7.2.
  - Editing unrelated sections in the consumer SKILL.md files, including reviewer-dispatch, evergreen-output, schema/tier, and per-task review-cycle surfaces owned by other tasks.

**Definition of done**

- `skills/_shared/multi-actor-flow-check.md` exists and contains the locked CD-3 snippet content, including the anchor phrases `Multi-Actor Flow Check`, `where "actor" means anything that performs an operation and hands off to another`, `STOP`, and `Iron law: silently inventing a missing hand-off is a contract violation`.
- The snippet enumerates all six required choreography elements with their bolded labels: `Actor inventory`, `Sequence of operations`, `Per-step inputs and outputs`, `Consumer identification`, `Loud-failure paths`, and `Context-cost call-out`.
- Each of the four consumer SKILL.md files carries exactly one `!cat skills/_shared/multi-actor-flow-check.md` line at the multi-actor-flow checking gate.
- Consumer SKILL.md files do not embed copied versions of the six-element list or diagnostic template; `!cat` is the only inclusion path.
- The snippet is self-contained and does not reference `Sub-Rule C`, `G1`, or any `GNN` identifier.
- Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), and reviewer verifies the same content-semantic rules: R1 cuts non-actionable history and metadata from the snippet; R2 preserves the non-obvious rationale for stopping instead of guessing; R3 keeps the load-bearing STOP and Iron law visible; R4 limits examples to the single diagnostic template; R5 uses the shared snippet as the reusable spine instead of duplicating six-element prose in consumers; R6 introduces no Mermaid or diagram-only content; R7 preserves lexical anchors such as `actor`, `Actor inventory`, `Consumer identification`, `Loud-failure paths`, `Context-cost call-out`, `STOP`, and `Backward Loops`.

**Test expectations**

- File-existence check confirms `skills/_shared/multi-actor-flow-check.md` is present.
- Verbatim diff confirms `skills/_shared/multi-actor-flow-check.md` matches the locked snippet in design.md ### CD-3 / structure.md ### `skills/_shared/multi-actor-flow-check.md`.
- Grep audit confirms all four consumers contain exactly one `!cat skills/_shared/multi-actor-flow-check.md` line each: `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, and `skills/implement/SKILL.md`.
- Repo-level grep audit for `multi-actor-flow-check.md` under `skills/` returns exactly the four consumer SKILL.md files plus the source snippet file.
- Snippet self-containment lint `grep -E "Sub-Rule C|G1|G\\d+" skills/_shared/multi-actor-flow-check.md` returns zero matches.
- Consumer duplication audit searches the four consumer files for the snippet-only anchor phrases and confirms they appear only via the `!cat` include, not as embedded prose copies.
- Prompt-prose rules-application pass verifies the R1-R7 findings named in Definition of done.

**References**

- goals.md ### G1 — problem framing for downstream agents guessing under-described design decisions.
- goals.md ### G30 — related Goals/Design dialogue and persistence context; implementation deferred to sibling T32.
- goals.md ### G33 — related Design dialog-clarity context; implementation deferred to sibling T31.
- design.md ## G1 → Altitude Sub-Rule C — six required choreography elements and the no-invented-hand-offs acceptance bar.
- design.md ## G30 — incremental-persistence context for Goals/Design; not implemented by this task.
- design.md ## G33 — Design-only simple-language rule folded into G1; not implemented by this task.
- design.md ### CD-3 — locked snippet body, four consumer include sites, layered-defense semantics, and acceptance criteria.
- structure.md ### `skills/_shared/multi-actor-flow-check.md` — source file body and source-file hook-point responsibility.
- structure.md ## Hook-Point Cross-Slice Index → CD-3 multi-actor-flow-check `!cat` include sites — four consumer SKILL.md include targets.

### Task 29: G34 Design scope-reviewer alignment with detailed-solution boundary (design-altitude-boundary primitive + scope-reviewer + owns-defers)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G34]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** create `skills/_shared/design-altitude-boundary.md`; modify `agents/qrspi-design-scope-reviewer.md`; modify `skills/design/owns-defers.md`; create `tests/lint/test-design-altitude-boundary-include.bats`
- **Dependencies:** none. **Blocks:** T30 (Design SKILL decision-completeness template consumes the superseded-G1-deliverable boundary), T37 (Structure-side boundary migration follows the Design boundary split).
- **LOC estimate:** ~150

**Overview**

Create a single shared Design altitude boundary and wire both Design enforcement surfaces to it so the Design scope-reviewer stops flagging content that Design is supposed to own. The task closes the G34 false-positive loop by making `skills/design/owns-defers.md` and `agents/qrspi-design-scope-reviewer.md` consume the same `!cat` source. (Why: see goals.md ### G34. Approach: see design.md ## G34.)

**Scope**

- **In:**
  - Create `skills/_shared/design-altitude-boundary.md` as the single source of truth for the Design OWNS block followed by the Design DEFERS block, lifted from design.md ## G34 D2/D3 and kept as one contiguous boundary contract.
  - Replace the inline contract body in `skills/design/owns-defers.md` with the literal directive `!cat skills/_shared/design-altitude-boundary.md`, preserving the file's existing surrounding structure.
  - In `agents/qrspi-design-scope-reviewer.md`, insert the exact introducer prose `The contract you just read carries the following allowances and deferrals; restated here so they are present in your immediate reasoning context:` immediately after the Step 1 Read citation, followed by the literal directive `!cat skills/_shared/design-altitude-boundary.md`.
  - Preserve the boundary's positive OWNS allowances and matching DEFERS list so detailed solution descriptions, edge cases, flows, prompt-writing specifics, acceptance examples, per-solution diagrams, naming/rename inventory, and phasing labels are allowed while implementation bodies, full test code, executable shell, file architecture, unified architecture/test strategy, and task carving remain deferred.
  - Create `tests/lint/test-design-altitude-boundary-include.bats` asserting that `agents/qrspi-design-scope-reviewer.md` contains the literal `!cat skills/_shared/design-altitude-boundary.md` directive on the line immediately after the Step 1 Read citation introducer prose, and that `skills/design/owns-defers.md` contains the same literal directive in place of the previous inline contract body. Removal of either include directive must fail the lint with a diagnostic naming the violating file and the missing directive.

- **Out:**
  - Rewriting the Design SKILL's per-goal template and other G1 deliverables — T30 owns; G1 deliverable #6 is superseded by this task's positive OWNS plus DEFERS boundary and must not be implemented a second time.
  - Moving unified system/test architecture responsibility into Structure — T37 owns.
  - Auditing or changing non-Design artifact scope reviewers and their owns-defers files — explicitly deferred outside G34.
  - Changing dispatch parameters, reviewer model selection, tool grants, reviewer-protocol `change_type` semantics, or scope-finding pause behavior.
  - Moving file architecture, unified system architecture, unified test architecture, or task decomposition back into Design ownership.
  - Adding or modifying files outside the four target files, unless a directly coupled include-resolution break prevents those files from being valid.

**Definition of done**

- `skills/_shared/design-altitude-boundary.md` exists and its boundary body is one contiguous Design OWNS block followed by one contiguous Design DEFERS block.
- The shared boundary contains the explicit OWNS allowances and DEFERS exclusions named in design.md ## G34 D2/D3, with no implementation instructions, task carving, or file-architecture material outside those blocks.
- `skills/design/owns-defers.md` keeps its existing surrounding structure and contains the literal line `!cat skills/_shared/design-altitude-boundary.md` in place of the previous inline contract body.
- `agents/qrspi-design-scope-reviewer.md` contains the exact introducer prose immediately after the Step 1 Read citation, followed by the literal line `!cat skills/_shared/design-altitude-boundary.md`.
- Neither consumer inlines the full boundary contract; both rely on the `!cat` directive so build expansion remains the single-source mechanism.
- No second Design owns-defers rewrite is introduced for G1 deliverable #6, and no non-Design scope-reviewer surfaces are broadened into this task.
- Prompt prose remains concrete and audit-friendly: no TODO/TBD placeholders, no stale `docs/prompt-design-guide.md` reference, no bare prohibition without a positive substitute and decision rule.
- `tests/lint/test-design-altitude-boundary-include.bats` exists and asserts the literal `!cat skills/_shared/design-altitude-boundary.md` directive is present in both consumer files at the canonical insertion points; removal of either directive fails the lint with a file-and-directive-naming diagnostic.

**Test expectations**

- File-existence check confirms `skills/_shared/design-altitude-boundary.md` exists and the two consumer files still exist at their canonical paths.
- Grep audit confirms the literal `!cat skills/_shared/design-altitude-boundary.md` line is present in both `skills/design/owns-defers.md` and `agents/qrspi-design-scope-reviewer.md`.
- Ordering inspection confirms the Design scope-reviewer introducer prose appears immediately after the Step 1 Read citation and immediately before the `!cat` directive.
- Boundary-body inspection confirms `Design OWNS:` precedes `Design DEFERS:` and includes the named OWNS allowances and DEFERS exclusions from design.md ## G34 D2/D3.
- Consumer-source inspection confirms the full OWNS/DEFERS boundary is not duplicated inline in either consumer beyond the required `!cat` directive.
- Run `tests/lint/test-design-altitude-boundary-include.bats` and confirm it passes against the implemented consumer files; a negative-test fixture (removing the include directive from one consumer) must cause the lint to fail with a diagnostic naming the violating file and the missing directive.
- Diff audit confirms only the four target files changed, unless the implementer documents a directly coupled include-resolution break.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) to the new prompt prose; reviewer verifies single-source prompt prose, positive OWNS allowances paired with DEFERS, exact anchor phrase preservation, evergreen/non-host-specific wording, no placeholder bodies, and compaction-resilient load-bearing instructions at the point of use.

**References**

- goals.md ### G34 — problem framing for the Design scope-reviewer vs Design SKILL boundary contradiction.
- design.md ## G34 — detailed solution D1-D6, locked OWNS/DEFERS lists, consumer insertion points, and acceptance criteria.
- structure.md ### `skills/_shared/design-altitude-boundary.md` — per-file contract for the shared boundary primitive.
- structure.md ### `agents/qrspi-design-scope-reviewer.md` — per-file contract for the reviewer insertion point and immediate reasoning context.
- structure.md ### `skills/design/owns-defers.md` — per-file contract for replacing the inline body with the shared include.
- structure.md ## Hook-Point Cross-Slice Index → G34 design-altitude-boundary `!cat` include sites — cross-slice list of the two required consumers.

### Task 30: G1 Design phase decision-completeness template

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G1]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** modify `skills/design/SKILL.md`
- **Dependencies:** Task 29. **Blocks:** T31 (Design dialog-clarity follow-on), T32 (Goals/Design incremental persistence).
- **LOC estimate:** ~160

**Overview**

Replace the Design skill's under-specified artifact template with a decision-complete per-goal template so downstream Structure and Plan receive outcome, solution, rationale, dependency, edge-case, and acceptance detail instead of filling gaps themselves. The edit installs the G1 Design prompt-prose content in `skills/design/SKILL.md` and removes Design-owned top-level strategy/flow sections whose responsibilities move downstream. (Why: see goals.md ### G1. Approach: see design.md ## G1.)

**Scope**

- **In:**
  - Replace the Design skill's artifact-output prose with G1's `What Design produces` contract: outcome altitude, inline per-goal acceptance, optional per-solution diagrams, and explicit deferral of unified architecture, file maps, unified test architecture, and per-test specification to downstream artifacts.
  - Install the per-goal block template with the required `Outcome`, `Solution`, `Why this approach`, `Dependencies + edge cases`, and `Acceptance` fields, plus the optional per-goal Mermaid diagram rule and top-level `Cross-Goal Decisions` section.
  - Install the Design Dialogue Conduct section and Altitude Sub-Rules A-D content at prompt-prose altitude, preserving the required anchor phrases and the named failure-mode examples from design.md ## G1.
  - Remove the existing Design SKILL.md top-level `## Test Strategy` and `## System Flow` sections so those concepts no longer live in Design's template.
  - Apply R1-R7 and the cross-cutting prompt-prose principles from `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)` to the edited prompt prose.

- **Out:**
  - Multi-actor flow shared snippet creation and downstream include sites in Structure, Plan, Parallelize, and Implement — T28 owns.
  - Design scope-reviewer and `skills/design/owns-defers.md` boundary alignment — T29 owns.
  - Additional Design dialog-clarity tests and narrow G33 follow-on refinements — T31 owns.
  - Goals mirroring and compaction-resilient incremental persistence across Goals and Design — T32 owns.
  - Structure-side absorption of unified architecture and unified test architecture after Design removes those sections — T37 owns Structure authoring; T38 owns Structure reviewer enforcement.
  - Reviewer-agent enforcement changes for the G1 template are out of scope; this task changes Design skill prompt prose only.

**Definition of done**

- `skills/design/SKILL.md` contains a `What Design produces` section matching design.md ## G1's outcome-altitude contract and downstream deferrals.
- `skills/design/SKILL.md` contains the five-field per-goal block template and a `Cross-Goal Decisions` section above per-goal blocks.
- Design Dialogue Conduct is present in the Design skill, including the eight-rule structure from design.md ## G1.
- Altitude Sub-Rules A-D are present with their load-bearing anchors: `Altitude Sub-Rule A — Naming-vs-Layout`, `Altitude Sub-Rule B — Prose-as-Decision`, `Altitude Sub-Rule C — End-to-End Flow`, and `Sub-Rule D — External-Knowledge Completeness`.
- The old Design top-level `## Test Strategy` and `## System Flow` sections are absent from `skills/design/SKILL.md`.
- The edited prompt prose preserves the stable audit phrases `Outcome`, `Solution`, `Why this approach`, `Dependencies + edge cases`, `Acceptance`, `Cross-Goal Decisions`, `Altitude Sub-Rule C — End-to-End Flow`, and `Sub-Rule D — External-Knowledge Completeness`.
- The Design skill prompt contains no TODO/TBD placeholders, stale line-number references, decorative Mermaid instructions, or non-actionable template commentary introduced by this edit.
- The edit does not modify reviewer agents, Goals skill prose, Structure ownership, tests, dispatch parameters, or unrelated Design skill behavior.

**Test expectations**

- Grep audit of `skills/design/SKILL.md` confirms all required anchor phrases from the Definition of done are present exactly where the new Design template/altitude-rule prose lives.
- Grep audit confirms `## Test Strategy` and `## System Flow` no longer appear as top-level sections in `skills/design/SKILL.md`.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)` to the Design prompt-prose edit.
- R1 verification confirms the edit removes non-actionable template commentary while preserving load-bearing decision-completeness rules.
- R2 verification confirms hot-path authoring instructions are imperative, with rationale only for non-obvious downstream-drift risks.
- R3 verification confirms override-critical altitude, no-placeholder, and last-research-bearing-phase rules appear where recency or hard-gate placement makes them visible.
- R4 verification confirms worked examples are limited to the observed failure modes for naming-vs-layout, prose-as-decision, multi-actor flow, and external-knowledge deferral.
- R5 verification confirms required template content is not sharded into optional references.
- R6 verification confirms the skill prompt avoids decorative Mermaid while still allowing generated design artifacts to include per-goal diagrams when useful.
- R7 verification confirms the stable audit phrases listed in the Definition of done are preserved verbatim.
- Cross-cutting prompt-prose review confirms the minimal complete behavior set is present; prohibitions have positive substitutes and named failure modes where needed; and the prose is evergreen, with no dialogue exhaust, TODOs, placeholders, or stale line-number references.

**References**

- goals.md ### G1 — problem framing for decision-under-specified Design artifacts and downstream context loss.
- design.md ## G1 — Design skill outcome/template/dialogue/sub-rule content and implementation deliverables.
- structure.md ### `skills/design/SKILL.md` → Slice 1.5 — target-file block naming the G1 Design SKILL.md outline sections and removals.

### Task 31: G33 Design skill interactive dialog clarity

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G33]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** skills/design/SKILL.md (modify), tests/unit/test-interactive-skill-prompts.bats (modify)
- **Dependencies:** Task 30. **Blocks:** T32 (Goals/Design dialogue authoring quality and compaction-resilient incremental persistence).
- **LOC estimate:** ~90

**Overview**

Make the Design skill's interactive discussion prose require simple language and grounding context when presenting candidate approaches, especially trade-off lists and newly introduced technical terms. This is a narrow Design-only follow-on to Task 30's Dialogue Conduct scaffold: it preserves G33's literal clarity rule and keeps broader interactive-skill scoping out of v0.7.2. (Why: see goals.md ### G33. Approach: see design.md ## G33 and design.md ## G1 → Dialogue Conduct Rule 5.)

**Scope**

- **In:**
  - Preserve the literal Rule 5 anchor phrase *"Use simple language and provide context when presenting ideas"* in `skills/design/SKILL.md`.
  - Make Rule 5 operational in the Design dialogue hot path: ground concrete scenarios before abstract names, provide one sentence of context for newly introduced project/domain terms not present in recent turns, and explain A/B/C trade-offs in plain prose before naming architectural shapes.
  - Keep the rule Design-only by ensuring the literal phrase does not appear in `skills/goals/SKILL.md` or other interactive skill prose.
  - Update `tests/unit/test-interactive-skill-prompts.bats` only to pin the Design presence / Goals absence contract for the Rule 5 phrase.

- **Out:**
  - Creating the CD-3 multi-actor-flow-check shared snippet and include sites for Structure / Plan / Parallelize / Implement — T28 owns.
  - Authoring the broader Design Dialogue Conduct scaffold and other G1 Design-skill sections — T30 owns; T31 only sharpens G33 / Rule 5 behavior.
  - Adding Goals dialogue-conduct subset coverage, direct incremental writes, compaction-resume diagnostics, or finalize-pass behavior — T32 owns.
  - Broadening the simple-language/context rule to Goals, Replan, Phasing, or Structure in v0.7.2 — explicitly out of scope per G33.

**Definition of done**

- `skills/design/SKILL.md` contains the literal phrase *"Use simple language and provide context when presenting ideas"* in the Design Dialogue Conduct Rule 5 surface.
- Rule 5 includes concrete hot-path imperatives for scenario grounding before abstract names, one-sentence context for newly introduced technical terms not present in recent turns, and plain-prose trade-off explanations before architectural labels.
- The prose applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention): no self-host-history bloat, no maintainer commentary, no redundant restatement of Dialogue Conduct, rationale only for the opaque-framing failure mode, examples only if contrastive and observed-failure-based, and lexical anchors around `presenting ideas`, `technical term`, `recent turns`, and `trade-off framings` remain intact.
- `skills/goals/SKILL.md` and other interactive skill prose do not contain the literal Rule 5 phrase.
- `tests/unit/test-interactive-skill-prompts.bats` pins the Design presence / Goals absence contract without adding unrelated dialog-conduct assertions.

**Test expectations**

- Grep audit confirms `skills/design/SKILL.md` contains the literal phrase *"Use simple language and provide context when presenting ideas"*.
- Grep audit confirms `skills/goals/SKILL.md` does not contain that literal phrase; if other interactive skill prose is touched, audit it for the same absence contract.
- Test inspection confirms `tests/unit/test-interactive-skill-prompts.bats` only adds/updates assertions for Design presence and Goals absence of the Rule 5 phrase.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) to the changed prose and verifies the specific DoD anchors and anti-bloat constraints.

**References**

- goals.md ### G33 — problem framing and user directive for simple-language/context Design dialogue.
- design.md ## G33 — G33 traceability, Design-only scope, and acceptance folded into G1 Rule 5.
- design.md ## G1 → Dialogue Conduct Rule 5 — verbatim operational rule text and Goals mirror exclusion.
- structure.md ### `skills/design/SKILL.md` — Slice 1.5 Design SKILL responsibilities for G1/G30/G31/G33, including Rule 5.
- structure.md ### `tests/unit/test-interactive-skill-prompts.bats` — tests pin Design Rule 5 presence and Goals absence.

### Task 32: G30 Goals and Design dialogue authoring quality and compaction-resilient incremental persistence

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G30]
- **Task type:** code
- **Model:** opus
- **Target files:** modify `skills/goals/SKILL.md`, modify `skills/design/SKILL.md`, modify `tests/unit/test-interactive-skill-prompts.bats`
- **Dependencies:** Task 30, Task 31
- **LOC estimate:** ~180

**Overview**

Make Goals and Design persist each locked decision directly into their final draft artifact, survive compaction by resuming from that artifact, and finalize only after completeness validation; add the approved Goals dialogue-conduct subset so both interactive phases ask grounded, one-at-a-time questions. (Why: see goals.md ### G30. Approach: see design.md ## G30, design.md ## G1, and design.md ## G33.)

**Scope**

- **In:**
  - Update `skills/design/SKILL.md` so each per-decision lock writes directly to `design.md` with `status: draft`, using the Task 30 five-field per-goal template and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.
  - Update `skills/goals/SKILL.md` so each locked goal writes directly to `goals.md` with `status: draft`, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.
  - Add the Goals dialogue-conduct subset: Rules 1, 2, 4, 6, 7, and 8 match the Design wording; Rule 3 uses Goals-safe grounding order of codebase then web; Rule 5's simple-language directive remains absent from Goals.
  - Document presence-as-locked semantics in both skills: tentative, placeholder, `to be filled`, TODO, or similar incomplete decision bodies never enter draft artifacts; re-locking an existing decision overwrites that keyed block in place instead of appending a duplicate.
  - Document resume-after-compaction behavior in both skills: re-read the draft artifact, enumerate locked decisions, surface the exact diagnostic `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`, then continue from the next unlocked decision.
  - Document the skill-specific remaining-work rule: Goals asks the user whether all desired goals have been articulated; Design computes remaining work from `goals.md` goals minus locked per-goal blocks in `design.md`.
  - Document end-of-phase finalize behavior: Goals validates locked goal completeness, optionally appends Purpose if absent, and flips `status: draft` to `approved`; Design validates every `goals.md` goal has all five fields populated, validates Cross-Goal Decisions well-formedness, and flips `status: draft` to `approved-pending-review`.
  - Update `tests/unit/test-interactive-skill-prompts.bats` to pin the dialogue-conduct, incremental-write, lock-semantics, resume, finalize, and simulated-compaction contracts above.

- **Out:**
  - Creating the CD-3 Multi-Actor Flow Check shared snippet and downstream include sites — T28 owns.
  - Authoring the Design five-field per-goal template, Dialogue Conduct base section, and altitude sub-rules — T30 owns; this task consumes those established contracts.
  - Authoring or broadening the Design-only simple-language Rule 5 — T31 owns; this task only preserves the Goals absence contract while using the approved Design wording as the comparison source.
  - Updating reviewer-agent files to enforce draft-artifact status or placeholder checks — not in this task's target files.

**Definition of done**

- `skills/design/SKILL.md` instructs direct incremental writes to `design.md` with `status: draft` after each per-decision lock signal, including the Task 30 five-field template and `## Cross-Goal Decisions` handling.
- `skills/goals/SKILL.md` instructs direct incremental writes to `goals.md` with `status: draft` as goals lock, while preserving the existing Goals template, question-topic checklist, and Pipeline Mode Selection step.
- Goals dialogue conduct mirrors Design Rules 1, 2, 4, 6, 7, and 8; Rule 3 uses codebase → web grounding; the Rule 5 simple-language directive is absent from Goals.
- Both skills define presence-as-locked semantics, prohibit placeholder or tentative draft blocks, and require keyed overwrite on re-lock instead of duplicate append.
- Both skills define resume-after-compaction using the exact diagnostic string and the correct remaining-work computation for that skill.
- Both skills define finalize validation and status transition behavior exactly as scoped: Goals to `approved`; Design to `approved-pending-review`.
- `tests/unit/test-interactive-skill-prompts.bats` covers the Goals conduct subset, Design and Goals incremental-write behavior, placeholder prohibition, resume diagnostic, remaining-work split, finalize pass, and simulated-compaction durability contract.

**Test expectations**

- `tests/unit/test-interactive-skill-prompts.bats` fails before implementation and passes after it pins the Goals dialogue-conduct subset: Rules 1, 2, 4, 6, 7, and 8 match Design wording; Rule 3 uses codebase → web grounding; Rule 5's simple-language directive remains absent from Goals.
- Tests pin `skills/design/SKILL.md` behavior for direct incremental writes to `design.md` with `status: draft` after each per-decision lock signal, using the five-field per-goal template from Task 30 and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.
- Tests pin `skills/goals/SKILL.md` behavior for direct incremental writes to `goals.md` with `status: draft` as goals lock, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.
- Grep or assertion coverage verifies both skills document presence-as-locked semantics, reject tentative / placeholder / `to be filled` / TODO-like decision bodies in draft artifacts, and require keyed in-place overwrite when a decision is re-locked.
- Tests pin the exact resume diagnostic string: `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`.
- Tests distinguish remaining-work computation: Goals asks the user whether all desired goals have been articulated; Design computes remaining work from `goals.md` goals minus locked per-goal blocks in `design.md`.
- Tests pin the finalize pass: Goals validates locked goal completeness, optionally appends Purpose if absent, and flips `status: draft` to `approved`; Design validates all five fields for every goal, validates Cross-Goal Decisions well-formedness, and flips `status: draft` to `approved-pending-review`.
- Simulated-compaction coverage uses a mid-phase decision such as G15 and verifies resume produces the same final artifact content as a no-compaction run.

**References**

- goals.md ### G30 — problem framing for Goals/Design dialogue quality gaps and compaction-loss risk.
- design.md ## G30 — direct-to-artifact draft persistence, lock semantics, resume diagnostic, finalize behavior, and acceptance criteria.
- design.md ## G1 — Design five-field template and base Dialogue Conduct rules consumed by this task.
- design.md ## G33 — Design-only simple-language Rule 5 that must remain absent from Goals.
- structure.md ### `skills/design/SKILL.md` — Slice 1.5 G30 per-file block for Design incremental persistence and tests.
- structure.md ### `skills/goals/SKILL.md` — Slice 1.5 G30 per-file block for Goals dialogue-conduct subset and incremental persistence.
- structure.md ### `tests/unit/test-interactive-skill-prompts.bats` — test block pinning dialogue conduct, resume diagnostics, and simulated-compaction durability.

### Task 33: G2 Plan schema-migration task shape

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G2]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** modify `skills/plan/SKILL.md`; modify `agents/qrspi-plan-reviewer.md`
- **Dependencies:** none
- **LOC estimate:** ~80

**Overview**

Add the Plan schema-migration task shape so Plan can author one narrow, self-verifying task for many same-shaped file edits without weakening ordinary task-size discipline. The contract must make the exception explicit and reviewer-checkable through the required exception, rationale, and structural-lint fields. (Why: see goals.md ### G2. Approach: see design.md ## G2.)

**Scope**

- **In:**
  - Add a schema-migration task-shape contract to `skills/plan/SKILL.md` that permits oversized same-shape migrations only when the spec declares `sizing_exception: schema-migration`.
  - Require schema-migration specs to carry `sizing_rationale:` plus mandatory `structural_lint:` naming a bash check that proves the diff is mechanical-only.
  - State that the exception is ungated by file count only after the structural lint succeeds; the lint, exception field, and rationale field are mandatory together.
  - Update `agents/qrspi-plan-reviewer.md` so the plan reviewer exempts LOC/file-count ceilings only when all three fields are present and the `structural_lint` command executes successfully on the proposed diff.
  - Ensure missing `structural_lint` or an otherwise incomplete schema-migration declaration fails plan-spec review with a clear diagnostic.

- **Out:**
  - G15/G18 sweep-task `dependent_tests:` and cross-task consumer-surface contracts in the same Plan/reviewer files — T14 and T15 own those surfaces.
  - G31 prompt-prose classification, writer-addition, and reviewer preload/include work in the same Plan/reviewer structure rows — out of this G2-only task.
  - Changing ordinary task-size limits or adding new sizing-exception categories beyond the existing closed set (`schema-migration`, `CI scaffolding`, `reusable primitives`).

**Definition of done**

- `skills/plan/SKILL.md` documents a `sizing_exception: schema-migration` task shape that allows LOC/file-count exceptions only for mechanical same-shape migrations.
- The Plan contract requires `sizing_exception: schema-migration`, `sizing_rationale:`, and `structural_lint:` as a mandatory trio; no field is optional when the exception is used.
- The Plan contract defines `structural_lint:` as a bash check that proves the proposed diff is mechanical-only, with N-files otherwise ungated.
- `agents/qrspi-plan-reviewer.md` verifies the mandatory trio and re-runs or otherwise requires successful execution of the named structural lint before exempting LOC/file-count ceilings.
- Plan-spec review fails clearly when a schema-migration task omits `structural_lint` or declares the exception incompletely.
- The prose keeps the exception narrow and does not relax ordinary task-size discipline for non-schema-migration work.

**Test expectations**

- Grep audit of `skills/plan/SKILL.md` confirms the schema-migration contract includes the exact field names `sizing_exception: schema-migration`, `sizing_rationale:`, and `structural_lint:`.
- Grep audit of `agents/qrspi-plan-reviewer.md` confirms the review rubric checks the same three fields and ties LOC/file-count exemption to successful structural-lint execution.
- Content review confirms the Plan prose says the structural lint is mandatory, N-files are ungated only under the exception, and all three fields are mandatory together.
- Content review confirms the reviewer prose emits a clear defect for an attempted schema-migration task missing `structural_lint`.
- Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application, especially load-bearing-rule clarity for distinguishing schema migrations from ordinary oversized tasks and positive-substitute wording for what schema migrations do.
- Anchor-phrase audit confirms the closed exception set remains clear (`schema-migration`, `CI scaffolding`, `reusable primitives`) and reviewers exempt LOC/file-count ceilings only when all schema-migration fields are present and the lint succeeds.

**References**

- goals.md ### G2 — problem framing for recurring same-shape schema migrations and why Plan/reviewer support is needed.
- design.md ## G2 — required schema-migration fields, mandatory structural lint, ungated file count, and review acceptance conditions.
- structure.md ### `skills/plan/SKILL.md` → Slice 1.5 — Plan SKILL insertion surface for the schema-migration task-shape contract.
- structure.md ### `agents/qrspi-plan-reviewer.md` → Slice 1.5 — plan-reviewer rubric addition for field completeness and structural-lint success before exemption.

### Task 34: G5 Plan post-approval split idempotency

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G5]
- **Task type:** code
- **Model:** sonnet
- **Target files:** modify `skills/plan/post-approval-split-contract.md`; modify `tests/unit/test-plan-post-approval-split.bats`
- **Dependencies:** none
- **LOC estimate:** ~110
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Make Plan's post-approval task split safe to re-run after compaction, restart, or a partial crash by documenting the block-hash audit contract and pinning it with unit tests. The task preserves existing per-task files when their source block is unchanged, halts loudly when `plan.md` changed, and prevents stale per-task specs from silently feeding Implementation. (Why: see goals.md ### G5. Approach: see design.md ## G5.)

**Scope**

- **In:**
  - Document the single `# block-hash: <sha256-hex>` header line in `skills/plan/post-approval-split-contract.md`, including its exact position, sha256 hex/no-salt syntax, and normalized source-block hash calculation.
  - Document the idempotent three-case decision rule: absent task file dispatches, present matching hash safe-skips without rewrite, and present mismatching hash halts before approval.
  - Document the exact mismatch and missing-header halt diagnostics, the malformed-header diagnostic requirement, the new `block_hash: <sha256-hex>` sub-subagent dispatch field, and the quick-fix N=1 path.
  - Update `tests/unit/test-plan-post-approval-split.bats` to pin block-hash emission, partial-crash recovery, complete re-run no-op behavior, hand-edit preservation, mismatch/missing/malformed-header failures, and quick-fix parity.

- **Out:**
  - No sibling task shares G5; this task owns the G5 surface in the two target files only.
  - Regenerating existing `tasks/task-NN.md` files automatically on mismatch — design.md ## G5 requires delete-and-rerun or revert-plan-edit as the user-controlled resolution.
  - Adding `.split-conflict-NN.md` sidecar machinery — design.md ## G5 explicitly rejects it in favor of the halt diagnostic plus preserved existing files.
  - Changing unrelated Plan task-shape behavior or editing `plan.md` directly — this task only enhances the post-approval split contract and its tests.

**Definition of done**

- `skills/plan/post-approval-split-contract.md` contains `## Block-Hash Header Format`, `## Idempotent Split Contract`, `## HALT Diagnostic`, `## Pre-G5 Migration Diagnostic`, `## Sub-Subagent Dispatch Contract`, and `## Quick-Fix N=1 Path` sections.
- The block-hash contract states exactly one header line immediately after the closing frontmatter `---` and before body content, with syntax `# block-hash: <sha256-hex>`.
- Hash calculation is documented as sha256 hex, no salt, over the normalized source `### Task N` block; normalization strips trailing whitespace from each line and preserves all other characters and line breaks.
- The idempotent split contract documents absent → dispatch, present + matching hash → safe-skip without rewrite, and present + mismatching hash → halt before approval with the existing file untouched.
- The mismatch diagnostic text is exact: `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`
- The missing-header diagnostic text is exact: `task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run.`
- Malformed block-hash handling halts with a diagnostic that names `malformed block-hash header` and does not rewrite the existing file.
- The sub-subagent dispatch contract includes `block_hash: <sha256-hex>` and instructs the writer to emit that value immediately after frontmatter close.
- The quick-fix N=1 path emits the same header and applies the same absent, matching, mismatching, missing-header, and malformed-header audit rules on re-run.
- Unit tests cover all behavior above, including partial-split crash recovery, complete-set re-run with zero sub-subagent dispatches, and hand-edit preservation when the stored source block hash still matches.

**Test expectations**

- `tests/unit/test-plan-post-approval-split.bats` verifies every generated `tasks/task-NN.md` contains a single `# block-hash: <sha256-hex>` line immediately after the closing frontmatter `---` and before the first body content.
- The hash calculation is verified as sha256 hex with no salt over the normalized source `### Task N` block, where normalization strips trailing whitespace from each line and preserves all other characters and line breaks.
- A partial split crash scenario with only some task files present dispatches only the missing task files on re-run; existing matching files are not rewritten and exact-set verification still passes once all expected files exist.
- A completed split re-run with all task files present and matching hashes dispatches zero sub-subagents and proceeds to plan reduction plus approval-state completion.
- A hand-edited existing `tasks/task-NN.md` whose stored block hash still matches the current `plan.md` task block is safe-skipped without overwriting the hand edit.
- A changed `plan.md` `### Task N` block with an existing task file whose stored hash no longer matches halts before approval, leaves the existing task file untouched, and emits exactly: `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`
- An existing task file with no `# block-hash:` line halts with exactly: `task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run.`
- An existing task file with a malformed block-hash line halts with a diagnostic that names `malformed block-hash header` and does not rewrite the file.
- The quick-fix single-task path emits the same `# block-hash:` line and applies the same absent, match, mismatch, missing-header, and malformed-header audit rules on re-run.
- Grep-based documentation audit confirms `skills/plan/post-approval-split-contract.md` documents `## Block-Hash Header Format`, `## Idempotent Split Contract`, `## HALT Diagnostic`, `## Pre-G5 Migration Diagnostic`, `## Sub-Subagent Dispatch Contract`, and `## Quick-Fix N=1 Path` with the required position, syntax, normalization, decision cases, and diagnostics.

**References**

- goals.md ### G5 — problem framing for compaction/restart-safe Plan splitting and data-loss avoidance.
- design.md ## G5 — idempotent decision rule, block-hash audit, halt diagnostics, edge cases, and acceptance criteria.
- structure.md ### `skills/plan/post-approval-split-contract.md` — required contract sections, exact diagnostics, dispatch field, and quick-fix clause.
- structure.md ### `tests/unit/test-plan-post-approval-split.bats` — required unit coverage for block-hash emission, safe re-run, loud conflicts, migration diagnostic, partial recovery, hand-edit preservation, and quick-fix parity.

### Task 35: G10 reviewer-protocol anti-fabrication hardening

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G10]
- **Task type:** code
- **Model:** opus
- **Target files:** skills/reviewer-protocol/SKILL.md (modify), tests/acceptance/test-review-pause.bats (modify)
- **Dependencies:** Task 03
- **LOC estimate:** ~100
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Add the reviewer-protocol anti-fabrication rule and acceptance coverage that prevent reviewers from inventing procedural authority when a loaded contract is hard to satisfy. The rule bounds the existing contradiction-refusal procedure to its documented dispatch malformation and gives genuine contract conflicts one explicit fail-loud exit. (Why: see goals.md ### G10. Approach: see design.md ## G10.)

**Scope**

- **In:**
  - Insert a new `### Anti-Fabrication Rule (FAIL-LOUD)` section in `skills/reviewer-protocol/SKILL.md` immediately after the existing refusal procedure and before `## Per-Finding Disk-Write Contract`, using the verbatim G10 callout content from design.md ## G10 D1.
  - State in that section that the contradiction-refusal procedure applies only to the documented malformed dispatch with `task_definition` present and a test-phase `output` path, and does not generalize to other contract conflicts.
  - Forbid inventing, paraphrasing, or attributing any reviewer-protocol escape hatch that is not literally present in the file; fabricated citations to absent procedures are contract violations, not approved exits.
  - Require genuine contract conflicts to avoid the Write tool, avoid findings and clean sentinels, return exactly one single-line response beginning with `CONTRACT-CONFLICT:`, and end the turn.
  - Update `tests/acceptance/test-review-pause.bats` to cover the `CONTRACT-CONFLICT:` prefix path, operator-intervention routing, fabricated-procedure rejection, and the valid-exit boundary.

- **Out:**
  - No sibling task shares G10; this task owns the G10 surface in the two target files only.
  - Rewriting or deleting the existing `### Contradiction Refusal (FAIL-LOUD)` or `### Refusal Procedure` sections — this task bounds them by adjacent callout rather than changing them.
  - Retroactively editing reviewer agent bodies — design.md ## G10 states the callout is consumed through the existing reviewer-protocol preload.
  - v0.7.3 follow-up investigation into training-data origin, context-size correlation, or round-number correlation — design.md ## G10 tracks that separately in issue dfrysinger/qrspi-plus#264.
  - Broad G6 transport fallback hardening — T03 owns the disk-write contract and transport-level chat-only fallback surface.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains `### Anti-Fabrication Rule (FAIL-LOUD)` immediately after `### Refusal Procedure` and before `## Per-Finding Disk-Write Contract`.
- The new section body matches the verbatim design.md ## G10 D1 callout, including the bounding clause, the prohibition on invented or paraphrased escape hatches, the three-step `CONTRACT-CONFLICT:` exit procedure, and the closing fabrication-as-rule clause.
- The new section preserves the existing contradiction-refusal and refusal-procedure sections unchanged.
- A reviewer that sees a real contract conflict is instructed not to call `Write`, not to emit findings or clean sentinels, to return exactly one line beginning with `CONTRACT-CONFLICT:`, and to end the turn.
- `tests/acceptance/test-review-pause.bats` verifies a reviewer chat output whose first non-blank line begins with `CONTRACT-CONFLICT:` routes to operator intervention rather than normal review-round handling.
- The conflict-prefix path does not parse findings, synthesize a clean sentinel, fire the schema-violation guard, auto-repair, consume a tag emission budget, or advance the round counter.
- The pause-flow coverage surfaces the single-line conflict statement verbatim to the operator with an intervention menu.
- Regression coverage rejects fabricated citations to reviewer-protocol procedures not literally present in the file and verifies the only valid conflict exits are normal finding emission under the loaded contract or the `CONTRACT-CONFLICT:` single-line response.

**Test expectations**

- Grep audit confirms `skills/reviewer-protocol/SKILL.md` contains `### Anti-Fabrication Rule (FAIL-LOUD)` between `### Refusal Procedure` and `## Per-Finding Disk-Write Contract`.
- Text comparison or anchored grep audit confirms the new section carries the exact D1 callout requirements from design.md ## G10: one-specific-dispatch-malformation bounding clause, no invented/paraphrased escape hatches, no `Write`, no findings/sentinels, literal `CONTRACT-CONFLICT:` prefix, single-line return, and end-turn requirement.
- Acceptance fixture covers a reviewer chat output whose first non-blank line begins with `CONTRACT-CONFLICT:` and asserts it routes to operator intervention rather than the normal review-round path.
- Conflict-prefix fixture asserts no findings are parsed, no clean sentinel is synthesized, no schema-violation guard fires, no auto-repair occurs, no tag emission budget is consumed, and the round counter does not advance.
- Pause-flow fixture asserts the single-line conflict statement is surfaced verbatim to the operator with an intervention menu.
- Regression fixture asserts a fabricated citation to a reviewer-protocol procedure not literally present does not satisfy the contract and is not treated as an approved escape hatch.
- Regression fixture asserts the only valid exits for a contract conflict are normal finding emission under the loaded contract or the `CONTRACT-CONFLICT:` single-line response.

**References**

- goals.md ### G10 — problem framing for reviewer procedural-authority fabrication and why it weakens SKILL-as-contract enforcement.
- design.md ## G10 — D1 anti-fabrication callout content, placement, `CONTRACT-CONFLICT:` handling, acceptance criteria, and explicit non-goals.
- structure.md ### `skills/reviewer-protocol/SKILL.md` → G10 block — insertion site, verbatim section body, preserve-existing-sections constraint, and reviewer-agent non-retrofit boundary.
- structure.md ### `tests/acceptance/test-review-pause.bats` — acceptance coverage for conflict-prefix routing, no normal review-round side effects, fabricated-citation rejection, and valid conflict exits.

### Task 36: G17 implementer-protocol and test-writer stale-prose cleanup

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G17]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** modify `skills/implementer-protocol/SKILL.md`; modify `agents/qrspi-test-writer.md`
- **Dependencies:** none
- **LOC estimate:** ~70

**Overview**

Reconcile three stale commit-hygiene prose surfaces after v0.7.1 Wave 1 T2 added `.qrspi-commit-msg.txt` to qrspi-plus's committed root `.gitignore`, preserving runtime behavior and invariant structure. This is documentation-only drift cleanup: the task applies the locked replacement edits and removes false or incomplete pre-T2 claims without expanding scope. (Why: see goals.md ### G17. Approach: see design.md ## G17.)

**Scope**

- **In:**
  - Replace the Invariant 3 rationale sentence in `skills/implementer-protocol/SKILL.md` with the locked design wording that preserves deterministic-status framing while clarifying downstream target repositories do not inherit qrspi-plus's committed `.gitignore` entry.
  - Replace the Commit-Before-Reporting step 4 parenthetical in `skills/implementer-protocol/SKILL.md` with `(keeps the scratch file out of the next round's diff)`.
  - Delete the redundant worktree-local-exclude sentence from the commit ownership bullet in `agents/qrspi-test-writer.md`, leaving the commit / `rm .qrspi-commit-msg.txt` workflow intact.
  - Preserve existing runtime behavior, existing invariant structure, and the existing commit-hygiene invariant tests.

- **Out:**
  - No sibling G17 task owns additional work; G17 does not fan out to other task specs.
  - Adding a new invariant, making the committed `.gitignore` a peer of Invariants 1/2/3, or rewriting Composition — explicitly out of scope.
  - Editing correct target-repo-scoped `.qrspi-commit-msg.txt` mentions in `skills/implement/SKILL.md` — design.md ## G17 says these remain accurate.
  - Changing `agents/qrspi-test-writer.md` L23 / L24 / L77-80 operational references or adding new tests — design.md ## G17 marks these as load-bearing / already covered.

**Definition of done**

- `skills/implementer-protocol/SKILL.md` contains the locked replacement Invariant 3 rationale sentence from design.md ## G17 deliverable 1.
- `skills/implementer-protocol/SKILL.md` contains the locked replacement Commit-Before-Reporting step 4 parenthetical `(keeps the scratch file out of the next round's diff)`.
- `agents/qrspi-test-writer.md` no longer carries the redundant sentence `The worktree-local .git/info/exclude already lists .qrspi-commit-msg.txt.` in the commit ownership bullet, while the commit / removal workflow remains present.
- The stale or false phrases `not gitignored`, `committed .gitignore is not polluted`, and single-layer exclude framing are removed from the edited surfaces.
- No new invariant, Composition rewrite, unrelated target-file edit, runtime behavior change, or test change is introduced.
- The edited prose follows R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), especially concise wording and positive-substitute framing.

**Test expectations**

- Grep/diff audit of `skills/implementer-protocol/SKILL.md` confirms the two locked replacement edits match design.md ## G17 deliverables 1 and 2.
- Grep/diff audit of `agents/qrspi-test-writer.md` confirms the design.md ## G17 deliverable 3 deletion is applied and the commit / `rm .qrspi-commit-msg.txt` workflow remains.
- Grep audit of the edited surfaces confirms stale prose is absent: `not gitignored`, the old `committed .gitignore is not polluted` rationale, and the redundant single-layer worktree-local exclude sentence.
- Review audit confirms no new invariant, no Composition rewrite, no unrelated `skills/implement/SKILL.md` edits, and no test changes.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); specifically verify concise shortened wording, positive-substitute current-contract wording, no dialogue-leakage, and no issue-history bloat.

**References**

- goals.md ### G17 — problem framing for stale prose after `.qrspi-commit-msg.txt` entered qrspi-plus's committed root `.gitignore`.
- design.md ## G17 — locked replacement prose, explicit non-goals, and no-new-tests rationale.
- structure.md ### `skills/implementer-protocol/SKILL.md` — per-file block for the two implementer-protocol replacement edits.
- structure.md ### `agents/qrspi-test-writer.md` — per-file block for the test-writer commit ownership sentence deletion.

### Task 37: G35 Structure SKILL absorbs unified architecture content with `structure-altitude-boundary` primitive

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G35]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** skills/structure/SKILL.md (modify), skills/_shared/structure-altitude-boundary.md (create), skills/structure/owns-defers.md (modify), tests/lint/test-structure-altitude-boundary-include.bats (create)
- **Dependencies:** Task 29. **Blocks:** T38 (Structure reviewer/scope-reviewer enforcement of the G35 boundary).
- **LOC estimate:** ~190

**Overview**

Move the destination side of the Design-to-Structure architecture migration into the Structure authoring surface by creating the shared Structure altitude primitive and teaching Structure to author unified system architecture plus unified test architecture. This keeps v0.7.2 from removing Design's unified architecture/test responsibilities without giving Structure the replacement contract. (Why: see goals.md ### G35. Approach: see design.md ## G35. File map: see structure.md ### `skills/structure/SKILL.md` and structure.md ### `skills/_shared/structure-altitude-boundary.md`.)

**Scope**

- **In:**
  - Create `skills/_shared/structure-altitude-boundary.md` as the single shared primitive carrying the locked Structure OWNS allowances and Structure DEFERS list as one contiguous markdown contract.
  - Update `skills/structure/SKILL.md` so Structure explicitly acknowledges ownership of unified system architecture diagram(s), file maps, module-boundary contracts, cross-solution component interactions, unified test architecture, and per-type stitching of per-solution acceptance criteria.
  - Add the Structure-side `## Test Architecture` authoring procedure that runs after Design approval, enumerates per-solution `Acceptance` subsections from design.md, groups them by release test taxonomy, identifies cross-cutting test invariants, and names the test type that owns each invariant.
  - Preserve positive Structure authoring guidance: tell Structure what to produce without re-litigating locked Design choices or descending into Plan/Implement-level test assertions.
  - Create `tests/lint/test-structure-altitude-boundary-include.bats` asserting that `agents/qrspi-structure-scope-reviewer.md` contains the literal `!cat skills/_shared/structure-altitude-boundary.md` directive on the line immediately after the introducer prose, and that `skills/structure/owns-defers.md` contains the same literal directive in place of the previous inline contract body. Removal of either include directive must fail the lint with a diagnostic naming the violating file and the missing directive.

- **Out:**
  - Reviewer-agent recognition/enforcement of unified system architecture and `## Test Architecture` as expected Structure content — T38 owns.
  - Scope-reviewer immediate-reasoning placement of `!cat skills/_shared/structure-altitude-boundary.md` — T38 owns.
  - Re-litigating Design decisions, per-solution flows, vendor research, detailed solution rationale, or per-task/unit-test assertions — Structure defers these by the G35 boundary.
  - Unrelated Structure procedure rewrites outside the unified architecture posture and `## Test Architecture` procedure.

**Definition of done**

- `skills/_shared/structure-altitude-boundary.md` exists and carries the locked Structure OWNS block plus the locked Structure DEFERS block from design.md ## G35 as a single shared primitive.
- `skills/structure/SKILL.md` states that Structure owns unified system architecture diagram(s), file map/module boundaries, cross-solution component interactions, unified test architecture, and per-type stitching of per-solution acceptance criteria.
- `skills/structure/SKILL.md` contains a `## Test Architecture` authoring procedure that is explicitly after Design approval and includes the load-bearing anchor phrases `name the test taxonomy`, `enumerate cross-cutting test invariants`, and `name the test type that owns each invariant`.
- The `## Test Architecture` procedure stitches locked per-solution `Acceptance` material from design.md into a release-level test taxonomy without re-opening Design rationale or adding Plan/Implement-level assertions.
- The edited prompt prose uses positive-substitute wording that describes what Structure authors, not only what Design no longer owns.
- The task does not edit reviewer agents, assume unresolved runtime `!cat` expansion beyond the primitive's intended source form, introduce implementation-level test assertions beyond the named include-guard lint, or rewrite unrelated Structure procedures.
- `tests/lint/test-structure-altitude-boundary-include.bats` exists and asserts the literal `!cat skills/_shared/structure-altitude-boundary.md` directive is present in both consumer files at the canonical insertion points; removal of either directive fails the lint with a file-and-directive-naming diagnostic.

**Test expectations**

- File-existence checks confirm `skills/_shared/structure-altitude-boundary.md` exists and `skills/structure/SKILL.md` remains a modified existing target file for this task.
- Diff or grep audit confirms the primitive carries the locked Structure OWNS and Structure DEFERS content from design.md ## G35 / structure.md ### `skills/_shared/structure-altitude-boundary.md` without drift.
- Grep `skills/structure/SKILL.md` for `## Test Architecture`, `after Design approval`, `name the test taxonomy`, `enumerate cross-cutting test invariants`, and `name the test type that owns each invariant`.
- Content audit confirms `skills/structure/SKILL.md` names unified system architecture, module boundaries, cross-solution component interactions, unified test architecture, and per-type stitching as Structure-owned responsibilities.
- Run `tests/lint/test-structure-altitude-boundary-include.bats` and confirm it passes against the implemented consumer files; a negative-test fixture (removing the include directive from one consumer) must cause the lint to fail with a diagnostic naming the violating file and the missing directive.
- Scope audit confirms no reviewer-agent edits, no implementation-level test assertions beyond the named include-guard lint, and no unrelated Structure procedure rewrites were introduced by this task.
- Implementer applies R1-R7 plus cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer verifies the same content-semantic rules application against the new primitive and Structure SKILL prose.

**References**

- goals.md ### G35 — problem framing for the empty Structure-side destination after Design relinquishes unified architecture/test architecture.
- design.md ## G35 — locked D2/D3 OWNS/DEFERS contract, D4 Structure SKILL procedure skeleton, D5 target surfaces, and acceptance criteria.
- structure.md ### `skills/structure/SKILL.md` — G35 Structure authoring surface for unified architecture posture and `## Test Architecture` procedure.
- structure.md ### `skills/_shared/structure-altitude-boundary.md` — shared primitive body carrying the G35 Structure OWNS/DEFERS contract.

### Task 38: G35 Structure reviewers (artifact + scope) enforce architecture-only-in-structure boundary

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G35]
- **Task type:** lightweight
- **Model:** sonnet
- **Target files:** modify `agents/qrspi-structure-reviewer.md`; modify `agents/qrspi-structure-scope-reviewer.md`
- **Dependencies:** Task 37
- **LOC estimate:** ~120

**Overview**

Update the Structure artifact-quality and scope-reviewer prompts so they enforce the new Structure ownership boundary for unified system architecture and unified test architecture without flagging valid structure.md content as drift. This is the reviewer-enforcement half of the G35 migration after T37 creates the Structure authoring/shared-boundary surface. (Why: see goals.md ### G35. Approach: see design.md ## G35.)

**Scope**

- **In:**
  - Update `agents/qrspi-structure-reviewer.md` so the artifact-quality reviewer treats a unified system architecture diagram and a top-level `## Test Architecture` section as expected Structure content, not anomalous or out-of-scope content.
  - Update `agents/qrspi-structure-scope-reviewer.md` so the introducer prose appears immediately after the Step 1 Read citation, followed on the next line by `!cat skills/_shared/structure-altitude-boundary.md`.
  - Preserve the Structure altitude boundary: Structure stitches locked Design solutions into architecture/test architecture, but does not re-litigate Design decisions or descend into per-task assertions/unit-test code.
  - Preserve stable audit anchors: `unified system architecture`, `## Test Architecture`, `structure-altitude-boundary`, `Structure OWNS`, `Structure DEFERS`, `per-solution Acceptance`, and `cross-cutting test invariants`.

- **Out:**
  - Creating `skills/_shared/structure-altitude-boundary.md` and updating `skills/structure/SKILL.md` — T37 owns.
  - Authoring or changing the unified system architecture / `## Test Architecture` procedure itself — T37 owns the Structure authoring surface.
  - Adding lint tests or test-code files — existing task text explicitly keeps this reviewer-prompt task to prompt-prose surfaces.
  - Editing other artifact reviewers, other scope reviewers, Design, Plan, or implementation/test-code surfaces.

**Definition of done**

- `agents/qrspi-structure-reviewer.md` no longer carries stale pre-G35 assumptions that architecture diagrams or unified test architecture are anomalous in Structure.
- `agents/qrspi-structure-reviewer.md` positively instructs the reviewer to recognize a unified system architecture diagram and a top-level `## Test Architecture` section as expected Structure content while preserving minimal artifact-quality reviewer duties.
- `agents/qrspi-structure-scope-reviewer.md` contains the required introducer prose immediately after the Step 1 Read citation, followed by the `!cat skills/_shared/structure-altitude-boundary.md` directive on the next line.
- The scope-reviewer update keeps the shared Structure OWNS/DEFERS vocabulary in the reviewer's immediate reasoning context and does not delegate the boundary to optional memory or broad reviewer discretion.
- The prompts preserve the distinction between artifact-quality review and scope/boundary review, with no re-litigation of Design choices and no ownership of per-task assertions or unit-test code in Structure.
- Prompt prose applies R1-R7 plus the cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), including imperative hot-path boundary instructions, rationale only where it explains false-positive drift risk, no generic examples beyond the v0.7.2 mental-replay anchor, no decorative diagrams in prompt prose, and no TODOs/placeholders/stale line-number references.
- No unrelated reviewer-agent or artifact-surface edits are made.

**Test expectations**

- Inspect `agents/qrspi-structure-reviewer.md` for positive obligations that treat `unified system architecture` and `## Test Architecture` as expected Structure content; confirm stale pre-G35 anomaly/drift framing is absent.
- Inspect `agents/qrspi-structure-scope-reviewer.md` to confirm the introducer sentence lands immediately after the Step 1 Read citation and the next line is exactly `!cat skills/_shared/structure-altitude-boundary.md`.
- Grep for the stable audit anchors named in the Definition of done across the two target files, as applicable to each reviewer surface.
- Apply R1-R7 and the cross-cutting principles from `skills/_shared/prompt-design-rules.md` to the prompt prose changes; verify positive reviewer obligations, byte-identical shared-boundary vocabulary for scope reasoning, and separation between artifact-quality review and scope/boundary review.
- Mental-replay check: a v0.7.2 `structure.md` containing a unified system architecture Mermaid diagram plus a top-level `## Test Architecture` section stitching per-goal/per-CD acceptance criteria by test type would not trigger a Structure scope finding under these reviewer prompts.
- Verify no other artifact scope-reviewers, no test-code files, no unrelated Structure procedure text, and no stale line-number references are changed.

**References**

- goals.md ### G35 — problem framing for the Structure-side migration destination and reviewer false-positive failure mode.
- design.md ## G35 — locked OWNS/DEFERS boundary, reviewer edit surfaces, mental-replay acceptance criterion, and non-goals.
- structure.md ### `agents/qrspi-structure-reviewer.md` — artifact-quality reviewer responsibility and mental-replay anchor.
- structure.md ### `agents/qrspi-structure-scope-reviewer.md` — scope-reviewer insertion site, introducer prose, and `!cat` include hook.

### Task 39: G32 plugin build pipeline (`tools/build-plugin.mjs` + `render-skill.sh` + `g4-section-anchor-refresh.sh` + marketplace.json + CI workflow + CONTRIBUTING)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G32]
- **Task type:** code
- **Model:** opus
- **Target files:** `tools/build-plugin.mjs`; `tools/render-skill.sh`; `tools/g4-section-anchor-refresh.sh`; `.claude-plugin/marketplace.json`; `.github/workflows/ci.yml`; `CONTRIBUTING.md`; `tests/unit/test-build-gate.bats`; `tests/unit/test-ci-workflow-shape.bats`; `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`; `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`; existing callers/references to `scripts/render-skill.sh`, `scripts/g4-section-anchor-refresh.sh`, and `${CLAUDE_SKILL_DIR}` sites.
- **Dependencies:** Task 25
- **LOC estimate:** ~360
- **Sizing exception:** CI scaffolding
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Implement the G32 plugin build pipeline that turns the source repo into a committed `build/` install artifact, expands `!cat` includes at build time, strips dev-only paths, moves dev helpers into `tools/`, and points marketplace installs at the built tree. This preserves Task 25/G31 shared-snippet authoring while making every supported host receive fully-expanded runtime plugin content. (Why: see goals.md ### G32. Approach: see design.md ## G32.)

**Scope**

- **In:**
  - Create `tools/build-plugin.mjs` as a Node.js ES module using only stdlib; it reads `.claude-plugin/plugin.json` component paths plus the fixed runtime include list and emits a reproducible `build/` tree.
  - Implement the D3 `!cat` resolver with the single whole-line bare-relative grammar, repo-root path resolution, transitive expansion, cycle detection, CR stripping, byte-faithful replacement, idempotence, and fail-loud diagnostics.
  - Fail non-zero with file:line plus reason for malformed `!cat` lines, missing targets, include cycles with full cycle printed, absolute/path-traversal attempts, outside-root includes, and any `${CLAUDE_SKILL_DIR}` occurrence in shipped files.
  - Copy runtime plugin content and defensive shared snippets into `build/`, while omitting dev-only paths including `docs/`, `tools/`, `tests/`, and review/work artifacts.
  - Move `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` to `tools/`, update callers/docs/references, remove old `scripts/` paths, and preserve `scripts/` as runtime-only while `tools/` remains dev-only and unshipped.
  - Convert legacy `${CLAUDE_SKILL_DIR}` sites to bare-relative form and prove shipped files contain no remaining `${CLAUDE_SKILL_DIR}`.
  - Update `.claude-plugin/marketplace.json` in place so the `qrspi` plugin source points at `./build` and v0.7.2 release metadata lands.
  - Extend the single CI workflow so PRs run `node tools/build-plugin.mjs` followed by `git diff --exit-code build/ .claude-plugin/marketplace.json`, include the recursive BATS/lint coverage required for this release, and avoid Actions auto-commit behavior.
  - Update `CONTRIBUTING.md` with the edit → build → add source plus `build/` → commit → push workflow, build-sync failure modes, rationale for committing `build/`, and the `scripts/` runtime vs `tools/` dev-time distinction.
  - Add/update the named unit and acceptance tests that pin resolver behavior, stale-build diagnostics, CI workflow shape, build tree strip/copy invariants, release-level G32 acceptance, and the two resolver fixtures.

- **Out:**
  - No sibling task shares G32, so there are no Goal-ID sibling deferrals.
  - Variables, conditionals, fenced `!cat` syntax, and `${CLAUDE_SKILL_DIR}` resolver support are not introduced for v0.7.2.
  - Tarball/release-asset publishing, sibling build branches, separate build workflows, CI auto-commit steps, and pre-commit hooks are out of scope for v0.7.2.
  - Rewriting or extending `tools/render-skill.sh` with recursion/cycle semantics is out of scope; `tools/build-plugin.mjs` owns production expansion.
  - Codex CLI `skills:` frontmatter portability is a v0.7.3+ open question and is not solved by this task.

**Definition of done**

- `node tools/build-plugin.mjs` creates a reproducible `build/` tree from source using `.claude-plugin/plugin.json` component paths plus the fixed runtime include list: `scripts/`, `templates/`, `LICENSE`, `README.md`, optional `AGENTS.md`/`CLAUDE.md`, and `.claude-plugin/`.
- Built output includes runtime plugin content and defensive shared snippets, including `build/skills/_shared/prompt-prose-detection.md`, and excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`.
- The built `build/skills/goals/SKILL.md` contains inlined `skills/goals/owns-defers.md` content and no remaining `!cat` directive for that include.
- The resolver accepts only the strict whole-line bare-relative grammar, expands nested includes transitively, preserves included content without extra blank lines, strips CR characters, and is byte-identical/idempotent when run against already-expanded output.
- The resolver fails non-zero with file:line plus reason for all listed D3 fail-loud conditions, including malformed directives, missing targets, include cycles, absolute/path-traversal attempts, outside-root includes, and `${CLAUDE_SKILL_DIR}` in shipped files.
- Legacy `${CLAUDE_SKILL_DIR}` sites are converted to bare-relative form, and shipped-file grep proves zero remaining `${CLAUDE_SKILL_DIR}` occurrences.
- `tools/render-skill.sh` and `tools/g4-section-anchor-refresh.sh` exist at their new paths; `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` no longer exist; callers/docs/reference sites are updated.
- `.claude-plugin/marketplace.json` remains in place, points the `qrspi` plugin source at `./build`, and carries the v0.7.2 release metadata.
- CI remains a single workflow, runs the build-sync gate, includes the recursive BATS/lint coverage needed for this release, and contains no Actions auto-commit step.
- `CONTRIBUTING.md` documents the local rebuild workflow, PR-blocking failure modes, why `build/` is committed, and the runtime/dev-time split between `scripts/` and `tools/`.
- No variables, conditionals, fenced `!cat` syntax, tarball/release-asset pipeline, sibling build branch, pre-commit hook, or CI auto-commit behavior is introduced.
- `tools/build-plugin.mjs` canonicalizes every `!cat` target path with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. This closes a symlink-escape exfiltration surface where a checked-in `skills/<dir>/<name>.md` symlink could point at `/etc/passwd` or any other path outside the repo and have its contents inlined into a shipped `build/` file. The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh` (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`).

**Test expectations**

- Run `node tools/build-plugin.mjs`; assert it exits 0 and creates a reproducible `build/` tree from the manifest plus fixed include list.
- Audit the built tree for required runtime content and defensive snippets, and assert `build/docs/`, `build/tools/`, and `build/tests/` do not exist.
- Inspect `build/skills/goals/SKILL.md` for inlined `skills/goals/owns-defers.md` content and absence of the corresponding `!cat` directive.
- Unit-test resolver success cases for strict grammar acceptance, repo-root resolution, transitive nested expansion, CR stripping, no extra blank lines, and idempotent byte-identical re-run behavior.
- Unit-test resolver failure cases for malformed `!cat` lines, missing targets, include cycles with full cycle printed, absolute paths, path traversal/escaping attempts, outside-root includes, and `${CLAUDE_SKILL_DIR}` in shipped files.
- Grep source/shipped files to confirm legacy `${CLAUDE_SKILL_DIR}` sites are converted and no shipped file still contains `${CLAUDE_SKILL_DIR}`.
- Verify the old `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` paths are gone, the new `tools/` paths exist, callers/docs are updated, `scripts/` remains runtime-only, and `tools/` is omitted from `build/`.
- Assert `.claude-plugin/marketplace.json` points the `qrspi` plugin source at `./build`, carries v0.7.2 release metadata, and is included in the build-sync diff gate.
- Assert CI runs `node tools/build-plugin.mjs` followed by `git diff --exit-code build/ .claude-plugin/marketplace.json`, keeps one workflow, includes recursive BATS/lint coverage needed for this release, and has no Actions auto-commit step.
- Verify `CONTRIBUTING.md` documents the edit → build → add source plus `build/` → commit → push workflow, the two PR-blocking failure modes, the committed-`build/` rationale, and the `scripts/` vs `tools/` distinction.
- Acceptance fixtures cover a legacy `${CLAUDE_SKILL_DIR}` directive failure and a deliberate include-cycle failure with the required diagnostics.
- Symlink-escape regression: a fixture commits a `!cat`-targeted file that is itself a symlink whose canonical target is outside `$REPO_ROOT` (e.g., `/etc/passwd` or `/tmp/secret`); the build fails non-zero before any byte of the symlink's referent enters the `build/` tree, with a stderr diagnostic containing `resolves outside repository`. Mirrors T21's symlink-out-of-repo regression in `tests/unit/test-dispatch-agent.bats` so the two canonicalization surfaces use the same audit-friendly diagnostic phrase.

**References**

- goals.md ### G32 — problem framing for source/install divergence, non-portable `!cat` expansion, and dev-only content leakage.
- design.md ## G32 — build output, strip-scope, resolver semantics, CI gate, marketplace, CONTRIBUTING, and v0.7.2 non-goals.
- structure.md ### `tools/build-plugin.mjs` — build script responsibilities, D1-D4 outline, acceptance spot-checks, and legacy-form cleanup.
- structure.md ### `tools/render-skill.sh` — relocated dev-only helper contract and non-goal for resolver semantics.
- structure.md ### `tools/g4-section-anchor-refresh.sh` — relocated dev-only anchor-refresh helper contract and post-move `scripts/` invariant.
- structure.md ### `.claude-plugin/marketplace.json` — source-field flip, unchanged file location, version bump, and build-sync dependency.
- structure.md ### `.github/workflows/ci.yml` — single workflow, recursive BATS/lint coverage, build-sync gate, and no auto-commit step.
- structure.md ### `CONTRIBUTING.md` — local rebuild workflow, failure-mode explainer, committed-build rationale, and `tools/` vs `scripts/` guidance.
- structure.md ### `tests/unit/test-build-gate.bats` — resolver, fixture, idempotence, recursion, grammar, and stale-build diagnostic coverage.
- structure.md ### `tests/unit/test-ci-workflow-shape.bats` — CI build-sync and recursive coverage assertions.
- structure.md ### `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` — built-tree strip/copy and shipped-file invariants.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — release-level G32 acceptance for `build/`, marketplace source, and resolver fixtures.

### Task 40: G21 bats short-circuit hardening with body-assertion-guard lint (incl. G26 BW02/minimum-version rule)

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G21, G26]
- **Task type:** code
- **Model:** sonnet
- **Target files:** `tests/unit/test-using-qrspi-vocab.bats`, `tests/lint/test-bats-body-assertion-guard.bats`, `tests/unit/test-ci-workflow-shape.bats`, `.github/workflows/ci.yml` (only if current CI/test entrypoints do not already execute `tests/lint/` or recursive `tests/` coverage)
- **Dependencies:** none. **Blocks:** none.
- **LOC estimate:** ~140

**Overview**

Harden the BATS gate against vacuous `$body` assertions by guarding existing negation pins, adding a corpus lint test, and ensuring that lint runs on the blocking CI/test path. The lint also carries the already-planned G26-ready BW02 rule surface so the corpus is walked once. (Why: see goals.md ### G21. Approach: see design.md ## G21.)

**Scope**

- **In:**
  - In `tests/unit/test-using-qrspi-vocab.bats`, add `[ -n "$body" ]` guards earlier in the same `@test` block for every existing unguarded `[[ "$body" != *...* ]]` negation assertion, preserving the already-guarded R5-era reference patterns.
  - Create `tests/lint/test-bats-body-assertion-guard.bats` to discover all `*.bats` files under `tests/` while excluding itself, parse `@test` blocks delimited by `^@test "..." \{` and a column-0 closing `}`, and fail any `[[ "$body" ... ]]` assertion without an earlier `[ -n "$body" ]` guard in the same block.
  - Emit clear `file:line` diagnostics for every unguarded `$body` assertion and rely on the existing guarded R5-era pins in `test-using-qrspi-vocab.bats` as live positive controls.
  - Structure the lint file with separate `@test` coverage for the G21 `$body` guard rule and the G26-ready BW02/minimum-version rule surface; the initial BW02 pattern set is `run --separate-stderr`, with diagnostics naming both triggering feature and `file:line`.
  - Extend CI or the existing test runner only as needed so `tests/lint/test-bats-body-assertion-guard.bats` runs on the blocking path, and update/add workflow-shape coverage that asserts the new lint coverage is executed.

- **Out:**
  - BATS deprecation sweep beyond the BW02/minimum-version rule surface this task lands — the BW02 rule is the canonical G26 deliverable (per design.md ## G26 + ## G21 Amendment at G26 design-lock); no further per-file deprecation cleanup ships under a standalone G26 task in v0.7.2.
  - G32 build-sync assertions and broader plugin build-pipeline CI behavior — T39 owns; this task keeps workflow-shape coverage scoped to G21 lint execution.
  - Shellcheck rules and pre-commit hooks — explicitly not part of G21; CI is the durable enforcement layer.
  - BATS upstream/root-cause investigation for #244 — deferred outside this task; the lint gate closes the v0.7.2 risk surface.

**Definition of done**

- Every existing unguarded `[[ "$body" != *...* ]]` negation assertion in `tests/unit/test-using-qrspi-vocab.bats` has a preceding `[ -n "$body" ]` guard earlier in the same `@test` block.
- The already-guarded R5-era reference assertions in `tests/unit/test-using-qrspi-vocab.bats` remain guarded and continue to pass.
- `tests/lint/test-bats-body-assertion-guard.bats` exists, excludes itself from discovery, walks all other `tests/**/*.bats` files, and parses `@test` blocks using the specified opener/column-0 closer shape.
- The G21 lint rule fails loudly with `file:line` diagnostics for every `[[ "$body" ... ]]` assertion that lacks an earlier `[ -n "$body" ]` guard in the same block.
- The lint file includes a separate BW02/minimum-version rule surface using the initial trigger `run --separate-stderr`, and BW02 violations report both the triggering feature and `file:line`.
- CI or the existing blocking test runner executes the new lint test; no shellcheck rule and no pre-commit hook are added.
- Workflow-shape test coverage asserts the G21 lint coverage is executed without taking over G32 build-sync assertions.
- Targeted validation passes for `tests/unit/test-using-qrspi-vocab.bats`, the new lint test, and any workflow-shape test touched by this task.

**Test expectations**

- Grep/audit `tests/unit/test-using-qrspi-vocab.bats` to confirm each existing unguarded `[[ "$body" != *...* ]]` negation now has an earlier `[ -n "$body" ]` guard in the same `@test` block.
- Run the new lint test and confirm it accepts the existing guarded R5-era pins as live positive controls.
- Review the lint implementation to confirm it discovers `tests/**/*.bats`, excludes itself, uses the specified `@test` block boundaries, and emits `file:line` diagnostics for G21 failures.
- Review the BW02 rule surface to confirm it is in separate `@test` coverage, starts with the `run --separate-stderr` trigger, and reports both triggering feature and `file:line`.
- Inspect CI/test-runner wiring and workflow-shape assertions to confirm `tests/lint/test-bats-body-assertion-guard.bats` runs on the blocking path; confirm no pre-commit hook or shellcheck rule is introduced.
- Run a targeted BATS invocation covering `tests/unit/test-using-qrspi-vocab.bats`, `tests/lint/test-bats-body-assertion-guard.bats`, and any touched workflow-shape test.

**References**

- goals.md ### G21 — problem framing for BATS short-circuit / empty-extractor silent passes.
- goals.md ### G26 — problem framing for the BW02/minimum-version regression class (absorbed into this task's lint surface).
- design.md ## G21 — locked retrofit-only, lint-gate, CI-only, and BW02-amendment implementation shape (Amendment at G26 design-lock specifies BW02 rides in the G21 lint file).
- design.md ## G26 — locked disposition that G26's runtime concern is moot (splitter already fixed pre-v0.7.2) and remaining work is the BW02 lint rule consolidated into G21's lint file.
- structure.md ### `tests/unit/test-using-qrspi-vocab.bats` — guarded `$body` retrofit surface and live positive controls.
- structure.md ### `tests/lint/test-bats-body-assertion-guard.bats` — new lint file responsibilities for G21 and G26 BW02 coverage.
- structure.md ### `tests/unit/test-ci-workflow-shape.bats` — workflow-shape assertions for recursive lint coverage.
- structure.md ### `.github/workflows/ci.yml` — CI/test-entrypoint surface that may need recursive lint coverage.
- structure.md ## CI Pipeline — release-level CI shape for lint and BATS execution.

### Task 44: G24-F05 anti-pattern pin regex hardening

- **Phase:** 1
- **Pipeline:** full
- **Goal IDs:** [G24]
- **Task type:** code
- **Model:** sonnet
- **Target files:** modify `tests/unit/test-using-qrspi-vocab.bats`; modify `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`
- **Dependencies:** [Task 17, Task 40]
- **LOC estimate:** ~80

**Overview**

Harden the G24-F05 silent-fallback prose pins so they guard the contract's meaning instead of one brittle sentence, then add phase-level acceptance coverage for the hardened pin behavior. The work lands after the dispatch-routing prose settles and stays limited to the four existing pin sites plus their release acceptance surface. (Why: see goals.md ### G24. Approach: see design.md ## G24.)

**Scope**

- **In:**
  - Replace the four existing literal pins for `silently fall back to the agent-bundled default` in `tests/unit/test-using-qrspi-vocab.bats` with in-place regex assertions matching the silent-fallback semantic family rather than that exact phrase.
  - Ensure each rewritten negative regex assertion has a same-`@test` `$body` presence guard (`[ -n "$body" ]`) before the regex is evaluated, so missing or empty extracted bodies fail loudly.
  - Cover equivalent silent-fallback regressions such as `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`, while allowing prose that does not describe silent fallback/default behavior.
  - Add release-level coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` proving the hardened vocab pins are in the phase acceptance path and the semantic negative cases trip the pin.

- **Out:**
  - Consolidating repeated `using-qrspi` per-H4 fail-loud prose, centralizing tier vocabulary regexes, parameterizing dispatch-routing assertion callers, or promoting H4 extraction into shared bats helpers — all four of these G24-F01/F02/F03/F04 surfaces are moot in v0.7.2 per design.md ## G24 (F01/F03 helpers and target files do not exist in current tree; F02 auto-resolves via CD-1; F04 absorbed into the G3/CD-1 dispatch rewrite).
  - Adding a new shared bats helper or utility for the regex pin pattern — explicit non-goal for this four-site surface.
  - Editing the dispatch-routing prose itself — upstream dispatch-routing tasks settle that prose; this task only hardens the pins against the settled wording.

**Definition of done**

- The four literal-substring pins in `tests/unit/test-using-qrspi-vocab.bats` are replaced in place by regex assertions that match silent-fallback intent instead of the exact historical sentence.
- Each rewritten assertion is preceded earlier in the same `@test` block by `[ -n "$body" ]`; no bare `[[ ! "$body" =~ ... ]]` pattern can silently pass on an empty body.
- The regex rejects equivalent contract regressions including `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`.
- The regex allows prose that does not describe silent fallback/default behavior.
- The unit test remains green against the post-dispatch-routing prose produced by the earlier schema, validation, and fail-loud-invariant edits.
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` exercises the hardened vocab pins as part of phase acceptance and proves the semantic negative cases trip the pin.
- The diff stays scoped to the four pin sites and their acceptance coverage: no new shared bats helper, no new test utility, and no unrelated assertions rewritten.

**Test expectations**

- Inspect `tests/unit/test-using-qrspi-vocab.bats` and confirm the four old literal `silently fall back to the agent-bundled default` pins no longer appear as literal-only assertions.
- Grep or targeted test inspection confirms each rewritten pin has `[ -n "$body" ]` earlier in the same `@test` block before the negative regex assertion.
- Negative-case coverage demonstrates the regex trips on `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`.
- Positive/non-regression coverage demonstrates prose without silent-fallback/default semantics is allowed.
- Run the touched unit test so `tests/unit/test-using-qrspi-vocab.bats` passes against the settled dispatch-routing prose.
- Run the phase acceptance coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` that proves the hardened vocab pins participate in the release-level acceptance path and the semantic negative cases trip the pin.
- Audit the diff to confirm no shared helper, new bats utility, or unrelated assertion rewrite was added.

**References**

- goals.md ### G24 — G24-F05 problem framing: literal anti-pattern pins can silently miss rephrased silent-fallback regressions.
- design.md ## G24 — post-audit re-scope to F05 only, regex-pin deliverables, `$body` guard requirement, and acceptance criteria.
- structure.md ### `tests/unit/test-using-qrspi-vocab.bats` — per-file test block for the four in-place silent-fallback regex pins and G21 guard inheritance.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — per-file release acceptance block for G24 regex-pin survival and semantic negative cases.

