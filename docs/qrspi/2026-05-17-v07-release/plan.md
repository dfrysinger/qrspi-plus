---
status: approved
phase_start_commit: 13bc4bbcb9d3ecc63c5cc61e6dca5fc7d507b959  # qrspi-plus main tip when qrspi/v07-release/main forked
test_writer_model: sonnet
build_command: 'none'  # rationale: qrspi-plus is pure-script/markdown; no build artifact
---

# Implementation Plan: qrspi-plus v0.7 release

## Overview

This plan decomposes the v0.7 release into 43 tasks (T01–T42 unconditional, plus T43 conditional on the T33 spike outcome) across a single Phase 1 made up of 10 vertical slices (per `phasing.md`). The phase model honors the Phase 1 PoC framing: the release IS the PoC for the qrspi-plus meta-stack, and each slice independently demonstrates a cross-layer behavior (config + dispatcher + policy consumer; dual-mode agent + orchestrator gate + per-framework adapters; CI workflow + hygiene contract + evergreen scan; etc.). Iron Law 1 is preserved — every slice traverses every layer it touches before the next slice begins.

Ordering rationale operates at two levels. **Cross-slice:** Slice 1 (cost-opt routing) precedes Slice 2 (TDD split) because the test-writer agent gains a `model_role:` frontmatter field in Slice 2 that depends on the G1 resolution chain landing in Slice 1; Slice 3 (CI + hygiene) lands before Slice 4 (parallelize hygiene + G14 consumer migration) because the CI workflow introduced by T14 must exist before the new Slice 4 BATS pins it will execute can be committed to the feature branch and validated; Slices 5–10 are largely independent and could parallelize at the wave level, with the exception that Slice 6 (T31) depends on Slice 5 (T24) because both edit `skills/plan/SKILL.md` — Slice 5's spec-frontmatter edits land first so Slice 6's post-approval split orchestration can reason over the finalized frontmatter shape. Within Slice 7, the G4 spike report and probe script land before the Mechanism B anchor index work so the spike outcome is recorded in the artifact directory before any anchor-index pin runs. **Within-slice:** dependency edges follow the contract-first rule — schema/helper/contract tasks precede their consumers; documentation-only edits (e.g., `### Per-Task Routing` reference in `skills/implement/SKILL.md`) precede the BATS pins that observe the documented shape.

The longest dependency chain runs through Slice 1: T01 (config schema) -> T02 (prompt-utils library) -> T03 (universal dispatcher) -> T04 (codex-shim retirement) -> T05 (Implement-skill routing chain + telemetry emission) -> T06 (agent frontmatter) -> T07 (G5 telemetry test) — seven tasks. All other slices have shorter internal chains (2-4 deep). Cross-slice dependencies are minimal: Slice 2 depends on Slice 1 only for the role-frontmatter convention (documentation-level, not a build dependency); Slice 4 depends on Slice 2's helper (T13); Slices 5-10 each depend only on their respective predecessor slices' artifacts and on the shared helper from T13.

## Phase 1: v0.7 release — PoC

Phase 1 ships the entire v0.7 release as a single PoC phase comprising all 10 slices from `phasing.md`. The slice grouping in the task list below is exact: T01–T07 = Slice 1 (cost-opt routing, G1+G2+G5); T08–T13 = Slice 2 (TDD test-writer split, G6+G14); T14–T19 = Slice 3 (hygiene + CI, G7+G17+G18); T20–T23 = Slice 4 (parallelize hygiene, G8+G9+G14); T24–T30 = Slice 5 (visual-fidelity + ref gate, G10+G11); T31–T32 = Slice 6 (plan post-approval split, G3); T33–T37 + T43 (conditional) = Slice 7 (caching spike + Mechanism B + conditional Path B, G4); T38–T39 = Slice 8 (commit scratch staging, G12); T40 = Slice 9 (u14-lint worktree, G13); T41–T42 = Slice 10 (Replan boundary with Goals, G15). T43 is the only conditional task: it executes only if the T33 spike report selects Path B; it is a NO-OP under Path A. The release as a whole proves the qrspi-plus meta-stack works end-to-end against the 17 current-phase goals.

### Task ordering and dependency graph

Tasks are dependency-respecting in declaration order — every `depends on:` reference points backward. Within each slice, contract/schema/helper tasks precede consumer tasks: e.g., in Slice 1 the config schema (T01) and prompt-utils library (T02) precede the universal dispatcher (T03), which precedes the codex-shim retirement (T04) and the Implement-skill routing chain (T05). In Slice 2 the shared BATS helper (T13) is authored alongside its first consumer (the dual-mode test, T11) but the file is declared before the test that loads it. Cross-slice dependencies are explicit and minimal — Slice 4's helper-migration tasks (T22–T23) depend on T13; Slice 2's agent-frontmatter convention is informed by T01's role-resolution chain (advisory, not a build dependency).

### Tasks

T01 — config.md routing/providers/validators schema in using-qrspi (Slice 1, G1+G5) — depends on: none
T02 — Shared prompt-utils library (scripts/lib/llm-prompt-utils.sh) (Slice 1, G2) — depends on: none
T03 — Universal dispatcher script (scripts/run-third-party-llm.sh) (Slice 1, G2) — depends on: T01, T02
T04 — Retire codex-shim entry behavior to thin forwarder (Slice 1, G2) — depends on: T03
T05 — Implement-skill per-task routing chain + citation-density validator dispatch + telemetry emission (Slice 1, G1+G5) — depends on: T01, T03
T06 — Add model_role frontmatter to specialist, collator, and lightweight-implementer agents (Slice 1, G1+G5) — depends on: T01
T07 — Slice 1 unit pins: dispatcher contract, config-routing precedence, citation-density validator, routing-matrix application, G5 telemetry emission (Slice 1, G1+G2+G5) — depends on: T03, T05, T06

T08 — Dual-mode qrspi-test-writer agent body (Slice 2, G6) — depends on: T01
T09 — RED-verification adapter contract documentation (skills/implement/red-verification-adapters.md) (Slice 2, G6) — depends on: none
T10 — Four RED-verification adapter scripts (bats, vitest, jest, pytest) (Slice 2, G6) — depends on: T09
T11 — Implement-skill pre-implementer dispatch + RED-verification gate + qrspi-implementer split-mode awareness (Slice 2, G6) — depends on: T08, T10
T12 — Plan-skill per-task dispatch-order note + task_type defaulting (Slice 2, G6) — depends on: T11
T13 — Shared BATS helper tests/helpers/skill-markdown.bash + helper-self pins + Slice 2 pins (dual-mode, RED gate, dispatch order) (Slice 2, G6+G14) — depends on: T08, T11, T12

T14 — .github/workflows/ci.yml (lint + bash32 jobs) (Slice 3, G17) — depends on: none
T15 — Combined G7+G18 hygiene contract in implementer-protocol/SKILL.md + qrspi-implementer + qrspi-implementer-lightweight preload-only edits (Slice 3, G7+G18) — depends on: none
T16 — Integrate-skill CI-gate consumer update (Slice 3, G17) — depends on: T14
T17 — test-evergreen-markdown.bats (Slice 3, G18) — depends on: T13, T14, T15
T18 — test-hygiene-self-check.bats (Slice 3, G7+G18) — depends on: T13, T15
T19 — test-ci-workflow-shape.bats + test-bash32-runtime-coverage.bats (Slice 3, G17) — depends on: T13, T14

T20 — parallelize/owns-defers.md Worktree-Aware Setup Validation OWNS addition (Slice 4, G8) — depends on: none
T21 — parallelize/SKILL.md multi-stage suffix grammar + qrspi-parallelize-reviewer vocabulary alignment (Slice 4, G9) — depends on: none
T22 — Migrate three existing BATS files to skill-markdown.bash helper (test-skill-md-content-patterns, test-cross-skill-contracts, test-worktree-aware-defaults) (Slice 4, G14) — depends on: T13
T23 — New Slice 4 pins: test-parallelize-owns-defers + test-parallelize-vocab (Slice 4, G8+G9+G14) — depends on: T13, T20, T21

T24 — Plan-skill per-task spec frontmatter (reference_gate, reference_artifact, ui, lift_source) + paired-field refuse-to-write + SPEC OVERRIDES SOURCE contract + ui_producing migration (Slice 5, G10+G11) — depends on: none
T25 — Structure-skill UI Reference Affordances section spec (Slice 5, G11) — depends on: T24
T26 — Parallelize-skill reference-gate wave termination + parallelization.md note shape (Slice 5, G10) — depends on: T24
T27 — Implement-skill reference-gate human pause + wave_context companion + visual-fidelity reviewer dispatch for ui:true (Slice 5, G10+G11) — depends on: T24, T26
T28 — Refine qrspi-visual-fidelity-reviewer.md to consume ui/lift_source/wave_context (Slice 5, G11) — depends on: T24, T27
T29 — reviewer-protocol/SKILL.md quick-tier finding-disposition guidance + design-skill reference-reviewer checklist (Slice 5, G10+G11) — depends on: none
T30 — Slice 5 pins: reference-gate-fields, ui-task-fields, wave-context-shape, quick-tier-wording, reference-gate-pause integration (Slice 5, G10+G11+G14) — depends on: T13, T24, T25, T26, T27, T28, T29

T31 — Plan-skill post-approval split orchestration + N-threshold carve-out (Slice 6, G3) — depends on: T24
T32 — plan/post-approval-split-contract.md sub-subagent contract + test-plan-post-approval-split pin (Slice 6, G3) — depends on: T13, T31

T33 — G4 cache-probe script (scripts/g4-cache-probe.sh) + spike report deliverable (docs/.../spikes/g4-cache-probe.md) (Slice 7, G4) — depends on: T03
T34 — Three colocated section-anchor index files (reviewer-protocol, using-qrspi, plan SKILL.anchors.json) + manifest (Slice 7, G4) — depends on: none
T35 — Anchor-refresh script (scripts/g4-section-anchor-refresh.sh) + structure-skill Section-Anchor Index section spec (Slice 7, G4) — depends on: T34
T36 — Slice 7 pins: cache-hit-rate, cache-control-capability-gate, section-anchor-index-shape, section-anchor-narrow-read, section-anchor-refresh (Slice 7, G4) — depends on: T13, T33, T34, T35
T37 — Cross-cutting test-no-summary-shim-dispatches pin (Slice 7, G4) — depends on: T13

T38 — implementer-protocol/SKILL.md three commit-hygiene invariants block (Slice 8, G12) — depends on: T15
T39 — Implement-skill worktree-setup exclude append + test-commit-hygiene-invariants pin (Slice 8, G12) — depends on: T13, T38

T40 — u14-lint slug-extraction logic update + confusable-prefix and genuine-integrate fixtures (Slice 9, G13) — depends on: none

T41 — replan/SKILL.md Boundary with Goals section + replan/owns-defers.md OWNS update (Slice 10, G15) — depends on: none
T42 — test-replan-boundary-with-goals pin + future-goals-mixed-shape fixture (Slice 10, G15+G14) — depends on: T13, T41

T43 — G4 Path B cache_control marker insertion at Anthropic SDK boundary, conditional on T33 spike outcome (Slice 7, G4) — depends on: T33, T36 — CONDITIONAL: NO-OP if T33 selects Path A

### Phase 1 Acceptance Criteria

Consolidated from `phasing.md` Slice 1-10 replan gate criteria. One checkbox per criterion:

Slice 1 — Cost-opt routing end-to-end:
- [ ] A configured non-Anthropic routing site dispatches through the universal dispatcher to the cheap provider and records enough telemetry to compare cost against the Anthropic baseline.
- [ ] The initial G5 routing matrix (dispatcher class -> routing decision) is documented in `skills/implement/SKILL.md`'s `### Per-Task Routing (task_type and model)` section as an observable table covering every dispatcher class enumerated in design.md G5, and the T07 `test-routing-matrix-application.bats` pin asserts the matrix's initial dispatch decisions and conditional-cell trusted-by-default routing.

Slice 2 — TDD test-writer split:
- [ ] A code task triggers a pre-implementation test-writer dispatch followed by an implementer dispatch after a RED-verification gate, observable in the per-task dispatch order.
- [ ] The RED-verification gate distinguishes assertion failures, infrastructure failures, vacuous-RED, and pass states, with the gate pausing on vacuous-RED and infrastructure failures.
- [ ] One agent body serves both the Implement-phase per-task mode and the Test-phase plan-level mode, with the dispatch context selecting the mode — observable in the artifacts produced by each mode against the same agent body.

Slice 3 — Hygiene + CI foundation:
- [ ] A push to a qrspi feature branch triggers CI with both a lint job and a bash-3.2 runtime job, both succeeding on the merge commit.
- [ ] Shellcheck runs against the project's shell surface and is clean.
- [ ] CI's bash-3.2 docker job is the load-bearing backstop. The grep ban-list catches known bash-4 constructs early; the docker job validates the ban-list remains current by execution test, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate.
- [ ] The evergreen-markdown scan runs under the unit BATS surface and is green.
- [ ] The implementer pre-DONE self-check reports added-line hits for internal-ID tokens and version tokens, the advisory commit still proceeds, and reviewer visibility covers unacknowledged hits.

Slice 4 — Parallelize hygiene + G14 consumers:
- [ ] The shared markdown test-helper exists and the migrated BATS consumers use it and remain green.
- [ ] The Parallelize scope reviewer dispatched against a worktree-aware parallelization artifact produces no scope-drift finding.
- [ ] The Parallelize quality reviewer dispatched against an artifact using canonical multi-stage vocabulary produces no style finding, and an artificially-introduced unconventional form does produce a style finding.
- [ ] The OWNS-list pin asserts the worktree-aware validation responsibility is present in Parallelize's OWNS surface.

Slice 5 — Visual-fidelity + human-gate references:
- [ ] A human gate for a UI-producing task surfaces its visual reference to the user in a renderable form, not merely as a path.
- [ ] A reference-gated UI task can be observed pausing dependents from dispatching until approval is recorded; the approval record persists so subsequent re-runs and audits can verify the gate fired and was cleared.
- [ ] The visual-fidelity reviewer's output for a UI task dispatched alongside sibling UI tasks contains either (a) at least one explicit reference to a sibling task's findings, or (b) an explicit statement that no relevant sibling visual context was found — observable in the reviewer's emitted finding files.
- [ ] The quick-tier finding-disposition guidance in `skills/reviewer-protocol/SKILL.md` codifies inline-patch for high and correctness-medium findings, acceptance for low findings, and prohibition of blanket quick-tier merges — observable via the `test-quick-tier-wording.bats` pin running green under the unit BATS surface.

Slice 6 — Plan post-approval split:
- [ ] An approved Plan with N>=3 tasks dispatches per-task spec authoring in parallel and produces N separate per-task spec artifacts, with the overview artifact recording phase-start state and approved status.
- [ ] An approved Plan with N<=2 tasks performs the split inline in main chat (carve-out exercised).

Slice 7 — Caching spike + verify:
- [ ] A written deliverable records the hit-rate behavior of representative high-token-cost dispatches against stable prefixes, observable as a release artifact.
- [ ] A recorded decision determines whether the platform's existing caching behavior is sufficient or whether follow-up implementation is required; downstream implementation work is either green-lit by the measurement or scoped against the gap the measurement surfaced.
- [ ] The summary-shim rejection invariant pin (`test-no-summary-shim-dispatches.bats`) runs green under the unit BATS surface, asserting no agent dispatch site substitutes an LLM-generated condensation of a stable artifact as the prompt's source-of-truth payload (per design.md G4's explicit rejection of summary shims).
- [ ] The three colocated section-anchor index files (`skills/reviewer-protocol/SKILL.anchors.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/plan/SKILL.anchors.json`) and the manifest at `scripts/g4-section-anchor-manifest.json` exist and are verified by the `test-section-anchor-index-shape.bats` and `test-section-anchor-narrow-read.bats` pins running green — Mechanism B ships unconditionally per design.md and its delivery is observed in the Phase 1 replan-gate criteria independent of the T33 spike outcome.
- [ ] (Conditional on T33 spike outcome) If the T33 spike report selects Path B (the dispatch path does not cache automatically), `cache_control: {type: "ephemeral"}` markers are observably present on the stable-prefix message block of the assembled JSON request payload at the flagged reviewer-dispatch sites for providers whose `supports_prompt_cache: true` AND `emit_cache_control_markers: true` config flags are both set, verified by `test-cache-hit-rate.bats` Path B fixtures running green. If the T33 spike report selects Path A, T43 is skipped and this criterion is satisfied vacuously (the implementer's terminal DONE report records `status: skipped` with the verbatim T33 spike-decision token captured as rationale).

Slice 8 — Commit-message scratch staging:
- [ ] Across an implementer commit cycle, the implementer scratch file used to compose commit messages does not appear in the committed tree, and the worktree-local exclude carries the corresponding entry.
- [ ] The three architectural invariants for commit hygiene hold and are observable in test output.

Slice 9 — u14-lint worktree:
- [ ] The u14-lint check passes for a worktree path whose prefix contains `integrate` as a non-skill directory segment while still failing on a genuine integrate-skill path — both fixtures exercised in the same run.

Slice 10 — Replan <-> Goals coordination:
- [ ] The `skills/replan/SKILL.md` `## Boundary with Goals` section codifies the promotion contract against the `tests/fixtures/future-goals-mixed-shape.md` fixture in a form whose decision branches (promote / skip-Idea / skip-partial-Formal) are each enumerable by the T42 BATS pin against the fixture entries — observable via the BATS pin (T42).
- [ ] The skill prose names the hand-off-report shape (promoted Formal goals named, skipped Ideas named with reason) — observable via the T42 BATS pin's documentation-shape assertions, not runtime invocation.
- [ ] **(human-verified Integrate-phase gate)** Runtime promotion behavior is gated at Integrate-phase Replan agent invocation against the fixture; T42's BATS pin covers skill-prose contract; runtime observation is the Integrate-phase acceptance gate — the v0.7 Integrate phase MUST include a Replan dry-run against `tests/fixtures/future-goals-mixed-shape.md` and capture the hand-off output for the gate (NOT deferred to the next-release real phase boundary). This bullet is NOT enforced by a BATS pin or CI step inside this plan; it is a human-verified Integrate-phase checklist item the operator runs and ticks during the v0.7 Integrate session.

## Task Specs

**Frontmatter field reference — `conditional:` and `conditional_precondition:`** (introduced in v0.7 by T43): a task spec MAY carry `conditional: true` in its frontmatter to mark the task as a NO-OP unless a documented precondition is met at dispatch time. When `conditional: true` is set, the task spec MUST also carry a one-line `conditional_precondition:` field naming the precondition in a single human-readable token of the form `<dependency_task> spike report decision == <token>` (e.g., `T33 spike report decision == Path B`). The Implement orchestrator reads these fields before dispatching the task: when the precondition is not met, the implementer dispatch is short-circuited and the implementer's terminal DONE report records `status: skipped` with the verbatim precondition-evaluation result captured as rationale. When `conditional: true` is absent (the default for all other tasks), the task is unconditionally dispatched. The Plan post-approval split sub-subagent (T31) preserves both fields verbatim when emitting per-task spec files.

---
task_id: 01
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G1, G5]
dependencies: []
loc_estimate: 180
sizing_exception: schema migration
---

### Task 01: Document config.md routing, providers, and validators schema in using-qrspi
- **Phase:** 1
- **Target files:**
  - `skills/using-qrspi/SKILL.md` (Modify) — author the `## Config File` subsections that define the per-run routing/providers/validators schema consumed by Slice 1 dispatch sites.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** schema migration
- **Description:** Extends `skills/using-qrspi/SKILL.md` with new `## Config File` subsections that document the four config blocks consumed by Slice 1 dispatch sites: `providers:` (entry per provider with `base_url`, `api_key_env`, `transport_type` of either `openai-chat-completions` or `codex-broker`, optional `supports_prompt_cache` flag defaulting to `false`, optional `emit_cache_control_markers` flag defaulting to `false` — independent of `supports_prompt_cache:` and required to be `true` for the dispatcher to actually emit `cache_control` fields (the dual-flag gate; see T03), optional `default_headers` map); `model_routing:` (role-name to provider-plus-model pair, each provider value referring to an entry in `providers:`); `trusted_path:` (flat list of agent file paths or role names that always win over `model_routing:`); and `validators:` (post-dispatch output gates including `citation_density_floor` defaulting to `0.05`). The same edit documents the one-time legacy-config warning that fires when `model_routing:` is absent on resume, per the runtime-backfill defaults contract from goals.md. The schema landing here is the authoritative source the dispatcher (T03), the per-task routing chain (T05), and the role-frontmatter resolution (T06) all consume.
- **Test expectations:**
  - The `## Config File` section in `skills/using-qrspi/SKILL.md` documents the `providers:` block with every required field, the two legal `transport_type:` values, the `supports_prompt_cache:` default (`false`), and the `emit_cache_control_markers:` default (`false`). The documentation states that `cache_control` fields are emitted by the dispatcher only when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set on the provider entry (the dual-flag gate); a `true`/`false` mismatch on either flag suppresses emission.
  - The `model_routing:` documentation enumerates the role-name to provider-plus-model mapping and states that the provider value must exist in `providers:`.
  - The `trusted_path:` documentation states that matching agent files or role names short-circuit ahead of `model_routing:`.
  - The `validators:` documentation declares `citation_density_floor:` with its `0.05` default and names the trusted-model re-run consequence.
  - The legacy-config warning subsection documents the one-time backfill behavior when a resumed run's `config.md` predates the `model_routing:` field, and states explicitly that "one-time" is implemented purely in-memory per session — no persistent marker is written to disk to track that the warning has already fired, so there is no write-failure surface that could leave the on-disk config in an inconsistent state. The warning fires once per resumed session and re-fires on each subsequent resume of a legacy `config.md`; the on-disk config is never silently mutated by the backfill, so a resumed session always sees the backfill defaults applied in-memory without changing the file on disk.
  - The combined precedence order (per-task `model:` override > hardcoded dispatch-site `model:` > `model_routing:` role lookup > agent bundled default) is stated in the same section, with `trusted_path:` documented separately as a short-circuit that wins outside the normal chain when an agent-file path or role name matches.
---
task_id: 02
task_type: code
model: sonnet
phase: 1
goal_ids: [G2]
dependencies: []
loc_estimate: 140
sizing_exception: reusable primitives
---

### Task 02: Extract shared prompt-utils library for vendor-agnostic dispatch
- **Phase:** 1
- **Target files:**
  - `scripts/lib/llm-prompt-utils.sh` (Create) — sourced shell library exposing prompt-composition helpers reused by every third-party-LLM dispatch site.
- **Dependencies:** none
- **LOC estimate:** ~140
- **Sizing exception:** reusable primitives
- **Description:** Creates `scripts/lib/llm-prompt-utils.sh` as a sourced bash library carrying the prompt-composition utilities previously inlined in `scripts/run-codex-review.sh`, refactored to be vendor-agnostic so both the new universal dispatcher (T03) and the retired codex shim (T04) source the same helpers. The library exposes the three prompt-composition helpers (frontmatter stripping, untrusted-data marker-collision guarding, dispatch-parameter emission) per the `scripts/lib/llm-prompt-utils.sh` interface contract documented in structure.md — function names, parameter shapes, and exit-code semantics are owned by structure.md and not duplicated here. The library is bash 3.2 portable (no `mapfile`, no `declare -A`, no `${var,,}`, no `coproc`, no `wait -n`), uses loud diagnostics on every failure path, and refuses to execute when invoked as a script rather than sourced (named diagnostic to stderr, exit 1).
- **Test expectations:**
  - `strip_frontmatter` on a file with a leading `---` frontmatter block emits only the body that follows the closing `---` marker.
  - `strip_frontmatter` on a file with no frontmatter emits the file body unchanged.
  - `guard_marker_injection` exits 0 on a file containing no untrusted-data sentinel markers and exits 1 with a named-marker stderr diagnostic when a collision is present.
  - `emit_dispatch_parameters` produces one `key=value` line per input pair in a stable order suitable for diffing across runs.
  - Sourcing the file under bash 3.2 succeeds and exports the three named functions.
  - Invoking the file as a script (rather than sourcing) prints a named diagnostic to stderr and exits 1.
---
task_id: 03
task_type: code
model: sonnet
phase: 1
goal_ids: [G2]
dependencies: [T01, T02]
loc_estimate: 195
---

### Task 03: Universal third-party-LLM dispatcher script
- **Phase:** 1
- **Target files:**
  - `scripts/run-third-party-llm.sh` (Create) — stdin-prompt dispatcher that resolves a configured provider, branches on transport type, blocks until the result is written, and emits numbered exit codes.
- **Dependencies:** T01, T02
- **LOC estimate:** ~195
- **Description:** Creates `scripts/run-third-party-llm.sh` as the single shell-level dispatcher every QRSPI dispatch site uses to invoke a third-party (or Codex) LLM endpoint. The script reads the prompt from stdin only (any positional argument or `--prompt-file` exits 1 with a validation diagnostic) and requires the canonical dispatcher flag set with the optional scope-hint and timeout parameters per the `scripts/run-third-party-llm.sh` CLI signature in structure.md. It reads `<artifact-dir>/config.md` to resolve the `providers:` entry named by `--provider` and branches on `transport_type:`: for `openai-chat-completions` it issues a blocking POST to `<base_url>/chat/completions` using the API key resolved from `api_key_env` and emits `cache_control` fields only when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set on the resolved provider entry (the dual-flag gate — if either flag is `false` or absent, NO `cache_control` field is included in the assembled request body; this dual-flag design preserves the T33 spike's ability to measure platform auto-caching uncontaminated, since `emit_cache_control_markers` defaults to `false` and is set to `true` only when T43 activates on Path B); for `codex-broker` transport, the dispatcher chains through the codex-companion lifecycle and writes the result to `--output-file` (the specific internal invocation sequence is an Implement-layer decision). The script sources `scripts/lib/llm-prompt-utils.sh` for prompt assembly; every invocation of `guard_marker_injection` checks the return code and a non-zero return aborts the dispatch with a prompt-injection diagnostic on stderr and propagates exit 1 — the protection is not silently skipped. The script exits with the shared codes from the structure.md interface: 0 success, 1 validation/argument/missing-key failure, 10 upstream timeout, 11 job-not-found, 13 hard-error from upstream, 14 malformed result body, 15 phantom-launch.
- **Test expectations:**
  - Invocation with any positional argument or `--prompt-file` exits 1 with a validation diagnostic on stderr.
  - Invocation missing any required flag (`--artifact-dir`, `--provider`, `--model`, `--output-file`) exits 1 and names the missing flag.
  - When `--provider` does not match any entry in `<artifact-dir>/config.md`, the script exits 1 with a named provider-resolution diagnostic.
  - When `api_key_env` names an environment variable that is unset at call time, the dispatcher exits 1 with a named key-resolution diagnostic before issuing any HTTP request.
  - When `api_key_env` names an environment variable that exists with an empty-string value, the dispatcher exits 1 with a named key-resolution diagnostic before issuing any HTTP request (fail-closed against silent empty-Authorization-header attempts).
  - When any component of the assembled prompt payload sources from a file whose body contains an untrusted-data sentinel token and `guard_marker_injection` therefore returns non-zero, the dispatcher exits 1 with a prompt-injection diagnostic on stderr and issues no outbound network call.
  - When `--artifact-dir` does not refer to an existing directory, the script exits 1 with a named path-validation diagnostic before reading `config.md`.
  - On every failure path (missing key, empty key, upstream timeout, upstream hard-error, malformed result body, prompt-injection abort, path-validation abort), the resolved secret value (the contents of the `api_key_env` environment variable AND any sensitive `default_headers` value such as an `Authorization` header) NEVER appears in stderr diagnostics, the `--output-file` body, the per-task telemetry JSON written by T05, or any other surface the dispatcher writes — diagnostics name the env-var name or provider key, not the secret value.
  - The dispatcher validates the resolved provider config before issuing any network call: for `openai-chat-completions` transport, a non-HTTPS `base_url` exits 1 with a named url-scheme diagnostic (unless an explicit documented local-test carve-out is active); a `base_url` resolving to a localhost/link-local/cloud-metadata address exits 1 with a named host-shape diagnostic; a `default_headers` entry whose name OR value contains a control character (CR, LF, NUL, or other ASCII control) exits 1 with a named header-validation diagnostic. None of these invalid configs causes any outbound HTTP call.
  - The host-shape local-test carve-out is activated ONLY by setting the named environment variable `QRSPI_ALLOW_LOCALHOST_BASE_URL=1`. The carve-out is OFF by default — a dispatcher invocation without the env var against a localhost provider exits 1 with the host-shape diagnostic. The carve-out narrows the rejection to the IPv4 loopback range `127.0.0.0/8` AND the IPv6 loopback address `::1` (equivalently `0:0:0:0:0:0:0:1`, addressed in URL form as `[::1]`) only; link-local (`169.254.0.0/16`, including the AWS/GCP cloud-metadata endpoint `169.254.169.254`), the carrier-grade NAT range (`100.64.0.0/10`), private RFC1918 ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), and IPv6 link-local (`fe80::/10`) and unique-local (`fc00::/7`) addresses remain rejected even when the carve-out is active. The carve-out env var MUST NOT be set in production CI; a T07 pin asserts the off-by-default behavior and the narrowed scope. No global `ALLOW_LOCALHOST` / `--allow-local` form is accepted; only the named env var activates the carve-out.
  - When the configured provider's `transport_type` is `openai-chat-completions`, the dispatcher issues the chat-completions call and on success writes the response body atomically to `--output-file` and exits 0.
  - When the configured provider's `transport_type` is `codex-broker`, the dispatcher chains the codex-companion launch+await sequence and on success writes the result to `--output-file` and exits 0.
  - The dispatcher emits `cache_control` fields in the assembled request body ONLY when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set on the resolved provider entry. The four-cell truth table is asserted: (a) `supports_prompt_cache: false`, `emit_cache_control_markers: false` → no `cache_control` field; (b) `supports_prompt_cache: true`, `emit_cache_control_markers: false` → no `cache_control` field (default state — preserves T33 spike measurement integrity); (c) `supports_prompt_cache: false`, `emit_cache_control_markers: true` → no `cache_control` field (capability gate still holds — providers that do not support prompt caching never receive markers regardless of the emission flag); (d) `supports_prompt_cache: true`, `emit_cache_control_markers: true` → `cache_control` field present on the stable-prefix message block.
  - Upstream timeout produces exit 10; job-not-found produces exit 11; upstream hard-error produces exit 13; malformed result body produces exit 14; phantom-launch produces exit 15.
  - The script runs under bash 3.2 without using `mapfile`, `declare -A`, `${var,,}`, `coproc`, or `wait -n`.
---
task_id: 04
task_type: code
model: sonnet
phase: 1
goal_ids: [G2]
dependencies: [T03]
loc_estimate: 90
---

### Task 04: Retire codex-shim entry behavior to a thin forwarder
- **Phase:** 1
- **Target files:**
  - `scripts/run-codex-review.sh` (Modify) — replace the inline user-facing entry behavior with a thin forwarder that delegates to `scripts/run-third-party-llm.sh` while preserving the existing caller CLI surface.
  - `scripts/codex-companion-bg.sh` (Modify) — update helper-script reference comments only; no behavior change to launch/await/JSONL lifecycle.
- **Dependencies:** T03
- **LOC estimate:** ~90
- **Description:** Rewrites `scripts/run-codex-review.sh` as a thin compatibility forwarder that preserves its existing caller-facing flag surface, then re-invokes `scripts/run-third-party-llm.sh --provider codex --model <id> --output-file <path>` (along with `--artifact-dir`) so every existing call site continues to work during the migration window per Decision 10's safe-default principle. Transport selection is config-driven through the `codex` entry in `config.md`'s `providers:` block (which carries `transport_type: codex-broker`); the shim does NOT pass a transport flag. Stdin is forwarded unmodified to the dispatcher's stdin so the prompt-source contract is preserved. The shim exits with the dispatcher's exit code unchanged so existing callers observe the same exit-code matrix. `scripts/codex-companion-bg.sh` is touched only to update header/inline comments that point at the new helper-script reference layout — no behavior change to its launch, await, or JSONL lifecycle.
- **Test expectations:**
  - Calling `scripts/run-codex-review.sh` with its existing flag set forwards stdin to `scripts/run-third-party-llm.sh` and exits with the dispatcher's exit code unchanged.
  - The forwarded invocation includes `--provider codex` and the model identifier originally passed to the shim, with no transport flag.
  - The forwarded invocation includes `--artifact-dir` with the artifact directory value resolved by the shim from its own caller context (so the dispatcher can read `config.md` from the correct artifact directory; without this flag the dispatcher would exit 1 per T03's required-flag contract).
  - The shim does not source or invoke `scripts/codex-companion-bg.sh` directly; the broker chaining happens inside the dispatcher.
  - Existing callers that pipe a prompt into `run-codex-review.sh` observe identical success-path behavior and explicit per-code exit-code pass-through: a timeout condition forwarded through the shim produces exit 10; a job-not-found condition produces exit 11; an upstream hard-error produces exit 13; a malformed result body produces exit 14; a phantom-launch produces exit 15 (each numeric code enumerated directly rather than cross-referenced by description).
  - `scripts/codex-companion-bg.sh`'s launch, await, and JSONL lifecycle behavior is unchanged (comment-only edits).
---
task_id: 05
task_type: code
model: opus
phase: 1
goal_ids: [G1, G5]
dependencies: [T01, T03]
loc_estimate: 170
sizing_exception: reusable primitives
---

### Task 05: Implement-skill per-task routing chain, citation-density validator dispatch, and G5 telemetry emission
- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — add the per-task `model` resolution chain inside `### Per-Task Routing (task_type and model)`; wrap research-specialist dispatches with the citation-density post-output validator and trusted-model re-run; emit per-task telemetry to `reviews/telemetry/round-NN/task-NN.json`.
  - `skills/research/SKILL.md` (Modify) — document the specialist citation-density post-validation hook and the trusted-model re-run path; cross-reference the `validators.citation_density_floor:` config key documented in T01.
- **Dependencies:** T01, T03
- **LOC estimate:** ~170
- **Sizing exception:** reusable primitives — the routing chain, the citation-density validator dispatch, and the G5 telemetry emission co-deploy in one Implement-skill section because the validator and telemetry sites are observed at the same per-dispatch boundary the routing chain authors and the citation-density validator+telemetry depend on the routing chain landing first; splitting them would either duplicate the per-dispatch boundary prose or leave the validator/telemetry without a resolved provider+model to observe.
- **Description:** Wires the Slice 1 routing chain and telemetry emission into the live Implement and Research skills. In `skills/implement/SKILL.md`, the `### Per-Task Routing (task_type and model)` section gains the four-layer `model` resolution chain consumed at every implementer/reviewer dispatch site: layer 1a is the per-task spec `model:` override, layer 1b is a hardcoded dispatch-site `model:` override (the inline `model:` argument the dispatch call composes), layer 2 is a `model_routing:` role-to-provider+model lookup keyed by the agent's `model_role:` frontmatter, and layer 3 is the agent's bundled default. The `trusted_path:` match (against agent file path or role name) is documented separately as a short-circuit that wins ahead of the entire four-layer chain when matched. The same skill wraps every `qrspi-research-specialist` dispatch with a post-output citation-density check against `validators.citation_density_floor:` (default `0.05`): below-floor output triggers exactly one re-run on the trusted model; above-floor proceeds. Per-task telemetry — routing decision (resolved role, provider, model, layer that won), fix-cycle count, review-finding category counts, citation-density rerun count — is emitted to `<ABS_ARTIFACT_DIR>/reviews/telemetry/round-NN/task-NN.json` as a single JSON object per task so the G5 living-config matrix can be tuned from real data. `skills/research/SKILL.md` documents the validator hook and trusted-model re-run path and references the `validators.citation_density_floor:` config key authored in T01.
- **Test expectations:**
  - The `### Per-Task Routing (task_type and model)` section in `skills/implement/SKILL.md` enumerates the four-layer resolution chain in precedence order (1a per-task `model:` override, 1b hardcoded dispatch-site `model:` override, 2 `model_routing:` role lookup, 3 agent bundled default) and documents `trusted_path:` separately as a short-circuit that wins ahead of the four-layer chain when matched.
  - Implement-skill dispatch prose specifies that the resolved provider+model pair is forwarded to `scripts/run-third-party-llm.sh` via `--provider` and `--model`.
  - The specialist dispatch prose specifies that below-floor citation-density triggers exactly one re-run on the trusted model and that above-floor output proceeds unchanged.
  - The specialist dispatch prose specifies that when the trusted-model re-run after a below-floor result ALSO produces below-floor citation density, the validator emits a loud diagnostic naming the below-floor density value, exits non-zero (propagating a failure signal to the Implement orchestrator), and does not silently forward the below-floor output to downstream consumers — the second-below-floor outcome is observably distinct from the success path via the non-zero exit code, NOT a zero-exit-with-empty-body. The Implement skill's downstream consumer treats the non-zero exit as a specialist-dispatch failure (the orchestrator can then decide to retry on a different topic angle, escalate to opus, or proceed with degraded output) rather than as an empty success body.
  - The telemetry-emission prose names the output path shape `<ABS_ARTIFACT_DIR>/reviews/telemetry/round-NN/task-NN.json` and lists the four required fields (routing decision, fix-cycle count, finding-category counts, citation rerun count).
  - The telemetry prose states that absence of the telemetry file at task-DONE time is a loud failure, not a silent skip.
  - `skills/research/SKILL.md` documents the citation-density post-validation hook and the trusted-model re-run path, and cross-references the `validators.citation_density_floor:` key by name.
  - The legacy-config one-time warning behavior from T01 is referenced (not redefined) so Implement consumers know how resumed runs without `model_routing:` are handled.
  - The `### Per-Task Routing (task_type and model)` section authors the initial G5 routing matrix as a documented table mapping each dispatcher class (`qrspi-research-collator`, `qrspi-implementer-lightweight`, `qrspi-research-specialist`, general-purpose/Explore, `qrspi-test-writer`) to its initial routing decision (cheap-model eligible vs. trusted/conditional) with the design.md rationale carried verbatim — the matrix is the observable G5 deliverable consumed by the T07 `test-routing-matrix-application.bats` pin and by Slice 1 acceptance.
  - The Implement-skill per-task reviewer dispatch section in `skills/implement/SKILL.md` documents the DONE-report companion-parameter wiring required by the T15 implementer-protocol hygiene contract: each per-task reviewer dispatch payload carries the implementer's DONE-report body as a named companion parameter AND lists the DONE-report file path in the dispatch payload so reviewers can re-Read it during pre-flight. This closes the gap between the prose contract authored in `skills/implementer-protocol/SKILL.md` (T15) and the actual dispatch-site wiring in `skills/implement/SKILL.md`, ensuring unacknowledged hygiene hits structurally reach the reviewer rather than only being declared in protocol prose.
---
task_id: 06
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G1, G5]
dependencies: [T01]
loc_estimate: 15
---

### Task 06: Declare model_role frontmatter on specialist, collator, and lightweight-implementer agents
- **Phase:** 1
- **Target files:**
  - `agents/qrspi-research-specialist.md` (Modify) — add `model_role: research-specialist` frontmatter alongside the existing `model:` value.
  - `agents/qrspi-research-collator.md` (Modify) — add `model_role: research-collator` frontmatter alongside the existing `model:` value.
  - `agents/qrspi-implementer-lightweight.md` (Modify) — add `model_role: lightweight-implementer` frontmatter alongside the existing `model:` value.
- **Dependencies:** T01
- **LOC estimate:** ~15
- **Description:** Adds a single `model_role:` frontmatter field to each of the three Slice 1 agent files so the layer-2 resolution step from T05's routing chain has an authoritative role label to look up against the `model_routing:` block authored under T01's schema. The existing `model:` frontmatter value is preserved as the layer-3 bundled default; the new `model_role:` field is purely additive and carries no runtime behavior of its own — it only exists for the dispatcher's role-to-provider+model resolution. The three role labels (`research-specialist`, `research-collator`, `lightweight-implementer`) match the candidate dispatcher-tolerance leaves identified in goals.md G5 so the matrix authored by Implement can be tuned against the same role vocabulary. No body prose changes; no other agent files touched in this task.
- **Test expectations:**
  - `agents/qrspi-research-specialist.md` carries `model_role: research-specialist` in its YAML frontmatter alongside the existing `model:` value, with both fields valid YAML.
  - `agents/qrspi-research-collator.md` carries `model_role: research-collator` in its YAML frontmatter alongside the existing `model:` value.
  - `agents/qrspi-implementer-lightweight.md` carries `model_role: lightweight-implementer` in its YAML frontmatter alongside the existing `model:` value.
  - The existing `model:` value on each of the three agents is unchanged (preserved as the layer-3 default).
  - The three role-label strings exactly match the role names consumed by the T01 `model_routing:` schema (no typo, no whitespace drift).
  - No agent body prose outside the frontmatter is modified in this task.
---
task_id: 07
task_type: code
model: sonnet
phase: 1
goal_ids: [G1, G2, G5]
dependencies: [T03, T05, T06]
loc_estimate: 220
sizing_exception: reusable primitives
---

### Task 07: Slice 1 unit pins for dispatcher, config routing, validator, matrix application, and telemetry
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-run-third-party-llm.bats` (Create) — pins the dispatcher contract (stdin-only, exit-code matrix, artifact-dir-based config resolution, transport-type branching, key resolution, capability-gated cache).
  - `tests/unit/test-config-model-routing.bats` (Create) — pins the precedence chain, trusted-path short-circuit, legacy-config one-time warning, provider-resolution fail-loud, and role-resolution chain.
  - `tests/unit/test-citation-density-validator.bats` (Create) — pins below-floor exactly-one trusted re-run, above-floor proceeds, and the `0.05` floor default.
  - `tests/unit/test-routing-matrix-application.bats` (Create) — pins initial-matrix dispatch decisions per dispatcher class and the conditional-cell trusted-by-default routing.
  - `tests/unit/test-g5-telemetry-emission.bats` (Create) — pins the per-task telemetry record presence under `reviews/telemetry/`, required fields, and loud-failure on absence.
- **Dependencies:** T03, T05, T06
- **LOC estimate:** ~220
- **Sizing exception:** reusable primitives — the five pins co-ship as the Slice 1 contract-lock and cannot land separately without leaving the routing chain (dispatcher, config precedence, validator, matrix, telemetry) unobserved; they form one observable behavior (the Slice 1 contract surface) realized across five BATS files.
- **Description:** Authors the five Slice 1 BATS unit pins that lock the contracts shipped by T03, T05, and T06 so Slice 1 acceptance criteria are independently observable. `test-run-third-party-llm.bats` exercises the dispatcher's stdin-only prompt contract, the full exit-code matrix (0/1/10/11/13/14/15), `--artifact-dir`-based config resolution (provider entries read from `<artifact-dir>/config.md`), branching on both `transport_type:` values, API-key resolution from the configured environment variable, and the capability-gated `cache_control` emission keyed on the dual-flag combination (`supports_prompt_cache:` AND `emit_cache_control_markers:`) covering all four cells of the truth table. `test-config-model-routing.bats` exercises the precedence order (task-override > hardcoded trusted-path > model_routing > agent default), trusted-path short-circuit against both agent-file paths and role names, the one-time legacy-config warning on resume when `model_routing:` is absent, fail-loud provider-resolution when the named provider is missing, and the role-resolution chain that consumes the `model_role:` frontmatter declared in T06. `test-citation-density-validator.bats` exercises the below-floor case (exactly one trusted re-run), the above-floor case (no re-run, output proceeds), the `0.05` floor default when `validators.citation_density_floor:` is absent, and the second-below-floor case (trusted-model re-run also below-floor: exits non-zero with a loud diagnostic, no forward). `test-routing-matrix-application.bats` exercises the initial matrix decisions per dispatcher class and the conditional-cell label routing to trusted by default. `test-g5-telemetry-emission.bats` exercises that a per-task telemetry record exists at `reviews/telemetry/round-NN/task-NN.json` after a task completes, that it contains the four required fields (routing decision, fix-cycle count, finding-category counts, citation rerun count), and that absence triggers loud failure. All five files run under the unit BATS surface and bash 3.2.
- **Test expectations:**
  - `test-run-third-party-llm.bats` covers stdin-only enforcement, every numbered exit code (0, 1, 10, 11, 13, 14, 15), config resolution from `<artifact-dir>/config.md`, both transport-type branches, environment-variable key resolution including explicit unset-variable AND empty-string-value cases (each exits 1 with a key-resolution diagnostic and issues no outbound network call), the prompt-injection abort path (a payload-source file containing an untrusted-data sentinel token causes `guard_marker_injection` non-zero to propagate to the dispatcher's exit 1 with no outbound network call), and the dual-flag `cache_control` emission gate: the pin exercises all four cells of the `supports_prompt_cache:` × `emit_cache_control_markers:` truth table (false/false, true/false, false/true, true/true) and asserts that `cache_control` fields appear in the assembled request body in the (true, true) cell ONLY — every other cell produces a request body with no `cache_control` fields. The (true, false) cell is the default state at T03 ship time and is critical to T33 spike measurement integrity.
  - `test-run-third-party-llm.bats` covers the SSRF host-shape carve-out off-by-default behavior: a dispatcher invocation without `QRSPI_ALLOW_LOCALHOST_BASE_URL=1` against a `base_url` resolving to `127.0.0.1` exits 1 with the host-shape diagnostic and issues no outbound call; the same exit-1 result holds for `http://[::1]/...` (IPv6 loopback) without the env var. With `QRSPI_ALLOW_LOCALHOST_BASE_URL=1` set, a `127.0.0.1` `base_url` proceeds AND a `[::1]` `base_url` proceeds (the carve-out covers both loopback addresses), BUT a `169.254.169.254` (cloud-metadata) `base_url` still exits 1, AND `10.0.0.1` (RFC1918), `192.168.0.1` (RFC1918), and `100.64.0.1` (CGNAT) all still exit 1 — the carve-out narrows to the `127.0.0.0/8` loopback range AND the `::1` IPv6 loopback only. The pin also covers the prompt-injection end-to-end path through the real sourced library (not a stub): a fixture file containing a real `<<<UNTRUSTED-ARTIFACT-START id=x>>>` sentinel token assembled into the payload causes the dispatcher (with `scripts/lib/llm-prompt-utils.sh` sourced as in production) to exit 1 with the prompt-injection diagnostic and no outbound network call, demonstrating the library-through-dispatcher return-code contract end-to-end so the pin breaks if the library's return-code contract ever changes.
  - `test-config-model-routing.bats` covers precedence ordering across all four layers, trusted-path short-circuit on both agent-file-path and role-name forms, the legacy-config one-time warning on resume, fail-loud provider-resolution on a missing provider name, and role-resolution that consumes the `model_role:` frontmatter from T06. The layer-1a vs. layer-1b tie-break is verified in a SINGLE SHARED fixture exercising both resolution outcomes — a task whose `tasks/task-NN.md` carries `model: opus` dispatching through a call site with a hardcoded `model:` "sonnet" override resolves to opus (1a wins), AND a task with no `model:` field on its task spec dispatching through the same call site resolves to sonnet (1b active in 1a's absence) — so the tie-break cannot silently pass with separate fixtures. The model-role resolution fallback is verified in a single fixture showing an agent with `model_role: cheap_reviewer` and `model: sonnet` resolving to the configured `deepseek-v3` when `model_routing.cheap_reviewer` is present, AND resolving to `sonnet` via the concrete-`model:` fallback when the role entry is removed.
  - `test-citation-density-validator.bats` covers the below-floor single-re-run path, the above-floor pass-through path, the `0.05` default when the config key is absent, AND the second-below-floor outcome where the trusted-model re-run also produces below-floor density (the validator emits a loud diagnostic naming the below-floor density value, exits non-zero so the Implement orchestrator observes a specialist-dispatch failure signal, and does not silently forward the output — the pin asserts the non-zero exit so a regression to zero-exit-with-empty-body is caught).
  - `test-routing-matrix-application.bats` covers the initial dispatch decision per documented dispatcher class and the trusted-by-default behavior of conditional-cell labels.
  - `test-g5-telemetry-emission.bats` covers presence of the telemetry file at the expected path shape, presence of the four required fields in the JSON body, and loud failure when the file is absent at task-DONE time.
  - All five BATS files run cleanly under bash 3.2 and do not use `mapfile`, `declare -A`, `${var,,}`, `coproc`, or `wait -n`.
---
task_id: 08
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G6]
dependencies: [T01]
loc_estimate: 140
---

### Task 08: Dual-mode qrspi-test-writer agent body
- **Phase:** 1
- **Target files:**
  - `agents/qrspi-test-writer.md` (Modify) — author the dual-mode contract keyed on `task_definition` presence and add the `model_role: test-writer` frontmatter alongside the existing concrete `model:` value.
- **Dependencies:** T01
- **LOC estimate:** ~140
- **Description:** Extends `agents/qrspi-test-writer.md` so a single agent body serves both the Implement-phase per-task mode (signal: `task_definition` present in the dispatch payload) and the existing Test-phase plan-level mode (signal: `task_definition` absent). The edit adds the H2 sections `## Purpose`, `## Pre-Flight`, `## Mode: implement-phase (per-task)`, `## Mode: test-phase (plan-level)`, `## Output Contract`, and `## Dispatch Signal Resolution`, with the resolution section documenting that mode selection branches on `task_definition` presence in the dispatch payload (mirroring the per-task reviewer dual-mode pattern). The Implement-phase mode consumes `task_definition`, `companion_goals`, `companion_codebase_context`, and `output_dir` and writes per-task failing tests against the un-implemented task spec without running the tests. The Test-phase mode preserves the existing parameter set (`companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir`) and behavior unchanged. The frontmatter adds `model_role: test-writer` alongside the existing concrete `model:` value so the G1 layer-2 role-resolution chain can route the test-writer half independently per the config schema landed in T01.
- **Test expectations:**
  - The agent file's frontmatter carries both `model_role: test-writer` and a concrete `model:` value (activation-time fallback preserved).
  - The `## Dispatch Signal Resolution` section names `task_definition` presence as the load-bearing mode-selection signal.
  - The `## Mode: implement-phase (per-task)` section enumerates the Implement-phase parameter set and states the agent does not run the tests it writes.
  - The `## Mode: test-phase (plan-level)` section preserves the existing Test-phase parameter set and behavior verbatim.
  - All six required H2 sections (`## Purpose`, `## Pre-Flight`, `## Mode: implement-phase (per-task)`, `## Mode: test-phase (plan-level)`, `## Output Contract`, `## Dispatch Signal Resolution`) are present.
  - The `## Dispatch Signal Resolution` section states that `task_definition` validity requires both presence AND a non-empty (non-whitespace) value: a present-but-empty (empty string, null, or whitespace-only) `task_definition` is treated as invalid and the agent (or the dispatch site) exits 1 with a named "empty-task-definition" diagnostic before any test authoring begins. Present-and-non-empty selects Implement-phase mode; absent selects Test-phase mode; present-and-empty fails loudly. T13's `test-test-writer-dual-mode.bats` exercises the empty-string `task_definition` fixture and asserts the loud-failure path.
---
task_id: 09
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G6]
dependencies: []
loc_estimate: 100
---

### Task 09: RED-verification adapter contract documentation
- **Phase:** 1
- **Target files:**
  - `skills/implement/red-verification-adapters.md` (Create) — author the per-framework adapter contract that the four adapter scripts in T10 and the orchestrator gate in T11 both consume.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Creates `skills/implement/red-verification-adapters.md` documenting the per-framework adapter contract that the Implement-skill RED-verification gate consumes after dispatching `qrspi-test-writer` in Implement-phase mode. The document declares the adapter call surface (each adapter accepts `--runner-exit <int>`, `--stdout-file <path>`, `--stderr-file <path>`), the classification output contract (each adapter emits exactly one of `pass`, `assertion-failure`, or `infrastructure-failure` on stdout), the adapter exit-code contract (`0` when a classification token is emitted, `1` with a loud diagnostic on stderr when the runner output is unrecognized), the initial framework set (BATS, Vitest, Jest, pytest), and the orchestrator's pause-behavior consequence for each classification (the orchestrator dispatches the implementer on `pass` or `assertion-failure` against the targeted change; the orchestrator pauses with a load-bearing diagnostic on `infrastructure-failure` or on vacuous-RED, where vacuous-RED is the suite-level condition of zero assertion failures on the targeted behavior even when individual adapters return `pass`). The contract document is the single source of truth that the four adapter scripts (T10) implement and the Implement-skill gate (T11) consumes.
- **Test expectations:**
  - The adapter call surface section names the three required flags (`--runner-exit`, `--stdout-file`, `--stderr-file`).
  - The classification output contract enumerates exactly the three legal stdout tokens (`pass`, `assertion-failure`, `infrastructure-failure`).
  - The adapter exit-code contract states `0` on classification and `1` with stderr diagnostic on unrecognized output.
  - The initial framework set lists BATS, Vitest, Jest, and pytest by name.
  - The orchestrator pause-behavior section documents that `infrastructure-failure` and vacuous-RED both trigger a pause, while `pass` and `assertion-failure` (with at least one task-relevant assertion failing) proceed to implementer dispatch.
---
task_id: 10
task_type: code
model: opus
phase: 1
goal_ids: [G6]
dependencies: [T09]
loc_estimate: 200
sizing_exception: reusable primitives
---

### Task 10: Four RED-verification adapter scripts (bats, vitest, jest, pytest)
- **Phase:** 1
- **Target files:**
  - `scripts/red-verify/bats-adapter.sh` (Create) — classifies BATS runner output per the T09 contract.
  - `scripts/red-verify/vitest-adapter.sh` (Create) — classifies Vitest runner output per the T09 contract.
  - `scripts/red-verify/jest-adapter.sh` (Create) — classifies Jest runner output per the T09 contract.
  - `scripts/red-verify/pytest-adapter.sh` (Create) — classifies pytest runner output per the T09 contract.
- **Dependencies:** T09
- **LOC estimate:** ~200
- **Sizing exception:** reusable primitives
- **Description:** Creates the four per-framework adapter scripts that the Implement-skill RED-verification gate dispatches after `qrspi-test-writer` writes pre-implementation tests. Each script consumes the runner's exit code plus its captured stdout/stderr files via the call surface defined in T09, distinguishes assertion failures from infrastructure failures (syntax errors, import/load errors, fixture/setup errors, missing-symbol errors) using framework-specific output signals — Implement selects the specific markers per framework — and emits exactly one of `pass`, `assertion-failure`, or `infrastructure-failure` on stdout. Each adapter exits `0` on successful classification or `1` with a loud diagnostic on stderr when the runner output is unrecognized, matching the T09 exit-code contract. All four adapters are bash-3.2-compatible per Slice 3's CI bash32 runtime gate and avoid bash-4-only constructs (no `mapfile`, no `${var,,}`, no associative arrays). Source layout under `scripts/red-verify/` is the colocated directory the orchestrator (T11) selects from by framework name.
- **Test expectations:**
  - Each of the four adapters accepts the `--runner-exit`, `--stdout-file`, and `--stderr-file` flags and rejects any other invocation shape.
  - Given a BATS runner output where individual tests fail due to assertions (not setup or syntax errors), `bats-adapter.sh` emits `assertion-failure`; given output where all tests passed, the adapter emits `pass`; given output indicating a parse or setup error before tests ran, the adapter emits `infrastructure-failure`.
  - Given a Vitest runner output indicating a module-resolution or syntax error (any failure that prevents test code from loading), `vitest-adapter.sh` emits `infrastructure-failure`; given individual test assertion failures, the adapter emits `assertion-failure`; given a clean run, the adapter emits `pass`.
  - Given a Jest runner output indicating a module-resolution or syntax error, `jest-adapter.sh` emits `infrastructure-failure`; otherwise the pass-vs-assertion-failure classification follows the same rule as above.
  - Given a pytest runner output indicating a collection or import error (a failure to load the test module before any test ran), `pytest-adapter.sh` emits `infrastructure-failure`; given individual test assertion failures, the adapter emits `assertion-failure`; given a clean run, the adapter emits `pass`.
  - Per-adapter unrecognized-output specificity: each adapter receives at least one named fixture whose output matches none of its classification rules and asserts the adapter exits `1` with a diagnostic written to stderr (e.g., for BATS: output with no `ok`/`not ok` lines and no parse-error markers; for Vitest: ANSI-escape-only output with no classification markers; for Jest: non-zero runner exit with no `FAIL`/`PASS` lines in stdout; for pytest: output beginning with `INTERNALERROR` with an exit code outside the usual classification surface). No silent default classification is emitted.
  - All four adapters run under bash 3.2 without parse errors or runtime failures.
---
task_id: 11
task_type: code
model: opus
phase: 1
goal_ids: [G6]
dependencies: [T08, T10]
loc_estimate: 180
sizing_exception: reusable primitives
---

### Task 11: Implement-skill pre-implementer dispatch + RED-verification gate + qrspi-implementer split-mode awareness
- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — insert the pre-implementer `qrspi-test-writer` dispatch and the RED-verification gate inside `### Dispatching the Implementer` for `task_type: code` and absent-`task_type:` tasks, preserving the `task_type: lightweight` bypass.
  - `agents/qrspi-implementer.md` (Modify) — add split-mode awareness so the implementer treats prewritten failing tests in `output_dir` as the RED input when a `prewritten_red_tests:` companion (or equivalent dispatch signal declared in `skills/implement/SKILL.md`) is present, skipping the implementer's own RED-authoring step while leaving the GREEN/refactor cycle unchanged.
- **Dependencies:** T08, T10
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives — the Implement-side RED-verification gate and the implementer agent's split-mode awareness cannot test independently: the agent must understand the gate's `prewritten_red_tests:` signal at the moment the gate first dispatches it, so a merged-but-incomplete intermediate state (gate dispatches the test-writer but the implementer ignores its output and re-authors RED) is observable and broken. The two edits co-deploy so the dispatch signal exists at the same revision the implementer learns to honor it.
- **Description:** Wires the TDD split into the Implement skill end-to-end. The `skills/implement/SKILL.md` edit adds a pre-implementer dispatch step inside `### Dispatching the Implementer` that, for TDD tasks (`task_type: code` or absent), dispatches `qrspi-test-writer` in Implement-phase mode (with `task_definition` present per T08) to write per-task failing tests to `output_dir`. After the test-writer returns, the orchestrator runs the freshly-written tests once, captures stdout/stderr, selects the appropriate adapter from `scripts/red-verify/` by framework (T10), and parses the adapter's classification token. The orchestrator dispatches `qrspi-implementer` when the adapter classification surfaces at least one targeted `assertion-failure` (the proceed condition is keyed on a targeted assertion failing, including mixed suites where some unchanged behaviors pass and at least one targeted behavior fails); it pauses with a load-bearing diagnostic on `infrastructure-failure` and on vacuous-RED (the suite-level condition where the adapter returns `pass` with zero assertion failures on the targeted behavior — a `pass` classification with no targeted failures is treated as vacuous-RED and must pause, never proceed). The dispatch declares the `prewritten_red_tests:` companion (or equivalent signal documented in the same SKILL.md edit) the implementer reads. The lightweight bypass is preserved verbatim — `task_type: lightweight` skips both the test-writer dispatch and the gate. The `agents/qrspi-implementer.md` edit adds split-mode awareness: when the dispatch carries the `prewritten_red_tests:` signal, the implementer reads the existing failing tests as its RED input rather than authoring its own RED tests, then proceeds with its existing GREEN-and-refactor cycle. The agent-body change is scoped to the RED-authoring control flow; the rest of the implementer's TDD cycle is unchanged.
- **Test expectations:**
  - The `### Dispatching the Implementer` section in `skills/implement/SKILL.md` documents the pre-implementer `qrspi-test-writer` dispatch for `task_type: code` and absent-`task_type:` tasks.
  - The RED-verification gate documentation enumerates the four adapter classifications (`pass`, `assertion-failure`, `infrastructure-failure`, vacuous-RED) and the orchestrator's proceed/pause decision per classification: proceed only when at least one targeted `assertion-failure` is present; pause on `infrastructure-failure`; pause on vacuous-RED (adapter returns `pass` with zero targeted assertion failures).
  - The `task_type: lightweight` bypass is preserved and explicitly documented (no test-writer dispatch, no RED gate).
  - The `prewritten_red_tests:` companion (or equivalent named signal) is declared in `skills/implement/SKILL.md` as the dispatch-time signal that flips implementer behavior.
  - `agents/qrspi-implementer.md` documents the split-mode behavior keyed on the named dispatch signal and states that the implementer skips RED-authoring when the signal is present.
  - The implementer's GREEN/refactor cycle prose is unchanged outside the RED-authoring control-flow edit.
  - When the selected adapter exits `1` (unrecognized runner output rather than emitting a classification token), the RED-verification gate pauses with a load-bearing diagnostic distinguishing adapter-classification-failure from `infrastructure-failure`, and does NOT dispatch the implementer — the gate never silently treats adapter exit 1 as a third infrastructure-failure synonym or as a proceed signal.
  - When the `qrspi-test-writer` dispatch itself exits non-zero (e.g., dispatch failure, agent cannot parse `task_definition`, output directory unwritable, or zero/partial test files written), the RED-verification gate treats this as infrastructure-failure-equivalent and pauses with a load-bearing "test-writer dispatch failed" diagnostic (distinct from both adapter-classification-failure and the post-test-run `infrastructure-failure` classification). The gate does NOT attempt to run tests, does NOT invoke the adapter against any partial output the failing test-writer may have written, and does NOT proceed to the implementer — closing the silent-failure path where a test-writer crash is reinterpreted as vacuous-RED or as a valid RED assertion-failure.
  - At least one behavioral test expectation observes the gate's runtime behavior end-to-end against a `task_type: code` task (the dispatch log shows test-writer entry before implementer entry on the proceed path; on `infrastructure-failure` the gate halts with a named diagnostic and no implementer dispatch occurs) — not only the documentation-shape assertions covered above.
  - The edited `skills/implement/SKILL.md` body documents the `conditional:` / `conditional_precondition:` orchestrator-dispatch contract introduced by T43: how the orchestrator reads these fields before dispatching any task (the read happens at the top of the dispatch chain, before the test-writer or implementer is invoked), what happens when the precondition is not met (dispatch is short-circuited; the implementer's terminal DONE report records `status: skipped` with the verbatim precondition-evaluation result captured as rationale), and that a task without `conditional: true` is unconditionally dispatched. This documentation closes the gap between the plan-level conditional-field declaration (see `## Task Specs` preamble) and the runtime-facing skill body.
---
task_id: 12
task_type: lightweight
model: opus
phase: 1
goal_ids: [G6]
dependencies: [T11]
loc_estimate: 80
---

### Task 12: Plan-skill per-task dispatch-order note + task_type defaulting
- **Phase:** 1
- **Target files:**
  - `skills/plan/SKILL.md` (Modify) — extend the per-task spec template so TDD tasks emit a dispatch-ordering note (test-writer first, implementer second) and add the `task_type:` defaulting note that absent `task_type:` defaults to the TDD path (test-writer plus implementer), `task_type: code` follows the same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch.
- **Dependencies:** T11
- **LOC estimate:** ~80
- **Description:** Extends `skills/plan/SKILL.md`'s per-task spec template so generated `tasks/task-NN.md` files for TDD tasks carry an explicit dispatch-ordering note that the test-writer dispatches before the implementer, matching the orchestration landed by T11. The same edit documents the `task_type:` defaulting rule: absent `task_type:` defaults to the TDD path (test-writer dispatch followed by implementer dispatch through the RED-verification gate), `task_type: code` follows that same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch with no test-writer and no RED gate. The defaulting note lives in the per-task spec template section so every future task spec the Plan skill emits inherits the convention without per-task re-authoring. The edit is scoped to the per-task spec template and the `task_type:` field documentation; it does not modify the post-approval split orchestration owned by Slice 6.
- **Test expectations:**
  - The per-task spec template in `skills/plan/SKILL.md` emits a dispatch-ordering note (test-writer first, implementer second) for TDD tasks.
  - The `task_type:` documentation states that absent `task_type:` defaults to the TDD path.
  - The `task_type:` documentation states that `task_type: code` follows the TDD path.
  - The `task_type:` documentation states that `task_type: lightweight` produces the lightweight-only dispatch (no test-writer, no RED gate).
  - The edit is confined to the per-task spec template and `task_type:` field documentation (no changes to post-approval split orchestration).
---
task_id: 13
task_type: code
model: opus
phase: 1
goal_ids: [G6, G14]
dependencies: [T08, T11, T12]
loc_estimate: 220
sizing_exception: reusable primitives
---

### Task 13: Shared BATS helper tests/helpers/skill-markdown.bash + helper-self pins + Slice 2 pins
- **Phase:** 1
- **Target files:**
  - `tests/helpers/skill-markdown.bash` (Create) — author the shared BATS helper library (H2/H3 section extractor, extract-and-grep wrapper, BATS-shaped assertion variant, `REPO_ROOT` resolution guard) sourced as `load 'helpers/skill-markdown'`; fail loudly on empty extract or missing anchor.
  - `tests/unit/test-helpers-skill-markdown.bats` (Create) — first consumer; helper-self pins covering happy-path, empty-extract, missing-anchor, end-of-file boundary, and stderr diagnostic content.
  - `tests/unit/test-test-writer-dual-mode.bats` (Create) — pin asserting `agents/qrspi-test-writer.md` exposes both Implement-phase and Test-phase modes against the same agent body, using the shared helper.
  - `tests/unit/test-red-verification-gate.bats` (Create) — pin covering the RED-verification gate's pass-case (all-fail and mixed), pause-case (vacuous-RED), and pause-case (infrastructure-failure), exercising each adapter's classification.
  - `tests/unit/test-tdd-dispatch-order.bats` (Create) — pin asserting `task_type: code` produces test-writer-then-implementer order, absent `task_type:` defaults to the TDD path, and `task_type: lightweight` produces lightweight-only dispatch.
- **Dependencies:** T08, T11, T12
- **LOC estimate:** ~220
- **Sizing exception:** reusable primitives
- **Description:** Authors the shared BATS helper library that 9+ downstream test files across Slices 2, 4, 5, and 10 consume, plus the first wave of consumer pins (helper-self plus Slice 2 behavioral pins). The helper at `tests/helpers/skill-markdown.bash` exposes four behavioral helpers — section extraction by H2/H3 heading anchor with loud-failure semantics on missing-anchor or empty-extract, an extract-plus-grep chained variant with the same loud-failure semantics, a BATS-shaped assertion wrapper that emits a `file:section:regex` failure diagnostic on miss, and a `REPO_ROOT` resolution guard — per the `tests/helpers/skill-markdown.bash` interface contract documented in structure.md; function names, parameter shapes, and exit-code semantics are owned by structure.md and not duplicated here. The helper is bash-3.2-compatible per Slice 3's CI bash32 runtime gate (no `mapfile`, no `${var,,}`, no associative arrays). The helper-self test file is the first consumer, validating the helper alongside the Slice 2 use that motivates it. The three Slice 2 behavioral pins exercise the dual-mode agent body (T08), the RED-verification gate (T11), and the dispatch order documented by Plan (T12), with the test-writer dual-mode and dispatch-order pins consuming the new helper to extract and assert against named sections of `agents/qrspi-test-writer.md`, `skills/implement/SKILL.md`, and `skills/plan/SKILL.md`.
- **Test expectations:**
  - The helper-self file `tests/unit/test-helpers-skill-markdown.bats` exercises happy-path extraction of an H2 section between two same-level headings (boundary lines excluded from the extract).
  - The helper returns non-zero with a named stderr diagnostic when the requested heading anchor is not present in the file.
  - The helper returns non-zero with a named stderr diagnostic when the extract between two adjacent same-level headings is empty (silent-pass guard).
  - The helper extracts correctly when the requested section ends at end-of-file with no following same-level heading.
  - The `assert_section_contains` wrapper emits a BATS-style `file:section:regex` failure diagnostic on miss.
  - `require_repo_root` resolves `REPO_ROOT` from `BATS_TEST_DIRNAME` plus `git rev-parse --show-toplevel` and fails loudly when neither resolution succeeds.
  - `tests/unit/test-test-writer-dual-mode.bats` asserts the same `agents/qrspi-test-writer.md` body exposes both `## Mode: implement-phase (per-task)` and `## Mode: test-phase (plan-level)` H2 sections and keys mode selection on `task_definition` presence, using the shared helper to scope its grep.
  - `tests/unit/test-red-verification-gate.bats` exercises pass-case (all-fail), pass-case (mixed with at least one task-relevant assertion failure), pause-case (vacuous-RED), pause-case (infrastructure-failure), AND pause-case (adapter-exit-1 / unrecognized runner output) classifications against each of the four framework adapters from T10. The adapter-exit-1 case dispatches each adapter against a fixture whose output matches none of the adapter's classification rules so the adapter returns exit 1; the pin asserts the RED-verification gate emits a distinguishing diagnostic distinct from the `infrastructure-failure` diagnostic AND does NOT dispatch the implementer — this is the fourth pause scenario alongside vacuous-RED and infrastructure-failure, observing the behavior T11 declares at the orchestrator level so the adapter-classification-failure path is BATS-falsifiable rather than only documented.
  - `tests/unit/test-tdd-dispatch-order.bats` asserts `task_type: code` produces test-writer-then-implementer dispatch order, absent `task_type:` defaults to the same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch with no test-writer and no RED gate.
  - The helper and all four BATS test files run under bash 3.2 without parse or runtime errors.
  - The helper documents (in its file header comment AND in the helper-self test file) the required calling convention: consumer tests MUST call `extract_section`, `extract_and_grep`, and `require_repo_root` WITHOUT wrapping in BATS `run` so that a non-zero return directly fails the `@test` block; `assert_section_contains` is the only function designed for `run` semantics. The helper-self test exercises one fixture demonstrating the direct-call failure mode (a missing-anchor `extract_section` call inside a `@test` block, without `run`, observably fails the test block rather than silently passing).
---
task_id: 14
task_type: code
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: []
loc_estimate: 120
sizing_exception: CI scaffolding
---

### Task 14: Author qrspi-plus GitHub Actions CI workflow with lint and bash32 jobs
- **Phase:** 1
- **Target files:**
  - `.github/workflows/ci.yml` (Create) — two-job GitHub Actions workflow that provides the four CI verification surfaces (shellcheck lint, Option B ban-list grep, unit BATS under bash 3.2, acceptance BATS under bash 3.2) for the qrspi-plus repo.
- **Dependencies:** none
- **LOC estimate:** ~120
- **Sizing exception:** CI scaffolding
- **Description:** Creates `.github/workflows/ci.yml` as the qrspi-plus CI workflow file. The workflow declares two `ubuntu-latest` jobs that together cover four verification surfaces. The `lint` job installs shellcheck and runs it across `hooks/**/*.sh`, `scripts/**/*.sh`, and `tests/helpers/**.bash`, then runs the Option B ban-list grep against the same surface to fast-fail on enumerated bash-4+ constructs (`\bmapfile\b`, `\bdeclare -A\b`, `\$\{[^}]*,,\}`, `\$\{[^}]*\^\^\}`, `\bcoproc\b`, `\bwait -n\b`). The `bash32` job launches the pinned `bash:3.2@sha256:<digest>` Docker container (immutable digest reference rather than the mutable `bash:3.2` tag, so a registry tag update cannot silently shift the runtime), installs `bats-core`, `jq`, and `yq` inside the image, then executes the unit BATS suite (`tests/unit/`) followed by the acceptance BATS suite (`tests/acceptance/`) so every assertion runs against a real bash 3.2 runtime — this job is the load-bearing version-compat gate that catches both parse-time and runtime-only bash-4+ incompatibilities. The workflow's `on:` block fires on `push` to `main`, `push` to `qrspi/**` (QRSPI feature/task branch family), `push` to `*/issue-*` (agent-handle issue-branch family), and `pull_request` targeting `main`. The `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true` so rapid pushes do not queue redundant runs. Every third-party action reference is pinned to a commit SHA. The workflow file is the canonical CI signal that the Integrate skill's CI-gate consumer (T16) reads via the `gh` CLI on the head commit of the integrate branch. **Expression-injection hardening:** all GitHub Actions context values that contain user-controlled data (`github.ref`, `github.head_ref`, `github.event.pull_request.title`, `github.event.pull_request.body`, and any `github.event.pull_request.*` field, plus any `github.event.issue.*` field) MUST NOT be interpolated directly into `run:` step shell commands via `${{ expression }}` syntax — direct interpolation enables remote code execution from attacker-controlled branch names or PR metadata. User-controlled context values are assigned to an `env:` block variable at the job or step level and referenced as `$ENV_VAR` inside the shell command, which the shell quotes safely. The `concurrency.group` field is a string field (not a shell command), so `${{ github.ref }}` interpolation there is acceptable; the prohibition applies to `run:` step bodies only.
- **Test expectations:**
  - `.github/workflows/ci.yml` parses as valid YAML.
  - The workflow defines exactly two `ubuntu-latest` jobs whose IDs match the documented `lint` and `bash32` behavioral roles.
  - The `lint` job runs shellcheck against the documented shell-script surface and runs the Option B ban-list grep as a distinct step on the same surface.
  - The `bash32` job launches the `bash:3.2@sha256:<digest>` Docker image (referenced by immutable digest, never a bare `bash:3.2` tag) and executes both the unit BATS suite and the acceptance BATS suite inside the container.
  - The `on:` triggers cover all four branch families (`main`, `qrspi/**`, `*/issue-*`, and `pull_request` to `main`).
  - The `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`.
  - Every third-party action invoked from the workflow is pinned to a commit SHA rather than a floating tag.
---
task_id: 15
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G7, G18]
dependencies: []
loc_estimate: 180
sizing_exception: reusable primitives
---

### Task 15: Combined G7+G18 hygiene contract in implementer-protocol with preload-only edits to both implementer agent bodies
- **Phase:** 1
- **Target files:**
  - `skills/implementer-protocol/SKILL.md` (Modify) — author the combined `## Hygiene contract` section that codifies the internal-ID forbidden-token list, the evergreen-markdown forbidden-token list, the path-shaped carve-outs, the inline carve-out comments, and the combined pre-DONE self-check.
  - `agents/qrspi-implementer.md` (Modify) — confirm the implementer's existing implementer-protocol preload pulls the new combined hygiene contract and that the pre-DONE step in the agent body invokes the combined self-check.
  - `agents/qrspi-implementer-lightweight.md` (Modify) — same preload-only treatment for the lightweight implementer so prose/doc/config tasks run the same combined self-check.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives
- **Description:** Authors the single combined hygiene contract that satisfies both the internal-ID forbidden-token requirement and the evergreen-markdown forbidden-token requirement in one section of `skills/implementer-protocol/SKILL.md`, with preload-only acknowledgment edits to both implementer agent bodies so the contract reaches the TDD and lightweight dispatch paths through the existing implementer-protocol preload. The new `## Hygiene contract` section in `skills/implementer-protocol/SKILL.md` carries five subsections: a forbidden-token subsection listing the internal-ID regex families (reviewer finding IDs of the form round-N finding-NN, task IDs of the form `T<NN>`, goal IDs of the form `G<N>`, question IDs of the form `Q<N>`, future-goal IDs of the form `F-<N>`, and design decision IDs of the form `D<N>`) that apply to every edited file; a forbidden-token subsection listing the evergreen-markdown regex families (release-version tokens such as `v\d+\.\d+`, milestone wording such as "in v0.7" or "after this release", and PR or issue references used as a justification for current behavior) that apply only to edited markdown; a path-shaped carve-out subsection that exempts `docs/qrspi/**` (the QRSPI artifact directory IS internal addressing), `agents/qrspi-*-reviewer.md` (reviewer agent bodies that document the finding-ID schema), runtime-assembled prompt parameters (in-memory dispatch payloads such as `wave_context:` are not git-tracked files), `docs/qrspi/YYYY-MM-DD-*/**` and `CHANGELOG.md` and `tests/fixtures/**` (dated pipeline artifacts and version-of-record files and version-tagged fixtures); an inline carve-out subsection documenting `<!-- id-hygiene-exempt -->` for the internal-ID rules and `<!-- evergreen-exempt -->` for the evergreen-markdown rules, both applying to the single line carrying the comment; and a pre-DONE self-check subsection that defines one combined scan over the implementer's commit diff added-lines, runs both regex passes, emits one combined report, and is advisory — the commit proceeds whether or not hits are present, but any retained hit must be explicitly acknowledged with reasoning in the DONE report so the reviewer dispatched against the artifact sees the acknowledgment. The `agents/qrspi-implementer.md` and `agents/qrspi-implementer-lightweight.md` edits change only the preload acknowledgment surface — confirming the existing `skills: [implementer-protocol]` preload pulls the new section and that the pre-DONE step the agent body already declares now references the combined self-check by name — without duplicating hygiene contract prose in either agent body, because the protocol is the single source of truth.
- **Test expectations:**
  - The `## Hygiene contract` section in `skills/implementer-protocol/SKILL.md` exists with the five named subsections (internal-ID forbidden tokens, evergreen-markdown forbidden tokens, path-shaped carve-outs, inline carve-outs, pre-DONE self-check).
  - The internal-ID forbidden-token subsection enumerates all six internal-ID families (reviewer finding ID, task ID, goal ID, question ID, future-goal ID, design decision ID) with the corresponding regex shapes.
  - The evergreen-markdown forbidden-token subsection enumerates release-version tokens, milestone wording, and PR or issue references with the corresponding regex shapes.
  - The path-shaped carve-out subsection names `docs/qrspi/**`, reviewer agent files, runtime-assembled prompt parameters, dated pipeline artifacts under `docs/qrspi/YYYY-MM-DD-*/**`, `CHANGELOG.md`, and `tests/fixtures/**` as exempt surfaces.
  - The inline carve-out subsection documents both `<!-- id-hygiene-exempt -->` and `<!-- evergreen-exempt -->` with their single-line scoping rule.
  - The pre-DONE self-check subsection states the scan is advisory, runs one combined pass, applies the internal-ID rules to all edited files and the evergreen-markdown rules to edited markdown only, and requires explicit DONE-report acknowledgment for any retained hit.
  - The pre-DONE self-check subsection specifies the concrete reviewer-visibility mechanism for unacknowledged hits: the DONE-report body is passed as a companion parameter on every per-task reviewer dispatch (so the reviewer's pre-flight reads the DONE-report alongside the artifact under review), AND the per-task reviewer dispatch site explicitly lists the DONE-report file path so reviewers can re-Read it directly — both channels carry the unacknowledged-hit data so reviewer visibility is structurally enforced rather than nominal.
  - `agents/qrspi-implementer.md` preloads `implementer-protocol` and its pre-DONE step references the combined self-check by name without duplicating the hygiene contract prose.
  - `agents/qrspi-implementer-lightweight.md` preloads `implementer-protocol` and its pre-DONE step references the combined self-check by name without duplicating the hygiene contract prose.
---
task_id: 16
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: [T14]
loc_estimate: 60
---

### Task 16: Update Integrate skill CI-gate to consume the new ci.yml workflow as canonical CI signal
- **Phase:** 1
- **Target files:**
  - `skills/integrate/SKILL.md` (Modify) — rewrite the existing CI-gate section so it consumes the `.github/workflows/ci.yml` run status on the head commit of the integrate branch via the `gh` CLI as the canonical green-CI signal.
- **Dependencies:** T14
- **LOC estimate:** ~60
- **Description:** Updates the CI-gate section of `skills/integrate/SKILL.md` so the canonical green-CI signal consumed by Integrate is the success of all jobs in the new `.github/workflows/ci.yml` workflow on the head commit of the integrate branch, queried via the `gh` CLI. The edit names the workflow by file path (`.github/workflows/ci.yml`) as the authoritative signal source, instructs Integrate to query workflow run status for the head commit of the integrate branch using the `gh` CLI, and requires success of all jobs in that workflow run (both the `lint` job and the `bash32` job) as the gate condition. The edit removes any prior ambiguity in the CI-gate prose about which workflow or which run is canonical for this repo and replaces it with a single named source. Exact `gh` invocation form (e.g., `gh run list`, `gh run view`, JSON query path) is left to Implement at execution time — the skill prose names the contract surface, not the literal command line.
- **Test expectations:**
  - The CI-gate section in `skills/integrate/SKILL.md` names `.github/workflows/ci.yml` as the canonical CI workflow file.
  - The CI-gate section states that Integrate queries the workflow run status on the head commit of the integrate branch via the `gh` CLI.
  - The CI-gate section requires success of all jobs in the workflow run as the gate condition rather than a subset.
  - The CI-gate section states that when the `gh` CLI query for the head commit returns zero workflow runs for `.github/workflows/ci.yml`, the gate FAILS with a named diagnostic identifying the missing run (e.g., "No CI workflow run found for commit SHA <sha>; CI may not have triggered yet") and does NOT pass — vacuous success (no runs found ≠ all jobs passed) is closed so an Integrate session against a head commit whose CI hasn't been triggered (for example immediately after a force-push) cannot bypass the gate.
  - No prior wording in the CI-gate section contradicts the `.github/workflows/ci.yml` canonical-signal contract.
---
task_id: 17
task_type: code
model: sonnet
phase: 1
goal_ids: [G18]
dependencies: [T13, T14, T15]
loc_estimate: 140
---

### Task 17: Repo-wide evergreen-markdown BATS scan with path and inline carve-outs
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-evergreen-markdown.bats` (Create) — unit BATS pin that scans every git-tracked `**/*.md` file for evergreen-markdown forbidden tokens, applies the path-shaped and inline carve-outs from the hygiene contract, and fails loudly with per-file diagnostics on any hit outside the carve-outs.
- **Dependencies:** T13, T14, T15
- **LOC estimate:** ~140
- **Description:** Authors `tests/unit/test-evergreen-markdown.bats` as the repo-wide regex scan that enforces the evergreen-markdown contract documented in `skills/implementer-protocol/SKILL.md` (Task 15) under the same unit BATS surface that the `bash32` job executes in the new CI workflow (Task 14, exercised through the workflow consumer in Task 16). The BATS file loads the shared markdown helper from Task 13 via `load 'helpers/skill-markdown'` to keep `require_repo_root` and diagnostic conventions consistent with the other Slice 3 pins, then iterates over every git-tracked `**/*.md` file in the repo, skipping files whose path matches the carve-out globs `docs/qrspi/YYYY-MM-DD-*/**`, `CHANGELOG.md`, and `tests/fixtures/**`. For each remaining file the test runs one regex pass per forbidden-token family (release-version tokens such as `v\d+\.\d+`, milestone wording such as "in v0.7" or "after this release", and PR or issue references used to justify current behavior). Lines containing the inline carve-out comment `<!-- evergreen-exempt -->` are skipped on that line only. Any surviving hit fails the test with a loud per-file, per-line diagnostic that names the file path, the line number, the matched regex family, and the matched text. The test is bash 3.2 portable (no `mapfile`, no `declare -A`, no `${var,,}`, no `coproc`, no `wait -n`) so it runs cleanly inside the `bash:3.2` Docker container under the `bash32` job.
- **Test expectations:**
  - A markdown file outside any path carve-out containing `in v0.6` fails the test with a diagnostic naming the file, line, and matched regex family.
  - A markdown file outside any path carve-out describing behavior by contract surface (no version tokens, no milestone wording, no PR/issue references) passes the test.
  - A markdown file under `docs/qrspi/YYYY-MM-DD-*/**` containing a release-version token does not fail the test.
  - A markdown file at `CHANGELOG.md` containing release-version tokens does not fail the test.
  - A markdown file under `tests/fixtures/**` containing a release-version token does not fail the test.
  - A markdown line containing a release-version token followed by `<!-- evergreen-exempt -->` does not fail the test even when the file is outside the path carve-outs.
  - A non-markdown file (for example a `.sh` file) containing a release-version token has no effect on the test result.
  - The test loads `tests/helpers/skill-markdown.bash` via the shared helper convention and runs to completion under bash 3.2 inside the `bash:3.2` Docker image.
---
task_id: 18
task_type: code
model: sonnet
phase: 1
goal_ids: [G7, G18]
dependencies: [T13, T15]
loc_estimate: 150
---

### Task 18: Implementer pre-DONE self-check BATS pin for combined hygiene contract behavior
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-hygiene-self-check.bats` (Create) — unit BATS pin that exercises the combined pre-DONE self-check defined in `skills/implementer-protocol/SKILL.md`, asserting added-line hit detection on both internal-ID and evergreen-markdown regex families, advisory commit semantics, the DONE-report acknowledgment path, and reviewer visibility for unacknowledged hits.
- **Dependencies:** T13, T15
- **LOC estimate:** ~150
- **Description:** Authors `tests/unit/test-hygiene-self-check.bats` as the BATS pin that exercises the combined pre-DONE self-check contract Task 15 codifies in `skills/implementer-protocol/SKILL.md`. The pin loads the shared markdown helper from Task 13 via `load 'helpers/skill-markdown'` to read the hygiene contract subsections from the protocol file by H2/H3 anchor, then exercises the self-check against synthesized commit-diff fixtures. The first fixture adds a line containing an internal-ID token (for example a reviewer finding ID of the round-N finding-NN form) to a `skills/foo/SKILL.md` path — the test asserts the self-check reports a hit naming the file, line, and internal-ID family. The second fixture adds the same token under `docs/qrspi/**` — the test asserts the self-check does not report a hit because of the path-shaped carve-out. The third fixture adds an evergreen-markdown token (for example `in v0.7+`) to a non-exempt markdown file — the test asserts the self-check reports a hit naming the file, line, and evergreen-markdown family. The fourth fixture adds the same token to a `.sh` file — the test asserts no hit because evergreen-markdown rules apply only to edited markdown. The fifth fixture pairs a retained hit with an explicit acknowledgment line in the DONE report — the test asserts the commit proceeds and the acknowledgment is preserved in the report for reviewer visibility. The sixth fixture pairs a retained hit with no acknowledgment — the test asserts the commit still proceeds (advisory contract) AND that the unacknowledged hit is surfaced to the reviewer through the DONE-report channel the reviewer dispatch consumes. The test is bash 3.2 portable so it runs cleanly inside the `bash:3.2` Docker container under the `bash32` job.
- **Test expectations:**
  - An added line containing an internal-ID token on a `skills/foo/SKILL.md` fixture path triggers a self-check hit naming the file, line, and internal-ID family.
  - An added line containing the same internal-ID token under a `docs/qrspi/**` fixture path does not trigger a self-check hit.
  - An added line containing an evergreen-markdown token on a non-exempt markdown fixture path triggers a self-check hit naming the file, line, and evergreen-markdown family.
  - An added line containing an evergreen-markdown token on a `.sh` fixture path does not trigger a self-check hit.
  - A retained hit accompanied by an explicit DONE-report acknowledgment proceeds to commit and the acknowledgment is preserved in the report.
  - A retained hit with no acknowledgment still proceeds to commit (advisory contract holds) and the unacknowledged hit is surfaced to the reviewer through the DONE-report channel — observably, the next per-task reviewer dispatch includes the DONE-report body as a companion parameter AND the DONE-report file path is listed in the dispatch payload so the reviewer Reads it during pre-flight.
  - The test loads `tests/helpers/skill-markdown.bash` via the shared helper convention and runs to completion under bash 3.2 inside the `bash:3.2` Docker image.
---
task_id: 19
task_type: code
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: [T13, T14]
loc_estimate: 200
sizing_exception: CI scaffolding
---

### Task 19: CI workflow shape pin and bash32 runtime coverage pin co-shipped against ci.yml
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-ci-workflow-shape.bats` (Create) — unit BATS pin that asserts `.github/workflows/ci.yml` parses as YAML, declares the two-job lint/bash32 surface with the documented trigger families and concurrency block, and pins commit-SHA action versions.
  - `tests/unit/test-bash32-runtime-coverage.bats` (Create) — unit BATS pin that asserts the Option B ban-list remains current by executing every enumerated construct under a real `bash:3.2` runtime and observing each construct fail.
- **Dependencies:** T13, T14
- **LOC estimate:** ~200
- **Sizing exception:** CI scaffolding
- **Description:** Co-ships two unit BATS pins against the same CI-workflow contract Task 14 introduces, because both observe the workflow's bash-3.2 verification surface and the ban-list-versus-runtime relationship the workflow encodes. The first pin, `tests/unit/test-ci-workflow-shape.bats`, loads the shared markdown helper from Task 13 for `require_repo_root` and diagnostic conventions, then asserts that `.github/workflows/ci.yml` parses as valid YAML (using `yq` inside the unit BATS surface), declares exactly two `ubuntu-latest` jobs whose IDs map to the documented `lint` and `bash32` behavioral roles, that the `lint` job carries both shellcheck and Option B ban-list steps, that the `bash32` job launches the `bash:3.2` Docker image and runs both the unit and acceptance BATS suites inside the container, that the `on:` trigger block covers `push` to `main`, `push` to `qrspi/**`, `push` to `*/issue-*`, and `pull_request` to `main`, that the `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`, and that every third-party action reference is pinned to a commit SHA rather than a floating tag. The second pin, `tests/unit/test-bash32-runtime-coverage.bats`, is the contrapositive of the ban-list-currency question: the `bash32` docker job validates ban-list currency by execution, so any ban-listed construct that runs under `bash:3.2` must fail; the test asserts every currently-listed construct (`mapfile`, `declare -A`, `${var,,}`, `${var^^}`, `coproc`, `wait -n`, and any further constructs the ban-list enumerates at test time) fails under `bash:3.2`, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate. The fixture set for the second pin is derived from the ban-list itself, parsed out of the lint job's step body so the test stays synchronized with the workflow rather than carrying an independent enumeration; each fixture is a one-line shell script invoking the construct in a way that executes the bash-4 codepath, and the pin asserts each fixture's invocation under `docker run --rm bash:3.2 bash -c '<fixture>'` exits non-zero. Both tests are bash 3.2 portable so they run cleanly inside the `bash:3.2` Docker container under the `bash32` job that they collectively observe.
- **Test expectations:**
  - `tests/unit/test-ci-workflow-shape.bats` asserts `.github/workflows/ci.yml` parses as valid YAML via `yq`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the workflow declares exactly two `ubuntu-latest` jobs whose IDs match the documented `lint` and `bash32` behavioral roles.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `lint` job carries both a shellcheck step and an Option B ban-list grep step.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `bash32` job launches the bash 3.2 Docker image referenced by immutable digest (`bash:3.2@sha256:<digest>`) — a bare `bash:3.2` tag without a `@sha256:` suffix fails the pin — and runs both the unit and acceptance BATS suites inside the container.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `on:` trigger block covers `push` to `main`, `push` to `qrspi/**`, `push` to `*/issue-*`, and `pull_request` to `main`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts every third-party action reference in the workflow is pinned to a commit SHA rather than a floating tag.
  - `tests/unit/test-ci-workflow-shape.bats` asserts no `run:` step in the workflow body contains a direct `${{ github.event.`, `${{ github.head_ref`, or `${{ github.ref` interpolation (the literal characters `${{` followed by `github.event.`, `github.head_ref`, or `github.ref`) — user-controlled GitHub Actions context values MUST be routed through `env:` block variables rather than interpolated directly into shell commands, closing the expression-injection vector. `github.ref` in `push` events resolves to `refs/heads/<branch-name>` where the branch-name segment is attacker-controlled, so an unquoted `${{ github.ref }}` inside a `run:` shell command is an injection vector alongside `github.head_ref`. The `concurrency.group` field is exempt because it is a string field, not a shell command.
  - `tests/unit/test-bash32-runtime-coverage.bats` parses the ban-list directly out of the workflow's `lint` job step body so its fixture set stays synchronized with the workflow.
  - `tests/unit/test-bash32-runtime-coverage.bats` asserts every currently-listed ban-list construct (`mapfile`, `declare -A`, `${var,,}`, `${var^^}`, `coproc`, `wait -n`, and any further enumerated constructs) fails under `docker run --rm bash:3.2 bash -c '<fixture>'`.
  - `tests/unit/test-bash32-runtime-coverage.bats` surfaces a loud diagnostic naming any new bash-4 construct authors introduce that the ban-list does not enumerate, by detecting any construct present in the workflow's ban-list that nonetheless succeeds under `bash:3.2` — the contrapositive observation that keeps the docker job's load-bearing role honest.
  - Both pins load `tests/helpers/skill-markdown.bash` via the shared helper convention and run to completion under bash 3.2 inside the `bash:3.2` Docker image.
---
task_id: 20
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G8]
dependencies: []
loc_estimate: 120
---

### Task 20: Add Worktree-Aware Setup Validation to Parallelize OWNS list + cross-skill OWNS/DEFERS drift audit
- **Phase:** 1
- **Target files:**
  - `skills/parallelize/owns-defers.md` (Modify) — add the Worktree-Aware Setup Validation line to the OWNS list and clarify the matching DEFERS boundary that keeps actual worktree/branch creation, baseline-test execution, and config edits with Implement.
  - `skills/*/owns-defers.md` (Modify — any) — any other skill's `owns-defers.md` MAY be modified during the cross-skill audit if same-pattern drift (skill mandates the work, owns-defers omits it) is discovered. Target files beyond `skills/parallelize/owns-defers.md` are discoverable at Implement time via the audit and are not pre-enumerated.
  - `docs/qrspi/future-goals.md` (Modify) — genuine-scope-debate mismatches discovered during the audit are logged here for a subsequent Goals run.
- **Dependencies:** none
- **LOC estimate:** ~120 (Parallelize OWNS/DEFERS base edit is ~60 LOC; the round-2-added cross-skill audit can yield 0–8 additional same-pattern-drift edits across other `skills/*/owns-defers.md` files, each ~5–10 LOC, so the upper bound is roughly 120 LOC and may approach the 200-LOC threshold if every audited skill exhibits drift — the implementer should escalate to opus if the audit yields more than ~6 drift fixes)
- **Description:** Closes the source-of-truth drift between the Parallelize skill's process (which already requires a Worktree-Aware Setup Validation step and surfaces results in `parallelization.md`) and `skills/parallelize/owns-defers.md` (which does not currently list that validation as an owned responsibility). Adds a Worktree-Aware Setup Validation line to the OWNS list scoped as advisory — Parallelize surfaces remediation guidance but does NOT auto-patch the artifact or perform the setup itself — and adjusts the DEFERS list to make the boundary explicit by stating that actual worktree creation, branch creation, baseline-test execution, and the on-disk config edits remain with Implement. The Parallelize scope reviewer reads `owns-defers.md` as its source of truth at dispatch time, so this OWNS addition is sufficient to eliminate the recurring false-positive scope-drift finding the reviewer emits against skill-mandated sections; no edit to the scope-reviewer agent file is required. **Cross-skill audit (time-boxed):** after applying the Parallelize OWNS/DEFERS edits, the implementer greps every `skills/*/SKILL.md` for instruction patterns (`write … to <artifact>`, `verify …`, `surface …`) and cross-checks each match against the corresponding `skills/*/owns-defers.md`. Mismatches that share the Parallelize pattern (the skill mandates the work but `owns-defers.md` omits it) are fixed in the same task by editing the appropriate `skills/*/owns-defers.md`. Mismatches that warrant genuine scope debate (rather than mechanical drift) are logged to `docs/qrspi/future-goals.md` rather than auto-resolved. Target files beyond `skills/parallelize/owns-defers.md` are discoverable at Implement time via the audit — they are not pre-declared because the audit's findings determine which other files require edits.
- **Test expectations:**
  - The OWNS list in `skills/parallelize/owns-defers.md` contains a Worktree-Aware Setup Validation entry naming the advisory-surface responsibility.
  - The OWNS entry states the validation surfaces remediation and does NOT auto-patch the parallelization artifact.
  - The DEFERS list explicitly retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned.
  - The added OWNS line uses canonical vocabulary consistent with `skills/parallelize/SKILL.md` so the Parallelize quality reviewer does not flag it as a style drift.
  - The cross-skill audit is observably executed: the implementer DONE report enumerates every `skills/*/SKILL.md` that was grepped for the three instruction patterns (`write … to`, `verify …`, `surface …`), names each match found, and records the disposition of each match (same-pattern-drift-fix-in-this-task, genuine-scope-debate-logged-to-future-goals, or no-mismatch). Absence of the enumerated grep audit in the DONE report is a STOP condition for the reviewer.
  - When same-pattern drift is discovered in another skill's `owns-defers.md`, the implementer edits that file in the same task and the DONE report names the file and the OWNS or DEFERS entry added.
  - When a genuine scope-debate mismatch is discovered, the implementer appends an entry to `docs/qrspi/future-goals.md` and the DONE report names the appended entry by `id:` or short slug.
  - (Phase-acceptance — Integrate-time, not a BATS unit pin): re-dispatching the Parallelize scope reviewer against a worktree-aware parallelization artifact produces no scope-drift finding on the Worktree-Aware Setup Validation section. Deterministic unit-tier observation lives in T23's `test-parallelize-owns-defers.bats`.
---
task_id: 21
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G9]
dependencies: []
loc_estimate: 90
---

### Task 21: Align multi-stage suffix grammar in parallelize SKILL.md and parallelize-reviewer agent
- **Phase:** 1
- **Target files:**
  - `skills/parallelize/SKILL.md` (Modify) — document the canonical multi-stage suffix grammar `stage-after-W{N}{suffix}` (suffix `a|b|c|...`) inside the Branch Model section and extend the Worked Example to cover a multi-stage-per-Wave case.
  - `agents/qrspi-parallelize-reviewer.md` (Modify) — align the reviewer's vocabulary-expectation list with the canonical tokens in `skills/parallelize/SKILL.md` so canonical forms are not flagged as style violations.
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** Resolves the Parallelize-reviewer false-positive class caused by vocabulary drift between the skill's Branch Map prose and the reviewer's accepted-token list. Updates `skills/parallelize/SKILL.md`'s Branch Model section to declare the canonical multi-stage suffix grammar `stage-after-W{N}{suffix}` where `{N}` is the originating Wave index and `{suffix}` is a single lowercase letter (`a`, `b`, `c`, ...) ordering multiple stages emitted from the same Wave; the existing Worked Example is extended to cover a Wave that emits multiple stage branches so the suffixed form has a documented illustration. The companion edit in `agents/qrspi-parallelize-reviewer.md` aligns the reviewer's accepted-vocabulary list to the same canonical tokens (`feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form) and removes the rejected non-canonical forms (hyphenated or integer-suffixed variants) that were producing style findings on valid artifacts. The skill is the source of truth; the reviewer file is brought into line with the skill.
- **Test expectations:**
  - The Branch Model section in `skills/parallelize/SKILL.md` documents the `stage-after-W{N}{suffix}` form and names the suffix alphabet (`a|b|c|...`).
  - The Worked Example in `skills/parallelize/SKILL.md` illustrates at least one Wave emitting multiple stage branches using the suffixed form.
  - The vocabulary-expectation list in `agents/qrspi-parallelize-reviewer.md` enumerates the canonical tokens `feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed variant.
  - The reviewer file no longer enumerates the previously rejected non-canonical forms as acceptable variants.
  - The reviewer's accepted-token list matches the SKILL.md canonical token set with no drift between the two files.
  - (Phase-acceptance — Integrate-time, not a BATS unit pin): re-dispatching the Parallelize quality reviewer against a parallelization artifact that uses the canonical multi-stage suffix grammar produces no style finding; an artificially-introduced unconventional form (e.g., `stageAfterWave4`) still produces a style finding. Deterministic unit-tier observation lives in T23's `test-parallelize-vocab.bats`.
---
task_id: 22
task_type: code
model: sonnet
phase: 1
goal_ids: [G14]
dependencies: [T13]
loc_estimate: 120
---

### Task 22: Migrate three existing BATS files to the shared skill-markdown helper
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-skill-md-content-patterns.bats` (Modify) — replace inline section-extraction logic with `load 'helpers/skill-markdown'` and call the helper's `extract_section` / `extract_and_grep` / `assert_section_contains` functions in place of the hand-rolled awk + grep blocks.
  - `tests/unit/test-cross-skill-contracts.bats` (Modify) — same helper-load refactor; replace the inline section-scoped extraction with the helper API.
  - `tests/unit/test-worktree-aware-defaults.bats` (Modify) — same helper-load refactor; route section extraction through the helper.
- **Dependencies:** T13
- **LOC estimate:** ~120
- **Description:** Migrates the three existing BATS files that independently hand-rolled the section-extract + grep pattern (per the G14 finding) so they consume the shared `tests/helpers/skill-markdown.bash` helper authored in T13. Each file is rewritten to `load 'helpers/skill-markdown'` near the top of the file and to call `extract_section`, `extract_and_grep`, or the BATS-shaped `assert_section_contains` wrapper in place of the previous inline awk + grep blocks; the `require_repo_root` guard replaces any bespoke `REPO_ROOT` resolution. The migration preserves every existing test behavior — every previously-asserted contract (every `@test` block, every assertion target, every failure mode the file is meant to catch) remains intact and continues to fire on the same conditions. No tests are deleted, renamed, or weakened; the change is a helper-load refactor that consolidates the duplicated section-extraction implementation behind the shared helper API while keeping the observable test surface unchanged. Empty-extract, missing-anchor, and end-of-file boundary handling now come from the helper's loud-failure diagnostics rather than each file's locally-implemented guard.
- **Test expectations:**
  - `tests/unit/test-skill-md-content-patterns.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - `tests/unit/test-cross-skill-contracts.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - `tests/unit/test-worktree-aware-defaults.bats` loads the helper via `load 'helpers/skill-markdown'` and contains no remaining inline awk-based section extractor.
  - Every `@test` block present in each file before migration is present after migration with the same `@test` name and the same asserted contract; no test block is deleted or renamed.
  - The full BATS run for all three files passes against the current skill markdown surface, matching the green pre-migration baseline.
  - When the helper is forced into a missing-anchor or empty-extract path against a fixture, the loud diagnostic from the helper (file, heading anchor, miss reason) is what surfaces in BATS output, rather than a locally-implemented guard message.
  - Each migrated file's `REPO_ROOT` resolution comes from the helper's `require_repo_root` rather than file-local resolution code.
---
task_id: 23
task_type: code
model: sonnet
phase: 1
goal_ids: [G8, G9, G14]
dependencies: [T13, T20, T21]
loc_estimate: 120
---

### Task 23: New Slice 4 pins — parallelize owns-defers and canonical vocabulary
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-parallelize-owns-defers.bats` (Create) — pin that asserts the OWNS list in `skills/parallelize/owns-defers.md` contains the Worktree-Aware Setup Validation entry added in T20, using the shared `skill-markdown.bash` helper for section extraction.
  - `tests/unit/test-parallelize-vocab.bats` (Create) — pin that asserts the canonical multi-stage suffix-grammar tokens are present in both `skills/parallelize/SKILL.md`'s Branch Model section and `agents/qrspi-parallelize-reviewer.md`'s vocabulary list, plus a drift-fixture assertion that an unconventional form (`stageAfterWave4`) is flagged.
- **Dependencies:** T13, T20, T21
- **LOC estimate:** ~120
- **Description:** Lands the two Slice 4 contract pins that observe the post-T20 and post-T21 surfaces and prevent future drift. `tests/unit/test-parallelize-owns-defers.bats` consumes the shared `tests/helpers/skill-markdown.bash` helper to extract the OWNS H2/H3 section from `skills/parallelize/owns-defers.md` and asserts that the extract contains a Worktree-Aware Setup Validation line scoped as advisory (no auto-patch); a separate assertion confirms the DEFERS section retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned. `tests/unit/test-parallelize-vocab.bats` uses the same helper to extract the Branch Model section from `skills/parallelize/SKILL.md` and the vocabulary-expectation section from `agents/qrspi-parallelize-reviewer.md`, then asserts that the canonical token set (`feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form) is present in both files with no drift between the two; a final assertion uses a drift fixture containing the unconventional form `stageAfterWave4` and verifies the reviewer-side regex flags it as a style violation. Both pins follow the loud-failure contract from the helper so missing-anchor or empty-extract conditions surface as named diagnostics rather than silent passes.
- **Test expectations:**
  - `test-parallelize-owns-defers.bats` extracts the OWNS section from `skills/parallelize/owns-defers.md` via the helper and asserts a Worktree-Aware Setup Validation entry is present.
  - The same file asserts the OWNS entry names the advisory-only scope and does not declare an auto-patch responsibility.
  - The same file asserts the DEFERS section retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned.
  - `test-parallelize-vocab.bats` extracts the Branch Model section from `skills/parallelize/SKILL.md` via the helper and asserts the canonical tokens `feature branch tip`, `task-NN tip`, `task-00 tip`, `stage-after-W{N}`, and the suffixed `stage-after-W{N}{suffix}` form are present.
  - The same file extracts the vocabulary-expectation section from `agents/qrspi-parallelize-reviewer.md` via the helper and asserts the same canonical token set is present.
  - The same file asserts no drift exists between the SKILL.md canonical tokens and the reviewer file's accepted-token list.
  - The same file uses a drift fixture containing `stageAfterWave4` and asserts the reviewer-side flag fires on the unconventional form.
  - Both pins emit the helper's loud-failure diagnostic (file, heading anchor, miss reason) when a section anchor is missing or the extract is empty, rather than silently passing.
---
task_id: 24
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10, G11]
dependencies: []
loc_estimate: 180
sizing_exception: schema migration
---

### Task 24: Introduce Plan-skill per-task spec frontmatter contract for reference-gate and UI fields with SPEC OVERRIDES SOURCE authority
- **Phase:** 1
- **Target files:**
  - `skills/plan/SKILL.md` (Modify) — task-spec template adds `reference_gate: true` + paired-required `reference_artifact: <path>`, `ui: true`, and optional `lift_source: <path>` frontmatter fields; refuse-to-write contract when paired fields are inconsistent; mandatory `SPEC OVERRIDES SOURCE` body section when `lift_source:` is present; one-time migration step rewrites `visual_fidelity_check.ui_producing: true` to top-level `ui: true`; SPEC OVERRIDES SOURCE precedence statement.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** schema migration
- **Description:** Establishes the per-task spec frontmatter contract for Slice 5 by extending `skills/plan/SKILL.md`'s task-spec template, split-task-file template, and Red Flags surface with four additive (and one replacement) frontmatter fields plus the SPEC OVERRIDES SOURCE authority statement that every downstream consumer (T25 Structure, T26 Parallelize, T27 Implement, T28 visual-fidelity reviewer, T29 reviewer-protocol/design-skill checklist) keys on. The four fields are `reference_gate: true` (G10), `reference_artifact: <path>` (G10; REQUIRED when `reference_gate: true`, absent otherwise — paired contract), `ui: true` (G11), and `lift_source: <path>` (G11; when present, the task body MUST include a `SPEC OVERRIDES SOURCE` section listing source behavior the implementer must NOT copy and the required target behavior). The migration step rewrites any pre-existing `visual_fidelity_check.ui_producing: true` into top-level `ui: true` and drops the nested `ui_producing` field from the schema; this is the one replacement-not-additive Slice 5 field per design Decision 10's second exception. The orchestrator-side **paired-field refuse-to-write contract** states explicitly: any task spec with `reference_gate: true` MUST also carry `reference_artifact: <path>`, and any task spec with `ui: true` AND `lift_source: <path>` MUST contain a `SPEC OVERRIDES SOURCE` body section — Plan refuses to write the task spec (or, in post-approval split, refuses to materialize the per-task file) when either pair is incomplete, surfacing a named diagnostic identifying the offending task number and the missing companion. The SPEC OVERRIDES SOURCE contract is stated separately in the body authority paragraph: when a per-task spec is authored in `plan.md` (or in a split `tasks/task-NN.md` produced via the sub-subagent fan-out), that spec is authoritative; if a source file's existing frontmatter (e.g., a pre-existing `visual_fidelity_check` block, a stale `ui_producing` value, or any conflict with the new frontmatter contract) disagrees with the spec, the spec wins and the source is rewritten to match. The Red Flags table adds the paired-field violation as a STOP condition. The implementer Description must call out that this spec contract is **architecturally load-bearing** — every Slice 5 consumer (T25–T29) keys on the frontmatter shape established here — so the operator may flip `model: opus` before approval if the schema-migration risk warrants the upgrade; default classification per the per-task heuristic stays at `lightweight` / `sonnet` because all target edits land in `skills/plan/SKILL.md` markdown body and template prose. The `sizing_exception: schema migration` justification stands because the per-task spec frontmatter contract IS a schema migration over plan task specs — one observable behavior (the contract is one decision) applied across many call sites and template surfaces inside one skill file.
- **Test expectations:**
  - The Plan-skill task-spec template and split-task-file template both expose `reference_gate`, `reference_artifact`, `ui`, and `lift_source` as documented frontmatter fields with the paired-contract guidance and the SPEC OVERRIDES SOURCE body-section requirement.
  - The Plan orchestrator refuses to write a task spec when `reference_gate: true` is present without a matching `reference_artifact: <path>`, surfacing a named diagnostic identifying the offending task number.
  - The Plan orchestrator refuses to write a task spec when `ui: true` and `lift_source: <path>` are both present without a `SPEC OVERRIDES SOURCE` body section, surfacing a named diagnostic identifying the offending task number.
  - The Plan-skill body carries an explicit SPEC OVERRIDES SOURCE statement asserting the per-task spec is authoritative over any conflicting frontmatter or block in a source file.
  - The migration step rewrites a fixture task spec carrying `visual_fidelity_check.ui_producing: true` to top-level `ui: true` and drops the nested `ui_producing` field from the schema.
  - The Red Flags table lists the paired-field violation and the missing-`SPEC OVERRIDES SOURCE`-section condition as STOP entries.
  - A pre-Slice-5 task spec with no `reference_gate:`, `reference_artifact:`, `ui:`, or `lift_source:` frontmatter fields is written and processed without error, produces no paired-field diagnostic, triggers no visual-fidelity reviewer dispatch, and triggers no reference-gate pause — behaving identically to a v0.6 task spec per design.md Decision 10's safe-default contract.
---
task_id: 25
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G11]
dependencies: [T24]
loc_estimate: 90
---

### Task 25: Add Structure-skill UI Reference Affordances section spec for sibling reference repo, lift codemod, and image-asset pipeline
- **Phase:** 1
- **Target files:**
  - `skills/structure/SKILL.md` (Modify) — add optional `## UI Reference Affordances` section spec; captured once per release for sibling reference repo, lift codemod, and image-asset pipeline; required when any task spec carries `lift_source:`.
- **Dependencies:** T24
- **LOC estimate:** ~90
- **Description:** Extends `skills/structure/SKILL.md` with an optional `## UI Reference Affordances` section spec that consumes the `lift_source:` frontmatter field T24 introduces. The section spec documents three affordances Structure records once per release rather than re-deriving per task: the sibling reference repo path (where the coded prototype lives — sibling repo, scratch directory, or upstream pinned commit), the lift-codemod transformation (token import codemod or equivalent mechanical lift recipe that translates source tokens into the target's design-system vocabulary), and the image-asset pipeline (where reference PNG/SVG/PDF artifacts live and how they reach the target tree). The section spec is optional at the Structure-skill level but BECOMES REQUIRED at the structure.md instance level when any task spec in the same release carries `lift_source:` — Structure refuses to mark `structure.md` approved if a `lift_source:` task exists in the plan without a corresponding `## UI Reference Affordances` section. The new section spec also documents the consumer contract: T28's refined visual-fidelity reviewer Reads `## UI Reference Affordances` from `structure.md` to ground its lift-verbatim-vs-re-derive judgments. Adds a Red Flags entry that fires when a plan contains `lift_source:` tasks but `structure.md` lacks `## UI Reference Affordances`. The Structure-skill body change is markdown prose and template-spec only — no code surface — so the lightweight/sonnet classification holds. Operator may flip to opus before approval if the section-spec shape warrants the upgrade.
- **Test expectations:**
  - `skills/structure/SKILL.md` documents the `## UI Reference Affordances` section spec with the three affordances (sibling reference repo path, lift-codemod transformation, image-asset pipeline) enumerated.
  - The section spec states the consumer contract that T28's visual-fidelity reviewer Reads `## UI Reference Affordances` from `structure.md` for lift-verbatim-vs-re-derive grounding.
  - The section spec states the conditional-required rule: when any task spec in the release carries `lift_source:`, `structure.md` MUST contain `## UI Reference Affordances`.
  - A Red Flags entry fires when a plan contains `lift_source:` tasks but `structure.md` lacks the section.
  - Behavioral refusal: when a fixture `plan.md` contains a task with `lift_source:` but the corresponding `structure.md` is missing the `## UI Reference Affordances` section, the Structure skill returns a named refusal at its approval step rather than marking `status: approved` — observable in the skill's exit behavior, not only in the Red Flags table's prose.
---
task_id: 26
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T24]
loc_estimate: 90
---

### Task 26: Add Parallelize-skill reference-gate wave termination and parallelization.md note shape
- **Phase:** 1
- **Target files:**
  - `skills/parallelize/SKILL.md` (Modify) — reference-gated task terminates its wave; `parallelization.md` emits an explicit note listing the gate and dependent tasks waiting on it.
- **Dependencies:** T24
- **LOC estimate:** ~90
- **Description:** Extends `skills/parallelize/SKILL.md` so any task carrying T24's `reference_gate: true` frontmatter field acts as a wave-terminating task — no dependent task in any later wave can dispatch until the gate releases. The Parallelize body documents the wave-termination rule alongside the existing wave-grouping logic and updates the Branch Model worked example to show a reference-gated task ending its wave with dependents landing in the next wave. The `parallelization.md` artifact emits an explicit note (canonical shape: `Reference gate: task-NN ({task name}) — dependents waiting: task-XX, task-YY, task-ZZ`) listing every reference-gated task and the dependent task IDs waiting on it; the note shape is documented in the Parallelize template section so reviewers and downstream consumers (T27 Implement) can locate the gates by pattern. Adds a Red Flags entry that fires when `parallelization.md` contains a reference-gated task without the canonical note, or when a dependent of a reference-gated task is scheduled in the same wave as the gate (wave-termination violation). Edits are markdown body and template-spec only, no code; lightweight/sonnet classification holds. Operator may flip to opus before approval if the wave-termination semantics warrant the upgrade.
- **Test expectations:**
  - `skills/parallelize/SKILL.md` documents the wave-termination rule: a task carrying `reference_gate: true` ends its wave and dependents land in the next wave.
  - The Parallelize Branch Model worked example shows a reference-gated task terminating a wave with dependents in the next wave.
  - The Parallelize template section documents the canonical `parallelization.md` note shape naming the gate task and the dependent task IDs waiting on it.
  - A Red Flags entry fires when `parallelization.md` contains a reference-gated task without the canonical note.
  - A Red Flags entry fires when a dependent of a reference-gated task is scheduled in the same wave as the gate.
---
task_id: 27
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10, G11]
dependencies: [T24, T26]
loc_estimate: 180
sizing_exception: reusable primitives
---

### Task 27: Add Implement-skill reference-gate human pause, wave_context companion, and visual-fidelity reviewer dispatch for ui:true tasks
- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — reference-gate human pause inside per-task DONE handling: render `reference_artifact:` via `SendUserFile` (images/PDF) or inline Read (text); require explicit "reference approved" confirmation before dispatching dependents; record approval at `reviews/tasks/task-NN/reference-gate.md`. For `ui: true` tasks, add `qrspi-visual-fidelity-reviewer` to per-task reviewer set and assemble `wave_context:` companion from earlier-wave sibling findings.
- **Dependencies:** T24, T26
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives
- **Description:** Extends `skills/implement/SKILL.md` with three coupled per-task orchestrator behaviors that together realize Slice 5's G10 reference-gate and G11 visual-fidelity-reviewer dispatch. Behavior one (G10 reference-gate human pause): when a task carrying T24's `reference_gate: true` frontmatter reaches DONE state, Implement halts before dispatching any dependent task. The orchestrator renders the `reference_artifact:` to the user in a user-visible form keyed on the artifact's file extension — images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`) and PDFs (`.pdf`) dispatch through `SendUserFile` so the user sees the rendered artifact, not a path string; text artifacts (`.md`, `.txt`, `.json`, `.yml`, `.yaml`, and other text MIME types) are surfaced via inline Read so the body appears in the conversation. The orchestrator requires explicit "reference approved" confirmation from the user before any dependent of the gated task dispatches, and records the approval (timestamp, run slug, task ID, reference_artifact path, approver acknowledgment line) at `reviews/tasks/task-NN/reference-gate.md` so subsequent re-runs and audits can verify the gate fired and was cleared. A bypass attempt (dispatching a dependent before the approval file exists) is blocked with a named diagnostic. Behavior two (G11 visual-fidelity reviewer dispatch): for any task carrying `ui: true`, Implement adds `qrspi-visual-fidelity-reviewer` to that task's per-task reviewer set, dispatched in parallel with the existing per-task reviewers using the shared per-task reviewer dispatch shape (artifact_body wrapped, output dir, round, reviewer_tag `visual-fidelity-claude`, diff_file_path, scope_hint when narrowed). Behavior three (G11 `wave_context:` companion assembly): when multiple sibling UI tasks ship in the same plan with `ui: true` (and optionally `lift_source:`), Implement constructs a per-wave `wave_context:` companion from prior-wave reviewer findings on those siblings — wrapped between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers per the reviewer-protocol untrusted-data convention — and passes it as a companion parameter on the visual-fidelity reviewer dispatch in later waves. The companion body carries the wave identifier (e.g., "Wave 2 — UI tasks") and per-task entries each showing task ID, task name, `allowed_files` glob, and any earlier-wave visual-fidelity reviewer findings on that sibling (finding category, severity, short summary). Absence of `wave_context:` is legal (first-wave dispatches, single-UI-task plans) and is treated as "no sibling history." The reference-gate pause and the visual-fidelity dispatch are coordinated so a reference-gated UI task waits for human approval before any dependent (including sibling UI tasks in later waves whose visual-fidelity dispatch would consume the gated task's reference) proceeds. Edits are markdown body and orchestrator-prose only inside `skills/implement/SKILL.md`; lightweight/sonnet classification holds. The `sizing_exception: reusable primitives` justification stands because the per-task DONE-handling pause, the visual-fidelity reviewer dispatch, and the `wave_context:` assembly are three coupled primitives that downstream Slice 5 consumers (T28 reviewer body, T30 pin bundle) key on as a unit. Operator may flip `model: opus` before approval if the three-primitive coupling warrants the upgrade.
- **Test expectations:**
  - `skills/implement/SKILL.md` documents the per-task DONE-handling reference-gate pause for tasks carrying `reference_gate: true`.
  - The pause renders the `reference_artifact:` to the user via `SendUserFile` for image and PDF artifacts and via inline Read for text artifacts.
  - The pause requires explicit "reference approved" confirmation before any dependent dispatches and records the approval at `reviews/tasks/task-NN/reference-gate.md`.
  - A bypass attempt that dispatches a dependent before the approval file exists is blocked with a named diagnostic.
  - Before any `SendUserFile` call or inline Read against the `reference_artifact:` value, the orchestrator validates that the resolved absolute path lies within the artifact-directory tree (`<artifact-dir>/**`) or within a declared `sibling_allowed_paths:` entry from the task spec — and additionally validates that EACH declared sibling-allowed path itself resolves to within either the artifact-directory tree (`<artifact-dir>/**`) or within the project's worktree root. A `sibling_allowed_paths:` entry that resolves outside both bounded trees (e.g., `/etc`, `/var`, `~/.ssh`, an absolute path under the user's home directory, or any path resolved via symlink outside the worktree) is itself rejected with a named sibling-allowed-path-validation diagnostic before the `reference_artifact:` resolution is even attempted — the bounded-tree constraint on sibling-allowed paths closes the confused-deputy gap where a task spec could otherwise widen the path-traversal guard to arbitrary filesystem locations. After both sets of bounded-tree constraints are validated, a `reference_artifact:` path that resolves outside the allowed tree (path-traversal attempts using `../`, absolute paths to filesystem secrets like `/etc/shadow` or `~/.ssh/id_rsa`, or symlink resolutions that escape the tree) is rejected with a named path-validation diagnostic, the pause aborts with no render or Read against the offending path, and no dependent dispatches. The T30 reference-gate-fields pin exercises the path-traversal rejection case with at least one fixture spec pointing outside the artifact dir AND at least one fixture spec carrying an out-of-tree `sibling_allowed_paths:` entry (e.g., `/etc`) and asserts no render call occurs in either case.
  - Implement adds `qrspi-visual-fidelity-reviewer` to the per-task reviewer set for any task carrying `ui: true`, using the shared per-task reviewer dispatch shape with reviewer_tag `visual-fidelity-claude`.
  - Implement assembles a `wave_context:` companion from earlier-wave visual-fidelity reviewer findings on sibling UI tasks and passes it on the visual-fidelity reviewer dispatch in later waves, wrapped between the canonical `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers.
  - Absence of `wave_context:` on first-wave or single-UI-task dispatches is legal and dispatch proceeds.
  - When a sibling task's earlier-wave finding body contains a `<<<UNTRUSTED-ARTIFACT-START` or `<<<UNTRUSTED-ARTIFACT-END` sentinel token, the `wave_context:` assembly step either strips the offending token (with a logged diagnostic naming the source finding) or excludes the finding from the payload with a loud diagnostic — never embeds a nested sentinel inside the outer wrapper body. In either redaction path, the `wave_context:` companion body MUST include an explicit machine-readable `REDACTION-NOTICE` entry naming the source task ID, the redaction action (strip or exclude), and the count of redacted findings, so the visual-fidelity reviewer that consumes the companion can detect that its context is incomplete rather than treating a silently-stripped companion as complete sibling history.
  - Implement passes an explicit `wave_number:` companion parameter on every visual-fidelity reviewer dispatch (`wave_number: 1` for first-wave, `wave_number: N` for later waves); the reviewer treats `wave_context:` absence as a load-bearing diagnostic when `wave_number > 1` AND the plan contains multiple sibling UI tasks (so a missing `wave_context:` caused by an orchestrator assembly bug fails loudly rather than silently degrading to "first-wave with no sibling history").
---
task_id: 28
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G11]
dependencies: [T24, T27]
loc_estimate: 100
---

### Task 28: Refine qrspi-visual-fidelity-reviewer agent to consume ui, lift_source, and wave_context inputs
- **Phase:** 1
- **Target files:**
  - `agents/qrspi-visual-fidelity-reviewer.md` (Modify) — refined in-place (no duplicate file) to consume `ui:` + `lift_source:` task-spec fields and the wave-aware `wave_context:` companion (untrusted-data wrapped per reviewer-protocol).
- **Dependencies:** T24, T27
- **LOC estimate:** ~100
- **Description:** Refines the existing `agents/qrspi-visual-fidelity-reviewer.md` agent body in place — no duplicate or parallel reviewer file is created — so it consumes the per-task spec frontmatter fields T24 introduces (`ui: true`, `lift_source: <path>`, the body's `SPEC OVERRIDES SOURCE` section when `lift_source:` is present) and the wave-aware `wave_context:` companion T27 assembles. The agent body documents three input-consumption contracts: (1) when the dispatched task carries `lift_source:`, the reviewer Reads the source path, Reads the `SPEC OVERRIDES SOURCE` section from the task spec, and grounds its lift-verbatim-vs-re-derive judgments by treating the spec section as authoritative over source behavior (the SPEC OVERRIDES SOURCE contract from T24); (2) when `wave_context:` is present on the dispatch, the reviewer treats the wrapped body as untrusted-data per the reviewer-protocol skill's untrusted-data handling, extracts the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, earlier-wave sibling findings), and grounds its findings in concrete sibling references — its output must contain either (a) at least one explicit reference to a sibling task's findings, or (b) an explicit statement that no relevant sibling visual context was found — observable in the emitted finding files; (3) when `## UI Reference Affordances` exists in `structure.md` (per T25), the reviewer Reads that section for the sibling reference repo path, lift-codemod, and image-asset pipeline grounding. The refined agent also studies the Keeplii workspace's working `qrspi-visual-fidelity-reviewer.md` as a reference template per the design's G11 implementer reference. The reviewer dispatch shape stays consistent with other per-task reviewers (5-field finding schema, change-type classifier, disk-write contract via the reviewer-protocol preload). Edit is markdown body in a single agent file; lightweight/sonnet classification holds.
- **Test expectations:**
  - The refined `agents/qrspi-visual-fidelity-reviewer.md` body documents consumption of `ui: true`, `lift_source: <path>`, and the body's `SPEC OVERRIDES SOURCE` section as authoritative inputs.
  - The body documents consumption of the `wave_context:` companion as untrusted-data per the reviewer-protocol's untrusted-data handling, extracting the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, earlier-wave sibling findings).
  - The reviewer's output for a wave-context dispatch contains either at least one explicit reference to a sibling task's findings or an explicit statement that no relevant sibling visual context was found.
  - The body documents consumption of `## UI Reference Affordances` from `structure.md` when present.
  - The body documents the reviewer's acknowledgment contract for the `REDACTION-NOTICE` entry T27 emits on the `wave_context:` companion when sibling findings were stripped or excluded due to sentinel collision: the reviewer MUST surface the redaction in its findings (naming the source task ID and the count) rather than treating the companion as complete sibling history, closing the false-confidence path documented in T27.
  - No duplicate or parallel visual-fidelity reviewer agent file is created; the existing file is refined in place.
---
task_id: 29
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10, G11]
dependencies: []
loc_estimate: 100
---

### Task 29: Add reviewer-protocol quick-tier finding-disposition guidance and design-skill reference-reviewer checklist
- **Phase:** 1
- **Target files:**
  - `skills/reviewer-protocol/SKILL.md` (Modify) — add quick-tier finding-disposition guidance that distinguishes high and correctness-medium inline patching from low-finding acceptance and prohibits blanket quick-tier merges.
  - `skills/design/SKILL.md` (Modify) — add checklist item: when a design introduces a reviewer whose verdict depends on an external reference artifact, the producing task is flagged `reference_gate: true` in Plan; record lift-verbatim vs. re-derive decision in `design.md`.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Ships the two reviewer-side supporting edits Slice 5 depends on. Edit one (G11 quick-tier wording in `skills/reviewer-protocol/SKILL.md`): adds a quick-tier finding-disposition section that codifies the Keeplii observed-useful pattern — inline-patch high-severity and correctness-medium findings during the quick tier, accept low-severity findings without inline patches, and explicitly prohibit blanket quick-tier merges (a quick-tier batch that accepts every finding without patching the highs and correctness-mediums is a process violation surfaced via a named diagnostic). The wording is owned by the reviewer-protocol body — the section names the disposition rule, the high/correctness-medium inline-patch requirement, the low-finding acceptance carve-out, and the no-blanket-merge prohibition, and is reachable via the protocol's standard section-anchor convention so T30's quick-tier-wording pin can extract it via the shared markdown helper. This edit is independent of UI work but ships in Slice 5 per the design's Decision 6 grouping (G10 and G11 are sibling reference-driven goals; the quick-tier wording is the G11 reviewer-protocol contribution). Edit two (G10/G11 design-skill checklist in `skills/design/SKILL.md`): adds a checklist item to the Design skill's process-step body asserting that when a design introduces a reviewer whose verdict depends on an external reference artifact (prototype screenshot, golden output file, contract fixture, lifted prototype), the producing task MUST be flagged `reference_gate: true` in Plan (the T24 frontmatter contract), AND the design.md MUST record the lift-verbatim-vs-re-derive decision so downstream Structure (T25) and the visual-fidelity reviewer (T28) can ground their decisions in the recorded judgment. Both edits are markdown body only in two skill files; lightweight/sonnet classification holds.
- **Test expectations:**
  - `skills/reviewer-protocol/SKILL.md` contains a quick-tier finding-disposition section codifying inline-patch for high-severity and correctness-medium findings, acceptance for low-severity findings, and prohibition of blanket quick-tier merges.
  - The quick-tier section is reachable via the standard section-anchor convention so the shared markdown helper can extract it.
  - `skills/design/SKILL.md` contains a checklist item asserting that designs introducing reference-dependent reviewers flag the producing task `reference_gate: true` in Plan.
  - The Design-skill checklist item asserts that `design.md` records the lift-verbatim-vs-re-derive decision.
---
task_id: 30
task_type: code
model: opus
phase: 1
goal_ids: [G10, G11, G14]
dependencies: [T13, T24, T25, T26, T27, T28, T29]
loc_estimate: 250
sizing_exception: reusable primitives
---

### Task 30: Add five Slice 5 BATS pins for reference-gate-fields, ui-task-fields, wave-context-shape, quick-tier-wording, and reference-gate-pause
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-reference-gate-fields.bats` (Create) — paired-field contract pin: `reference_gate: true` requires `reference_artifact:`; image artifact triggers user-visible attachment (not path-only).
  - `tests/unit/test-ui-task-fields.bats` (Create) — UI-glob auto-detection sets `ui: true`; `lift_source:` requires `SPEC OVERRIDES SOURCE` section; visual-fidelity reviewer dispatched on `ui: true`. Uses `skill-markdown.bash`.
  - `tests/unit/test-wave-context-shape.bats` (Create) — `wave_context:` payload contains wave identifier + per-task entries (task ID, task name, `allowed_files` glob, sibling findings) wrapped between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers.
  - `tests/unit/test-quick-tier-wording.bats` (Create) — `skills/reviewer-protocol/SKILL.md` contains codified quick-tier patch-vs-accept guidance. Uses `skill-markdown.bash`.
  - `tests/integration/test-reference-gate-pause.bats` (Create) — reference-gated task ending wave pauses dependents until approval recorded under `reviews/tasks/task-NN/reference-gate.md`; bypass attempt blocked.
- **Dependencies:** T13, T24, T25, T26, T27, T28, T29
- **LOC estimate:** ~250
- **Sizing exception:** reusable primitives — the five pins co-ship as the Slice 5 contract-lock; splitting them would leave the reference-gate-fields, ui-task-fields, wave-context-shape, quick-tier-wording, and reference-gate-pause contracts unobserved independently.
- **Description:** Ships the five BATS pins that lock Slice 5's contracts into the test harness. Pin one (reference-gate-fields, G10) asserts T24's paired-field contract: a fixture task spec carrying `reference_gate: true` MUST carry a matching `reference_artifact: <path>`; a fixture spec with `reference_gate: true` and no `reference_artifact:` is rejected by the Plan orchestrator with the named diagnostic; a fixture with an image `reference_artifact:` (e.g., `.png`) triggers a user-visible attachment render (not a path-only display) at the gate pause. Pin two (ui-task-fields, G11+G14) loads the shared `skill-markdown.bash` helper from T13 and asserts T24's UI-field contract: a fixture task spec whose target files match the UI glob auto-receives `ui: true`; a spec carrying `lift_source: <path>` without a `SPEC OVERRIDES SOURCE` body section is rejected with the named diagnostic; a `ui: true` task dispatches the visual-fidelity reviewer per T27 (`qrspi-visual-fidelity-reviewer` appears in the per-task reviewer set with reviewer_tag `visual-fidelity-claude`). Pin three (wave-context-shape, G11) asserts T27's `wave_context:` companion shape: a fixture wave-2 dispatch on a UI task carries a `wave_context:` companion whose body is wrapped between the canonical `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers and contains the wave identifier plus per-task entries each showing task ID, task name, `allowed_files` glob, and earlier-wave sibling findings. Pin four (quick-tier-wording, G11+G14) loads `skill-markdown.bash` and asserts T29's reviewer-protocol edit: `skills/reviewer-protocol/SKILL.md` contains the codified quick-tier finding-disposition guidance (inline-patch high and correctness-medium, accept low, prohibit blanket merges) reachable via the standard section-anchor convention. Pin five (reference-gate-pause integration, G10) is the integration-tier pin that exercises the cross-skill flow end-to-end against a seeded fixture plan: a reference-gated task (carrying T24's `reference_gate: true`) ends its wave per T26's Parallelize wave-termination rule; per T27's Implement pause behavior, dependents do not dispatch until the approval file is recorded at `reviews/tasks/task-NN/reference-gate.md`; a bypass attempt that dispatches a dependent before the approval file exists is blocked with a named diagnostic. The pin count (5) and the integration-tier pin (a real cross-skill exercise rather than a markdown-section assertion) drive the opus classification, with a ~250 LOC estimate (roughly proportional to the five behaviors covered) declared in the frontmatter.
- **Test expectations:**
  - reference-gate-fields pin asserts the paired-field contract: `reference_gate: true` requires `reference_artifact:`, with rejection of the unpaired fixture and image-artifact user-visible attachment rendering. The pin also exercises the path-traversal rejection case: a fixture task spec carrying `reference_artifact: ../../../../etc/shadow` (or any path that resolves outside the artifact-directory tree) is rejected before any render or Read call, with a named path-validation diagnostic. The pin additionally exercises the out-of-tree `sibling_allowed_paths:` rejection case from T27: a fixture task spec carrying a `sibling_allowed_paths:` entry that resolves outside both the artifact-directory tree AND the project's worktree root (e.g., `sibling_allowed_paths: ["/etc"]`) is rejected with a named sibling-allowed-path-validation diagnostic before the `reference_artifact:` resolution is attempted, and no render or Read call occurs against any path declared by the unsafe sibling-allowed entry.
  - ui-task-fields pin asserts UI-glob auto-detection of `ui: true`, the `lift_source:` + `SPEC OVERRIDES SOURCE` body-section requirement, and visual-fidelity reviewer dispatch on `ui: true` — using `skill-markdown.bash`.
  - wave-context-shape pin asserts the `wave_context:` companion payload carries the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, sibling findings) wrapped between the canonical untrusted-data markers, AND a sentinel-collision fixture (a sibling finding body containing a literal `<<<UNTRUSTED-ARTIFACT-START` or `<<<UNTRUSTED-ARTIFACT-END` token) exercises the wave_context assembly step's sanitize-or-exclude behavior so no nested sentinel reaches the outer wrapper body. The pin further asserts that when at least one finding was stripped or excluded, the assembled `wave_context:` body contains a `REDACTION-NOTICE` entry naming the source task ID, the redaction action, and the count of redacted findings — absence of the notice when a redaction occurred fails the pin.
  - quick-tier-wording pin asserts `skills/reviewer-protocol/SKILL.md` contains the codified quick-tier patch-vs-accept guidance via the shared markdown helper.
  - reference-gate-pause integration pin asserts the cross-skill flow: wave termination, dependent pause until `reviews/tasks/task-NN/reference-gate.md` exists, and bypass-attempt blocking with a named diagnostic.
---
task_id: 31
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G3]
dependencies: [T24]
loc_estimate: 110
---

### Task 31: Plan-skill post-approval split orchestration with N-threshold carve-out
- **Phase:** 1
- **Target files:**
  - `skills/plan/SKILL.md` (Modify) — add the post-approval split orchestration section that fans approved per-task spec authoring out to sub-subagents, declare the N-threshold carve-out (N >= 3 dispatches sub-subagents in parallel; N <= 2 performs the split inline in main chat), and retain the main-chat transactional steps (sub-subagent confirmation collection, file-count verification, `plan.md` overview-only rewrite, `phase_start_commit:` capture, `status: approved` write) so downstream skills never see an approved `plan.md` without corresponding `tasks/task-NN.md` files on disk.
- **Dependencies:** T24
- **LOC estimate:** ~110
- **Description:** Adds a post-approval split orchestration section to `skills/plan/SKILL.md` that replaces the current main-chat per-task spec writing with a sub-subagent fan-out reusing the generation-side dispatch shape already documented in the skill, closing the Plan post-approval split-via-subagent gap captured in qrspi-plus issue #172 and realizing design decision G3. The orchestration section declares the N-threshold carve-out explicitly: when the approved `plan.md` overview enumerates N >= 3 tasks the skill dispatches one sub-subagent per task in parallel, each consuming the merged `plan.md` task section as wrapped input plus the canonical task-file template (now carrying the Slice 5 spec frontmatter shape established by T24) plus the G7 ID-hygiene contract, and each writing exactly one `tasks/task-NN.md` file without editing `plan.md`; when N <= 2 the skill performs the split inline in main chat because sub-subagent dispatch overhead exceeds the context saving below that threshold (combined two-task plan + specs estimated at under 600 lines per design line 157). The main chat retains the transactional ordering — collect sub-subagent confirmations, verify the resulting `tasks/task-NN.md` file count matches the expected task count, rewrite `plan.md` to overview-only, capture `phase_start_commit:` in `plan.md` frontmatter, then write `status: approved` to `plan.md` frontmatter — so an approved `plan.md` is never observable on disk without all corresponding task files present. This task is the single touch on `skills/plan/SKILL.md` for Slice 6 and is co-aligned with T24 (Slice 5), which edits the same SKILL.md to add the per-task spec frontmatter shape; T24 lands first so T31's orchestration reasons over the finalized frontmatter shape carried into each sub-subagent's task-file template payload, avoiding a double-touch on the file within the same wave.
- **Test expectations:**
  - The post-approval split section in `skills/plan/SKILL.md` documents the N-threshold carve-out, stating N >= 3 triggers sub-subagent fan-out and N <= 2 triggers inline main-chat split.
  - The section enumerates the per-sub-subagent input payload (wrapped `plan.md` task section, canonical task-file template, G7 ID-hygiene contract) and the per-sub-subagent output contract (exactly one `tasks/task-NN.md` per dispatch; no `plan.md` edits).
  - The section preserves the main-chat transactional steps in order: collect confirmations, verify file count, rewrite `plan.md` to overview-only, capture `phase_start_commit:`, write `status: approved`.
  - The verification step checks the EXACT SET of `tasks/task-NN.md` files present after the fan-out — specifically that `{task-01.md, task-02.md, ..., task-N.md}` is exactly the expected set with no duplicates and no missing IDs — not only that N files exist. A duplicate-ID condition (two sub-subagents writing the same `task-NN.md`) or a missing-ID condition (gaps in the expected set) is detected and surfaces a loud diagnostic naming the duplicated or missing IDs, aborting the split rather than proceeding with mismatched files.
  - The section states the carve-out rationale (sub-subagent overhead exceeds context saving below N=3) so the threshold is defensible against future tuning.
  - The orchestration section reuses the generation-side sub-subagent dispatch shape already declared elsewhere in `skills/plan/SKILL.md` rather than introducing a parallel dispatch grammar.
  - The Slice 5 spec frontmatter fields introduced by T24 (`reference_gate:`, `reference_artifact:`, `ui:`, `lift_source:`) appear in the canonical task-file template carried into each sub-subagent payload so the post-approval split emits frontmatter-complete `tasks/task-NN.md` files.
  - When a task spec carries `conditional: true` and a `conditional_precondition:` value (the T43 conditional-dispatch fields documented in the `## Task Specs` preamble), the sub-subagent payload template includes both fields verbatim and the emitted `tasks/task-NN.md` file carries both fields verbatim in its frontmatter so the Implement orchestrator can evaluate the precondition at dispatch time.
---
task_id: 32
task_type: code
model: sonnet
phase: 1
goal_ids: [G3]
dependencies: [T13, T31]
loc_estimate: 150
---

### Task 32: Formal post-approval split sub-subagent contract document and BATS pin
- **Phase:** 1
- **Target files:**
  - `skills/plan/post-approval-split-contract.md` (Create) — author the formal per-sub-subagent input/output contract document referenced by the T31 orchestration section, declaring the wrapped task-section payload shape, the canonical task-file template the sub-subagent populates, the G7 ID-hygiene contract the sub-subagent honors, the output file naming convention (`tasks/task-NN.md` exactly one per dispatch), the prohibition on editing `plan.md` from within a sub-subagent, and the atomicity contract for partial returns (a failed or non-returning sub-subagent leaves `plan.md` unapproved and the main chat aborts the split with a loud diagnostic).
  - `tests/unit/test-plan-post-approval-split.bats` (Create) — pin observing the split orchestration shape declared by T31 plus this contract document: verifies the N-threshold carve-out at N=2 (inline split) and N=3 (sub-subagent fan-out), confirms the sub-subagent prompt template shape includes the wrapped task section + canonical template + ID-hygiene contract, confirms each dispatch yields exactly one `tasks/task-NN.md` file, confirms the atomicity contract (any sub-subagent failure leaves `plan.md` unapproved with no `tasks/task-NN.md` files retained from the failed dispatch), and confirms `phase_start_commit:` is present in `plan.md` frontmatter after a successful approval. Sources `tests/helpers/skill-markdown.bash` (T13) for H2/H3 section extraction against the new contract document and against `skills/plan/SKILL.md`.
- **Dependencies:** T13, T31
- **LOC estimate:** ~150
- **Description:** Creates `skills/plan/post-approval-split-contract.md` as the formal sub-subagent dispatch contract referenced by the T31 orchestration section, and creates `tests/unit/test-plan-post-approval-split.bats` as the canonical pin observing the post-approval split shape end-to-end. The contract document declares, in one source of truth, the per-sub-subagent input payload (wrapped `plan.md` task section, the canonical task-file template carrying the Slice 5 spec frontmatter shape established by T24, the G7 ID-hygiene contract), the per-sub-subagent output contract (exactly one `tasks/task-NN.md` per dispatch, no `plan.md` edits), the output file naming convention (`tasks/task-NN.md` where NN matches the task ID from the wrapped section), and the atomicity contract on partial returns (any sub-subagent that fails to write or returns a malformed task file causes the main chat to abort the split, leaves `plan.md` unapproved, and surfaces a loud diagnostic identifying the failed dispatch). The BATS pin observes the orchestration shape: the N <= 2 carve-out branch produces task files via inline main-chat split (boundary case N=2), the N >= 3 branch dispatches sub-subagents in parallel and yields exactly N `tasks/task-NN.md` files (boundary case N=3), the sub-subagent prompt template shape carries the contract-documented payload sections, the atomicity contract holds under a simulated sub-subagent failure (no `plan.md` approval, partial files cleaned up), and the `phase_start_commit:` frontmatter field is present in `plan.md` after a successful approval. The pin uses the shared `tests/helpers/skill-markdown.bash` library from T13 for H2/H3 section extraction against both the new contract document and against `skills/plan/SKILL.md`'s post-approval split section authored in T31.
- **Test expectations:**
  - `skills/plan/post-approval-split-contract.md` declares the per-sub-subagent input payload sections (wrapped task section, canonical task-file template, G7 ID-hygiene contract).
  - The contract document declares the per-sub-subagent output contract: exactly one `tasks/task-NN.md` per dispatch with NN matching the wrapped task ID, and prohibits the sub-subagent from editing `plan.md`.
  - The contract document declares the atomicity contract on partial returns: any sub-subagent failure leaves `plan.md` unapproved, ALL `tasks/task-NN.md` files written during the current fan-out run are removed (not only the file from the failed dispatch — partial successes are rolled back too), and a loud diagnostic identifies the failed dispatch.
  - The BATS pin asserts the N=2 boundary triggers the inline main-chat split branch and produces exactly two `tasks/task-NN.md` files.
  - The BATS pin asserts the N=3 boundary triggers the sub-subagent fan-out branch and produces exactly three `tasks/task-NN.md` files.
  - The BATS pin asserts the sub-subagent prompt template shape carries the contract-documented payload sections (wrapped task section, canonical task-file template, ID-hygiene contract) verbatim from the contract document.
  - The BATS pin asserts the atomicity contract under a simulated sub-subagent failure where one of N>=3 sub-subagents fails AFTER one or more others have already succeeded: `plan.md` retains `status: draft`, ALL `tasks/task-NN.md` files written during the current fan-out (including files from sub-subagents that succeeded before the failure) are removed leaving the task directory clean, and a diagnostic identifying the failed dispatch is surfaced.
  - The BATS pin asserts `plan.md` frontmatter contains a `phase_start_commit:` value after a successful approval.
  - The BATS pin asserts the exact-set verification with a duplicate-ID fixture: a fan-out where two sub-subagents both write `tasks/task-01.md` (and `tasks/task-03.md` is missing as a result) causes the verification step to detect the duplicate-and-missing-set mismatch, surface a loud diagnostic naming both the duplicated ID and the missing ID, abort the split, leave `plan.md` unapproved, and clean up any partial files — count-only verification (N files present) is insufficient and the pin proves the verification looks at the set, not just the count.
  - The BATS pin sources `tests/helpers/skill-markdown.bash` from T13 and uses its H2/H3 extractor to validate sections in both the new contract document and `skills/plan/SKILL.md`.
  - The BATS pin asserts conditional-field preservation: a fixture fan-out on a plan containing T43's conditional fields (`conditional: true` and `conditional_precondition: T33 spike report decision == Path B`) produces a `tasks/task-43.md` file (or the fixture equivalent) whose frontmatter contains BOTH `conditional: true` and the exact `conditional_precondition:` string unchanged from the wrapped input.
  - The BATS pin asserts that after a simulated sub-subagent failure (the atomicity scenario above), `plan.md` frontmatter does NOT contain a non-null `phase_start_commit:` value — either the field is absent or its value is `null`, confirming the transactional rollback covers all approval-state fields and not only `status:`. A draft `plan.md` carrying a mid-transaction `phase_start_commit:` SHA is an observable ambiguity the pin must detect.
---
task_id: 33
task_type: code
model: sonnet
phase: 1
goal_ids: [G4]
dependencies: [T03]
loc_estimate: 130
---

### Task 33: G4 Mechanism A cache-probe script and spike report deliverable
- **Phase:** 1
- **Target files:**
  - `scripts/g4-cache-probe.sh` (Create) — shell probe script per the `## Interfaces` `scripts/g4-cache-probe.sh` signature in `structure.md`; takes `--report-out <path>`, dispatches 3 reviewer prompts that share an identical system prefix, captures Anthropic cache-hit usage metadata (`cache_creation_input_tokens` / `cache_read_input_tokens`) from each response, and writes the spike report.
  - `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (Create) — one-page measurement report deliverable that records (a) whether `Agent({})` dispatch responses expose Anthropic cache-hit metadata, (b) the observed `cache_read_input_tokens` value on second-and-later dispatches with an identical prefix, and (c) the Path A vs Path B decision the spike resolves.
- **Dependencies:** T03
- **LOC estimate:** ~130
- **Description:** Implements the G4 Mechanism A spike — the Plan-time measurement that resolves the Mechanism-A-only Path A vs Path B sub-decision. Mechanism A (Anthropic prompt caching) ships unconditionally; the spike only determines, within Mechanism A, whether the Claude Code `Agent({})` dispatch path already caches stable prefixes automatically (Path A: instrument + measure only) or whether `cache_control` markers must be added at the Anthropic SDK boundary before measurement (Path B: Mechanism A scope expands to include marker insertion). Mechanism B (the section-anchor index landed by T34 and T35) ships independent of this spike outcome and is not gated by the result. The `scripts/g4-cache-probe.sh` script dispatches three reviewer prompts via the universal dispatcher from T03 with an identical system-prompt prefix and a varying per-dispatch tail, captures each response's usage metadata, and writes a one-page report at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`. The report records the cache-metadata exposure question (does `Agent({})` surface the Anthropic cache-hit fields at all), the observed `cache_read_input_tokens` value on the second and third dispatches, and the resulting Path A or Path B decision per the spike contract in `design.md`. The decision the spike records is consumed by T36's `test-cache-hit-rate.bats` pin (Path-conditional fixture set) and gates any follow-up `cache_control` marker-insertion task. Exit codes follow the dispatcher convention (`0` report written + decision recorded, `1` dispatch failure or report-write failure).
- **Test expectations:**
  - Invoking `scripts/g4-cache-probe.sh` without `--report-out` exits non-zero with a validation diagnostic on stderr.
  - Invoking `scripts/g4-cache-probe.sh --report-out <path>` dispatches exactly three reviewer prompts whose system-prompt prefix is byte-identical across the three calls. The "system-prompt prefix" is concretely defined as the bytes from the start of the assembled system-message body through the end of the verbatim `skills/reviewer-protocol/SKILL.md` content the probe embeds (the load-bearing stable content for the cache-hit measurement); the per-dispatch varying tail begins at the per-call reviewer-task-body section the probe appends after the stable prefix. The byte-identity assertion compares the two prefix slices using their defined byte ranges.
  - On success the script writes the report file at the `--report-out` path and exits `0`; the report body contains the three captured `cache_read_input_tokens` values and the three captured `cache_creation_input_tokens` values from the dispatched responses.
  - The report body contains an explicit Path A or Path B decision line, derived from whether the second-and-later dispatches observed `cache_read_input_tokens > 0`.
  - The report distinguishes the "no cache metadata exposed at all" outcome from the "metadata exposed but zero hits" outcome and records each as a distinct decision branch.
  - A dispatcher failure during any of the three dispatches causes the script to exit `1` with a loud diagnostic naming the failed dispatch and to NOT write a partial report.
  - The report file lives at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (the spike-deliverable location declared in `structure.md` Slice 7 file map).
  - Before applying the path-validation check, the script resolves the `--report-out` value to its canonical absolute path via `realpath` (or `cd "$(dirname "$path")" && pwd` for parent-resolution when the file does not yet exist) and applies the `docs/qrspi/` prefix check against the resolved path, not the raw argument string. A path that cannot be resolved (e.g., the parent directory does not exist) exits 1 with a named path-validation diagnostic. When the resolved `--report-out` path lies outside the declared spike-deliverable location under `docs/qrspi/`, the script exits 1 with a named path-validation diagnostic before attempting any dispatch or report write. A fixture invocation with `--report-out docs/qrspi/../../../etc/shadow` (raw argument is string-prefix `docs/qrspi/` but resolves to `/etc/shadow`) exits 1 with the path-validation diagnostic — the realpath normalization is what catches the traversal attempt that a naive string-prefix bash implementation would miss.
  - When the report file cannot be written to the `--report-out` path (parent missing, read-only filesystem, permission denied), the script exits 1 with a loud diagnostic naming the write-failure reason and does NOT exit 0 with a missing report.
  - The report header contains an explicit `run_id:` (or `invocation_timestamp:`) field that uniquely identifies the invocation that produced the report. At script start, the script removes any prior sentinel/lock file at `<report-out-dir>/g4-cache-probe.lock`; on a complete successful run, after the report is written, the script atomically creates a `g4-cache-probe.lock` file containing the same `run_id:` as the report. A mid-run failure leaves no lock file, so downstream consumers (T36) can detect a stale report by the absence of a fresh lock or a `run_id:` mismatch between report and lock, preventing T36 from silently consuming a prior-run report when the current run failed.
---
task_id: 34
task_type: code
model: opus
phase: 1
goal_ids: [G4]
dependencies: []
loc_estimate: 180
sizing_exception: reusable primitives
---

### Task 34: G4 Mechanism B three colocated section-anchor index files plus manifest
- **Phase:** 1
- **Target files:**
  - `skills/reviewer-protocol/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/reviewer-protocol/SKILL.md`; maps every H2 and H3 heading text in the source to `{line_start, line_end}` so consumers can `Read(offset, limit)` a specific section verbatim. This is the highest-traffic stable artifact (every reviewer dispatch preloads `reviewer-protocol`).
  - `skills/using-qrspi/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/using-qrspi/SKILL.md`; same `{H2|H3 heading → {line_start, line_end}}` shape. `using-qrspi` is preloaded at every skill entry; consumers Read specific subsections such as `## Compaction Checkpoints` or `## Standard Review Loop` rather than the whole file.
  - `skills/plan/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/plan/SKILL.md`; same shape. `plan/SKILL.md` is one of the longest skill files and Plan dispatches frequently Read only the post-approval split sub-section.
  - `scripts/g4-section-anchor-manifest.json` (Create) — manifest JSON enumerating the three indexed artifacts (source path plus colocated `.anchors.json` path per entry). The refresh script in T35 reads this manifest to know which artifacts to regenerate; new entries are added later by extending the manifest.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives — the three anchor index files are a shared lookup substrate consumed by every Mechanism B narrow-read site (downstream agent dispatches use `Read(offset, limit)` against the index, not the inline awk-style anchor scans); the manifest is the registry every refresh run keys off. The combined JSON volume reflects the three source artifacts' full H2/H3 surface, which is the irreducible payload for the consumer contract — splitting the indexes across tasks would fracture the primitive.
- **Description:** Ships the G4 Mechanism B section-anchor index — the narrow-read lookup substrate that lets agents Read only the section of a long stable artifact they need, with the slice byte-identical to the source. The four target files this task creates are the three colocated `.anchors.json` index files AND the new `scripts/g4-section-anchor-manifest.json` manifest that the T35 refresh script keys off; the manifest is an additional load-bearing runtime artifact this task ships even though it is not enumerated in structure.md's Slice 7 file map. This is a documented post-approval gap noted by the round-1 Plan reviewer; the gap is recorded at `reviews/plan/structure-amendment-needed.md` as a follow-up TODO for a future Structure-skill amendment cycle. The implementer of T34 is NOT required to action the amendment as part of this task — `reviews/plan/structure-amendment-needed.md` is a tracking note, not an implementation dependency — and T34 ships the manifest at the path declared above regardless of the amendment's status. Mechanism B ships unconditionally in v0.7 independent of the T33 spike outcome; the section-anchor index is the lookup substrate that Mechanism B's narrow-read consumers (Plan dispatches reading only the post-approval split sub-section, reviewers reading only the Reviewer Dispatch Contract, every skill entry reading only the Compaction Checkpoints subsection) depend on. Each `.anchors.json` file is colocated with its source (`skills/<name>/SKILL.anchors.json` sits next to `skills/<name>/SKILL.md`) per the colocation convention declared in `structure.md`'s Section-Anchor Index section spec (authored in T35). The JSON shape maps every H2 and H3 heading text from the source file to a `{line_start, line_end}` object whose values are 1-indexed inclusive line numbers; no duplicate heading text is permitted within a single artifact. The manifest at `scripts/g4-section-anchor-manifest.json` enumerates the three initial indexed artifacts so the T35 refresh script knows which sources to regenerate against; the manifest is the single registry that future Mechanism B expansions extend rather than each new index being discovered ad-hoc. The contents of each index reflect the current heading layout of the corresponding source artifact at authoring time; T35 ships the refresh tooling that keeps them in sync as the sources evolve. The three pinned consumer contracts in T36 (`test-section-anchor-index-shape`, `test-section-anchor-narrow-read`, `test-section-anchor-refresh`) observe this primitive.
- **Test expectations:**
  - `skills/reviewer-protocol/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - `skills/using-qrspi/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - `skills/plan/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - Every top-level key in each `.anchors.json` corresponds to an H2 or H3 heading text that exists in the source `SKILL.md` at the matching path.
  - Every value in each `.anchors.json` is an object with integer `line_start` and `line_end` fields satisfying `line_start <= line_end`, with both fields referring to lines within the source file's actual line count.
  - No `.anchors.json` contains two keys with the same heading text (duplicates would make narrow-read targeting ambiguous).
  - `scripts/g4-section-anchor-manifest.json` exists, parses as valid JSON, and enumerates the three indexed artifact pairs (source path + colocated index path) corresponding to the three `.anchors.json` files above.
  - For each indexed artifact, a sample narrow-read using one heading's `{line_start, line_end}` and `Read(offset=line_start, limit=line_end-line_start+1)` returns a byte-identical slice of the source artifact's corresponding line range.
---
task_id: 35
task_type: code
model: opus
phase: 1
goal_ids: [G4]
dependencies: [T34]
loc_estimate: 150
---

### Task 35: G4 Mechanism B anchor-refresh script and structure-skill Section-Anchor Index section spec
- **Phase:** 1
- **Target files:**
  - `scripts/g4-section-anchor-refresh.sh` (Create) — bash 3.2-compatible shell script that reads `scripts/g4-section-anchor-manifest.json` from T34, walks every `(source, index)` pair in the manifest, regenerates the `<source>.anchors.json` file from the source artifact's current H2/H3 heading layout, and writes the regenerated JSON to the colocated index path. Idempotent: re-running against an in-sync source produces a byte-identical index. Fail-loud on duplicate heading text within a single source artifact.
  - `skills/structure/SKILL.md` (Modify) — add a new `## Section-Anchor Index` section that documents the colocation convention (`skills/<name>/SKILL.anchors.json` sits next to `skills/<name>/SKILL.md`), the manifest's role as the single registry of indexed artifacts, the refresh ownership (the refresh script is the source-of-truth regenerator; index files are not hand-edited), and the consumer contract (an agent that wants section X of artifact Y looks up the range from `<artifact>.anchors.json`, then uses `Read(offset, limit)` to fetch the slice verbatim).
- **Dependencies:** T34
- **LOC estimate:** ~150
- **Description:** Ships the G4 Mechanism B refresh tooling and the Structure-skill section spec that documents the Mechanism B contract for consumers. Mechanism B ships unconditionally in v0.7 independent of the T33 spike outcome; this task closes the Mechanism B substrate by providing the regeneration tool that keeps the T34 anchor indexes in sync with their sources as the sources evolve, and by anchoring the consumer contract in the Structure skill body so downstream skill authors and reviewers can verify Mechanism B sites at design time rather than discovering the index shape ad-hoc. The `scripts/g4-section-anchor-refresh.sh` script reads `scripts/g4-section-anchor-manifest.json` (authored in T34), iterates over each `(source, index)` entry, extracts every H2 and H3 heading text from the source artifact together with the `{line_start, line_end}` range each heading spans (where the range ends at the line immediately before the next same-or-higher-level heading), and writes the resulting `{heading_text → {line_start, line_end}}` JSON object to the colocated index path. The script is idempotent — a second invocation against an in-sync corpus produces byte-identical indexes — and fails loud with a named diagnostic if any single source artifact contains two H2 or H3 headings whose text is identical (duplicates would make narrow-read targeting ambiguous). The new `## Section-Anchor Index` section in `skills/structure/SKILL.md` documents: (1) the colocation convention so future indexed artifacts ship their index alongside the source; (2) the manifest as the single registry that gates which artifacts the refresh script regenerates; (3) refresh ownership — index files are regenerator output, not hand-authored; (4) the consumer contract — agents Read the slice via index lookup + `Read(offset, limit)`, not by re-scanning the source for headings. The contract surfaces in T36's `test-section-anchor-refresh.bats` pin (regenerated index reflects current heading layout after a source heading is added, removed, or renamed).
- **Test expectations:**
  - Running `scripts/g4-section-anchor-refresh.sh` against the manifest from T34 produces three regenerated `.anchors.json` files at the colocated paths.
  - The regenerated index for each indexed artifact contains exactly the H2 and H3 heading texts present in the corresponding source artifact at refresh time.
  - Each regenerated index entry's `{line_start, line_end}` matches the actual line span of the heading in the source artifact (line_end is the line before the next same-or-higher-level heading, or the last line of the source for the final section).
  - A second invocation of the refresh script against an unchanged source corpus produces byte-identical index files (idempotency).
  - Adding a new H2 heading to a source artifact and re-running the script produces an index containing the new heading; removing a heading and re-running produces an index without the removed entry; renaming a heading replaces the old key with the new key.
  - A source artifact containing two H2 or H3 headings with identical text causes the script to exit non-zero with a loud diagnostic naming the offending artifact, the duplicate heading text, and the line numbers of the collision, without writing a partial or corrupt index.
  - `skills/structure/SKILL.md` contains a new `## Section-Anchor Index` H2 section that documents the colocation convention, the manifest registry, the refresh ownership rule (regenerated, not hand-edited), and the consumer contract (index lookup + `Read(offset, limit)` for byte-identical slices).
  - Running the refresh script when `scripts/g4-section-anchor-manifest.json` is absent exits non-zero with a loud diagnostic naming the missing manifest file (no silent skip).
  - Running the refresh script when the manifest JSON is malformed exits non-zero with a loud diagnostic naming the manifest file and the parse error.
  - Running the refresh script when a manifest entry's source path does not exist exits non-zero with a loud diagnostic naming the missing source path and the manifest entry that referenced it.
---
task_id: 36
task_type: code
model: opus
phase: 1
goal_ids: [G4]
dependencies: [T13, T33, T34, T35]
loc_estimate: 200
---

### Task 36: Slice 7 G4 unit pins — cache-hit-rate, cache-control-capability-gate, section-anchor-index-shape, section-anchor-narrow-read, section-anchor-refresh
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-cache-hit-rate.bats` (Create) — observes Mechanism A. Path-conditional: Path A produces verification-only assertions (`cache_read_input_tokens > 0` on second-and-later dispatches with an identical system-prefix at flagged dispatch sites); Path B produces add-then-verify assertions (cache_control markers are present in the assembled JSON request body for providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` (the dual-flag gate), AND the hit-rate assertion holds after the config flags are set). The path the test runs is read from the spike report deliverable from T33.
  - `tests/unit/test-cache-control-capability-gate.bats` (Create) — observes Mechanism A. Exercises the dual-flag emission gate by dispatching through the T03 dispatcher against fixtures for all four cells of `supports_prompt_cache:` × `emit_cache_control_markers:`; the request body contains `cache_control` only in the (true, true) cell.
  - `tests/unit/test-section-anchor-index-shape.bats` (Create) — observes Mechanism B. For each `.anchors.json` from T34 (reviewer-protocol, using-qrspi, plan), asserts: file parses as JSON; every key is an H2 or H3 heading text present in the source SKILL.md; every value is `{line_start, line_end}` with integer fields satisfying `line_start <= line_end`; no duplicate heading text within one artifact.
  - `tests/unit/test-section-anchor-narrow-read.bats` (Create) — observes Mechanism B. For each indexed artifact, fetches a section via `Read(offset=line_start, limit=line_end-line_start+1)` driven by the `.anchors.json` lookup; asserts the assembled slice is BYTE-IDENTICAL to the corresponding source slice per the design line-237 contract.
  - `tests/unit/test-section-anchor-refresh.bats` (Create) — observes Mechanism B. After running `scripts/g4-section-anchor-refresh.sh` (T35) against a fixture corpus where a heading has been added, removed, and renamed, the regenerated indexes reflect each change; a duplicate-heading fixture causes the script to exit non-zero with a loud diagnostic.
- **Dependencies:** T13, T33, T34, T35
- **LOC estimate:** ~200
- **Description:** Pins the Slice 7 G4 observable behaviors with five BATS unit tests that together observe BOTH G4 mechanisms. The two Mechanism A pins (`test-cache-hit-rate.bats` and `test-cache-control-capability-gate.bats`) observe prompt caching: `test-cache-hit-rate.bats` is path-conditional and reads the T33 spike-report deliverable to choose between Path A verification-only fixtures (the Claude Code Agent-tool dispatch path already caches automatically; the test asserts `cache_read_input_tokens > 0` on second-and-later identical-prefix dispatches at flagged sites) and Path B add-then-verify fixtures (cache_control markers are activated at providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` (the dual-flag gate); the test then asserts both marker presence in the assembled JSON request body and the same hit-rate condition); `test-cache-control-capability-gate.bats` observes the dual-flag emission gate where the T03 universal dispatcher reads each provider's `supports_prompt_cache:` AND `emit_cache_control_markers:` flags and emits `cache_control` only when BOTH flags are true. The three Mechanism B pins observe the section-anchor index landed by T34 and T35: `test-section-anchor-index-shape.bats` asserts the JSON contract on each of the three indexes (valid JSON, key is real H2/H3 heading text, value is well-ordered `{line_start, line_end}`, no duplicates); `test-section-anchor-narrow-read.bats` asserts the byte-identical-slice contract per design line 237 (the consumer reads `Read(offset, limit)` driven by the index and the slice matches the source slice byte-for-byte); `test-section-anchor-refresh.bats` asserts the T35 refresh-script contract against a fixture corpus that exercises added / removed / renamed headings plus the duplicate-heading fail-loud branch. All five files load `tests/helpers/skill-markdown.bash` (T13) where appropriate for shared section-extraction utilities and `require_repo_root` resolution. Mechanism A and Mechanism B are independent unconditional ships per the design two-axes framing; this task pins both.
- **Test expectations:**
  - `tests/unit/test-cache-hit-rate.bats` reads the T33 spike-report deliverable to determine the Path A vs Path B branch and runs the corresponding fixture set; on Path A it asserts `cache_read_input_tokens > 0` on second-and-later dispatches with an identical system prefix at flagged dispatch sites; on Path B it asserts both cache_control marker presence (under the dual-flag gate) AND the same hit-rate condition. Path B asserts the `cache_control` field (value `{type: "ephemeral"}`) appears on the stable-prefix message block of the assembled JSON request body ONLY for providers whose config carries BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` — at the flagged reviewer-dispatch sites enumerated in the T33 spike report's Path B decision body (not "all dispatch sites"). The pin also asserts the contrapositive: providers with `emit_cache_control_markers: false` (the default state) receive NO `cache_control` field even on Path B, demonstrating that T43's Path B activation works by toggling the new config flag on the specific Anthropic provider entries rather than by changing dispatcher behavior unconditionally.
  - When the T33 spike-report deliverable is absent, malformed, or does not contain a recognizable Path A or Path B decision line, `test-cache-hit-rate.bats` fails with a loud diagnostic naming the missing/malformed prerequisite and does NOT silently default to either path.
  - `test-cache-hit-rate.bats` further asserts spike-report freshness by reading the report's `run_id:` header field and comparing it against the `run_id:` in the colocated `g4-cache-probe.lock` sentinel file T33 creates atomically only after a complete successful run. When the lock file is absent, or when the report's `run_id:` does not match the lock's `run_id:`, the pin fails with a loud diagnostic identifying the stale-report condition rather than silently consuming a prior-run report. The pin also exercises the malformed-lock case alongside the absent-lock and run_id-mismatch fixtures: when the `g4-cache-probe.lock` file exists but its content cannot be parsed to extract a `run_id:` value (empty, whitespace-only, binary/truncated, or no line matching the `run_id:` key pattern), the pin fails with a loud diagnostic naming the malformed-lock condition (distinct from the absent-lock and stale-report diagnostics).
  - `tests/unit/test-cache-control-capability-gate.bats` invokes the T03 universal dispatcher against fixture providers exercising all four cells of the dual-flag truth table (`supports_prompt_cache:` × `emit_cache_control_markers:`): (a) (false, false), (b) (true, false), (c) (false, true), (d) (true, true) and asserts the request body contains `cache_control` ONLY in cell (d). All four fixture providers use `transport_type: openai-chat-completions` so the dispatcher assembles a chat-completions JSON request body that the pin can observe directly — the pin does NOT exercise `transport_type: codex-broker` because broker transport defers JSON assembly to the broker subprocess and would make the request-body assertion vacuous. Cells (a), (b), (c) all produce a request body with no `cache_control` field — preserving both the capability gate (no markers to providers without prompt-cache support, regardless of the emission flag) and the emission gate (no markers by default even when the provider supports caching, preserving T33 spike measurement integrity).
  - `tests/unit/test-section-anchor-index-shape.bats` runs against each `.anchors.json` from T34 and asserts: valid JSON parse; every top-level key matches an H2 or H3 heading text present in the corresponding source SKILL.md; every value is an object with integer `line_start` and `line_end` satisfying `line_start <= line_end`; no two keys within one file share the same heading text.
  - `tests/unit/test-section-anchor-narrow-read.bats` for each indexed artifact exercises at least three sample headings — one near the start of the artifact (small `line_start`), one from the middle of the artifact, and one at the FINAL section (where `line_end` equals the artifact's last line, not the line before a following same-or-higher heading) — fetches each heading's `{line_start, line_end}` from the corresponding `.anchors.json`, performs `Read(offset=line_start, limit=line_end-line_start+1)` against the source, and asserts each returned slice is byte-identical to the corresponding source line range. The final-section boundary case is required because an off-by-one in the `line_end` computation could cause a heading at the last H2 to return one extra line from the next artifact boundary or omit the final line — a single-sample test would not detect that bug.
  - For at least one indexed artifact, the pin exercises an H2 heading whose indexed `{line_start, line_end}` span includes at least one nested H3 sub-heading, and asserts the returned slice (via `Read(offset, limit)`) is byte-identical to the full H2 section INCLUDING its nested H3 children — confirming that `line_end` is bounded by the NEXT same-or-higher-level heading (another H2 or the file end), not by the first H3. The actual production indexes from T34 (`reviewer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, `plan/SKILL.md`) all contain H2s with nested H3s, so a regression that truncates H2 spans at the first H3 child would silently corrupt the narrow-read contract; this assertion guards against that.
  - `tests/unit/test-section-anchor-refresh.bats` against a fixture corpus where one source has a new heading added, one has a heading removed, and one has a heading renamed, runs `scripts/g4-section-anchor-refresh.sh` and asserts each regenerated index reflects the corresponding change (new key present, removed key absent, renamed key replacing the prior key with the same `{line_start, line_end}` shape).
  - `tests/unit/test-section-anchor-refresh.bats` against a fixture source containing two H2 headings with identical text asserts the script exits non-zero, emits a diagnostic naming the duplicate heading text and the colliding line numbers on stderr, and does not write a partial index file.
  - All five files load `tests/helpers/skill-markdown.bash` via `load 'helpers/skill-markdown'` where shared helpers (section extraction, `require_repo_root`) are used.
  - All five files run green under the unit BATS suite, including under the bash 3.2 runtime from the T14 CI workflow's `bash32` job.
---
task_id: 37
task_type: code
model: sonnet
phase: 1
goal_ids: [G4]
dependencies: [T13]
loc_estimate: 80
---

### Task 37: G4 cross-cutting rejection-of-summary-shims invariant pin
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-no-summary-shim-dispatches.bats` (Create) — repo-wide code-search BATS pin that asserts no agent dispatch site feeds an LLM-generated summary of a stable artifact back into a downstream prompt as source-of-truth. Loads `tests/helpers/skill-markdown.bash` (T13) for `require_repo_root` and shared diagnostics; scans `skills/**/SKILL.md` and `agents/qrspi-*.md` for dispatch-prompt shapes that would substitute a derived summary for a verbatim Read or for a Mechanism B index-driven narrow Read.
- **Dependencies:** T13
- **LOC estimate:** ~80
- **Description:** Pins the cross-cutting G4 rejection-of-summary-shims invariant per `design.md` lines 219 and 238 — the rule that summary-shim mechanisms (LLM-generated condensations consumed as prompt source-of-truth in place of the original artifact) are explicitly rejected by the design, in contrast to Mechanism A (prompt caching, which preserves verbatim content) and Mechanism B (the section-anchor index, which slices verbatim content). The test is a code-search assertion against the QRSPI dispatch surface: it walks every skill body (`skills/**/SKILL.md`) and every QRSPI agent body (`agents/qrspi-*.md`) and asserts no dispatch site composes a prompt whose source-of-truth payload is a derived-summary artifact substituted for the corresponding stable source artifact (e.g., a dispatch that injects `<summary-of reviewer-protocol.md>` into a reviewer's prompt body rather than the actual `reviewer-protocol/SKILL.md` content or a verbatim index-driven slice of it). The pin is cross-cutting because the invariant spans every dispatch site rather than any one Mechanism A or Mechanism B surface — it catches regressions where a future skill author reaches for the rejected third mechanism (the summary shim) instead of either of the two unconditionally-accepted mechanisms. The test uses `tests/helpers/skill-markdown.bash` for the shared `require_repo_root` resolution and shared diagnostic shape; it fails loud with the offending file path, dispatch-site context, and the matched summary-shim shape when an introduction is detected.
- **Test expectations:**
  - The test walks every file matching `skills/**/SKILL.md` and `agents/qrspi-*.md` from the resolved `REPO_ROOT`.
  - For each file the test asserts no dispatch-prompt construction substitutes a derived-summary artifact for the corresponding stable source artifact as the prompt's source-of-truth payload.
  - When a fixture introduces a summary-shim dispatch shape (e.g., a dispatch site that composes its prompt around an LLM-generated condensation of `reviewer-protocol/SKILL.md` and feeds that condensation as the reviewer's source-of-truth body), the test fails with a diagnostic naming the offending file, the line range of the dispatch site, and the matched summary-shim shape.
  - The test loads `tests/helpers/skill-markdown.bash` via `load 'helpers/skill-markdown'` and uses `require_repo_root` for repo-root resolution.
  - The test does NOT flag verbatim Read sites (full-file Reads) or Mechanism B index-driven narrow Reads against `.anchors.json` from T34 — both deliver verbatim content and are explicitly outside the rejected category.
  - The test does NOT flag human-facing digest surfaces (summaries presented to a reader rather than fed back into an agent dispatch as source-of-truth) — the rejection scope is dispatch-prompt source-of-truth payloads only, per the design line-219 carve-out.
  - The test runs green under the unit BATS suite against the current dispatch surface.
  - The test runs green under the bash 3.2 runtime from the T14 CI workflow's `bash32` job.
  - The detection pattern distinguishes summary-shim dispatch sites (where a derived condensation of a stable artifact is substituted as the prompt source-of-truth in place of the original artifact) from the two accepted mechanisms. The literal detection algorithm — the specific regex(es), token forms, and grep/awk commands used to classify a dispatch site — is authored in the BATS file itself (Implement-TDD), not in this task spec. Plan declares the behavioral boundary in plain language; the falsifiability anchor is concrete fixtures the pin exercises. The three exclusion categories (Plan OWNS the boundary statements): (1) **verbatim Reads excluded** — a dispatch site that Reads the full body of the stable artifact and feeds the verbatim content into the prompt is not a summary-shim. (2) **Mechanism B narrow-read sites excluded** — a dispatch site that consults a section-anchor index (`.anchors.json` from T34) and Reads a narrow line-range slice that is byte-identical to the source slice is not a summary-shim, because the slice preserves verbatim content. (3) **Human-facing digest surfaces excluded** — a summary surfaced to a human reader (e.g., a `## Summary` body for user presentation) is not a summary-shim, because the rejection scope is dispatch-prompt source-of-truth payloads only, per the design line-219 carve-out. The pin's falsifiability is exercised by three behavioral fixtures: a positive fixture (a synthesized summary-shim dispatch site) causes the pin to fail; a verbatim-Read fixture does NOT cause the pin to fail; a Mechanism B narrow-read fixture does NOT cause the pin to fail.
---
task_id: 38
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G12]
dependencies: [T15]
loc_estimate: 80
---

### Task 38: Codify the three commit-hygiene invariants in implementer-protocol so the commit cycle structurally cannot leak the commit-message scratch file
- **Phase:** 1
- **Target files:**
  - `skills/implementer-protocol/SKILL.md` (Modify) — append a `## Commit hygiene invariants` section that declares the three architectural invariants (staging-before-scratch, cleanup-after-commit, worktree-local-exclude) the implementer commit cycle must satisfy, sitting alongside the combined `## Hygiene contract` section authored in Task 15.
- **Dependencies:** T15
- **LOC estimate:** ~80
- **Description:** Adds the three commit-hygiene invariants to `skills/implementer-protocol/SKILL.md` as architectural invariants the implementer commit cycle must satisfy across every commit it produces, eliminating the recurring v0.6 regression where implementers accidentally committed their `.qrspi-commit-msg.txt` scratch file. The new `## Commit hygiene invariants` section declares exactly three invariants and frames them as load-bearing properties the procedure must hold rather than as a literal step-by-step command sequence (the procedure that realizes them is owned by `skills/implement/SKILL.md` and Plan-authored task specs per design G12). Invariant 1 — staging-before-scratch: the staging operation for a commit cycle completes before the commit-message scratch file is written to the worktree, so the scratch file does not exist on disk when staging runs and therefore cannot be accidentally included in that commit. Invariant 2 — cleanup-after-commit: the scratch file is removed after the commit completes and before any subsequent staging cycle begins, so even when the worktree-local exclude is absent (for example, in a worktree set up by a non-QRSPI mechanism), the next staging cycle finds no stale scratch file to include. Invariant 3 — worktree-local-exclude: the scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup independently of any per-commit ordering, so `git status` reports remain deterministic between scratch-file write and removal and the target repo's committed `.gitignore` is not polluted with QRSPI internals. The section states explicitly that these three invariants compose — any one alone is fragile — and that the file-based commit-message convention (`git commit -F <scratch>`) is preserved unchanged, honoring the user's global Bash convention against heredocs. The section does not enumerate the literal git command order, does not reauthor the existing pre-DONE self-check from Task 15's `## Hygiene contract` section, and does not duplicate the procedural prose owned by `skills/implement/SKILL.md` — it declares the invariants the procedure must satisfy and points downstream consumers to those sites for the realization details.
- **Test expectations:**
  - The `## Commit hygiene invariants` section exists in `skills/implementer-protocol/SKILL.md` and is positioned alongside (not inside) the combined `## Hygiene contract` section authored in Task 15.
  - The section enumerates exactly three invariants, each named (staging-before-scratch, cleanup-after-commit, worktree-local-exclude) and each stated as an architectural property the implementer commit cycle must satisfy.
  - The staging-before-scratch invariant states that the staging operation completes before the commit-message scratch file is written to the worktree, with the implication that the scratch file cannot be accidentally included in that commit.
  - The cleanup-after-commit invariant states that the scratch file is removed after the commit completes and before any subsequent staging cycle begins, with the implication that a missing worktree-local exclude still cannot strand a stale scratch file for inclusion.
  - The worktree-local-exclude invariant states that the scratch file path is excluded via the worktree-local `.git/info/exclude` entry added during worktree setup independently of any per-commit ordering, with the implication that the target repo's committed `.gitignore` is not polluted with QRSPI internals.
  - The section states explicitly that the three invariants compose and that any one alone is fragile.
  - The section preserves the file-based commit-message convention (`git commit -F <scratch>`) without introducing heredoc-based commit-message authoring.
  - The section does not enumerate the literal git command order and does not duplicate the procedural prose owned by `skills/implement/SKILL.md`.
---
task_id: 39
task_type: code
model: opus
phase: 1
goal_ids: [G12]
dependencies: [T13, T38]
loc_estimate: 120
---

### Task 39: Implement-skill worktree-setup appends scratch path to worktree-local exclude and a BATS pin asserts the three commit-hygiene invariants hold across a representative implementer commit cycle
- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — extend the per-task worktree-setup step so that during worktree creation it appends `.qrspi-commit-msg.txt` to `<worktree>/.git/info/exclude`, independent of any per-commit ordering, satisfying the worktree-local-exclude invariant declared in Task 38's `skills/implementer-protocol/SKILL.md` section.
  - `tests/unit/test-commit-hygiene-invariants.bats` (Create) — author the BATS pin that simulates a representative implementer commit cycle against a fixture worktree and asserts the three commit-hygiene invariants from Task 38 observably hold (scratch file absent from any committed tree, `.git/info/exclude` carries the entry after worktree setup, scratch file absent from the worktree after the cycle completes, file-based commit-message mechanism used rather than heredoc, and the cleanup invariant still holds when the worktree-local exclude is artificially emptied).
- **Dependencies:** T13, T38
- **LOC estimate:** ~120
- **Description:** Realizes the worktree-local-exclude invariant from Task 38 inside `skills/implement/SKILL.md`'s worktree-setup step and pins all three commit-hygiene invariants with a BATS test that exercises a representative implementer commit cycle end-to-end. The `skills/implement/SKILL.md` edit extends the existing worktree-setup step so that, during per-task worktree creation, the orchestrator appends the line `.qrspi-commit-msg.txt` to the new worktree's `<worktree>/.git/info/exclude` file (creating the file if it does not exist). This append is independent of any per-commit ordering — it happens once at worktree creation time and is the structural defense that satisfies the worktree-local-exclude invariant for every commit cycle the implementer runs in that worktree, including the first one. The edit preserves the file-based commit-message convention (`git commit -F <scratch>`) unchanged and does not reorder existing per-commit steps; the staging-before-scratch and cleanup-after-commit invariants are realized by the existing commit procedure prose, which Task 38 already declared as the load-bearing surface. The BATS pin at `tests/unit/test-commit-hygiene-invariants.bats` constructs a fixture git worktree set up the same way Implement sets up implementer worktrees, runs a representative implementer commit cycle against it (write scratch file, `git add -A`, `git commit -F <scratch>`, cleanup), and asserts five observable properties that together prove the three invariants hold. The pin asserts that no committed tree in the cycle contains the `.qrspi-commit-msg.txt` blob (staging-before-scratch invariant observably held); that `<worktree>/.git/info/exclude` carries the `.qrspi-commit-msg.txt` entry immediately after worktree setup (worktree-local-exclude invariant observably held); that the scratch file is absent from the worktree after the cycle completes (cleanup-after-commit invariant observably held); that the commit was authored via `git commit -F <scratch>` (file-based commit-message convention preserved, no heredoc); and that with the worktree-local exclude artificially emptied between cycles, a subsequent staging cycle still finds no stale scratch file (cleanup-after-commit invariant remains load-bearing on its own when the worktree-local exclude is absent). The pin runs under the unit BATS surface so the Slice 3 `bash32` job executes it.
- **Test expectations:**
  - The worktree-setup step in `skills/implement/SKILL.md` instructs the orchestrator to append `.qrspi-commit-msg.txt` to `<worktree>/.git/info/exclude` during per-task worktree creation, creating the file when absent.
  - The append happens once at worktree creation time independent of any per-commit ordering, satisfying the worktree-local-exclude invariant for every commit cycle the implementer runs in that worktree including the first one.
  - The worktree-setup edit preserves the file-based commit-message convention (`git commit -F <scratch>`) and does not reorder the existing per-commit steps owned by `skills/implementer-protocol/SKILL.md`.
  - `tests/unit/test-commit-hygiene-invariants.bats` exists and runs under the unit BATS surface.
  - The pin constructs a fixture git worktree configured the same way Implement configures implementer worktrees and runs a representative implementer commit cycle against it.
  - The pin asserts no committed tree in the cycle contains the `.qrspi-commit-msg.txt` blob, observably proving the staging-before-scratch invariant held.
  - The pin asserts `<worktree>/.git/info/exclude` carries the `.qrspi-commit-msg.txt` entry immediately after worktree setup, observably proving the worktree-local-exclude invariant held.
  - The pin asserts the scratch file is absent from the worktree after the cycle completes, observably proving the cleanup-after-commit invariant held.
  - The pin asserts the commit was authored via `git commit -F <scratch>` rather than via heredoc, preserving the user-global file-based commit-message convention.
  - The pin asserts that with the worktree-local exclude artificially emptied between cycles, a subsequent staging cycle still finds no stale scratch file — demonstrating the cleanup-after-commit invariant remains load-bearing on its own when the worktree-local exclude is absent.
---
task_id: 40
task_type: code
model: sonnet
phase: 1
goal_ids: [G13]
dependencies: []
loc_estimate: 90
---

### Task 40: u14-lint slug-extraction logic update with confusable-prefix and genuine-integrate fixtures
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-u14-lint.bats` (Modify) — replace the current absolute-path substring match (which trips on any path whose ancestor directory happens to contain the exclusion token `integrate`) with a skill-slug extractor that derives the slug from the path segment immediately after `skills/` and compares only that slug against the exclusion list; preserve the intended failure mode so genuine `skills/integrate/` paths still trip the exclusion.
  - `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md` (Create) — confusable-prefix fixture whose path contains `integrate` as a non-skill ancestor segment (e.g. a worktree-like prefix such as `worktrees/feature-integrate-foo/skills/replan/` is the failure-mode this represents; the fixture realizes that shape by placing `skills/goals/SKILL.md` underneath `tests/fixtures/u14-worktree-confusable/`, where `u14-worktree-confusable` contains `integrate` as a non-skill ancestor segment) so the skill-slug resolves to `goals` and u14-lint MUST pass.
  - `tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md` (Create) — genuine-integrate fixture under a real `skills/integrate/` skill-directory boundary so the skill-slug resolves to `integrate` and u14-lint MUST fail, locking the intended failure mode.
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** Removes the u14-lint false positive that fires when BATS runs from a QRSPI integrate worktree (or any path whose ancestor directory happens to contain the substring `integrate`) by replacing the substring scan in `tests/unit/test-u14-lint.bats` with a skill-slug extractor anchored to the `skills/<slug>/` directory boundary, then locks the contract with two fixtures exercised in the same test run. The lint logic update derives the skill slug from the path segment immediately after `skills/` in each candidate path, compares that slug against the exclusion list, and treats a path that is not under `skills/` at all as yielding an empty slug that matches no exclusion — eliminating the worktree-path false positive while preserving the intended failure mode for in-scope files that actually live under an excluded skill slug. The confusable-prefix fixture at `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md` realizes a worktree path containing `integrate` as a NON-skill directory segment: the ancestor directory `u14-worktree-confusable` carries the substring `integrate` while the actual skill slug resolves to `goals`, and u14-lint MUST PASS for this fixture because the slug extractor compares `goals` (not the absolute path) against the exclusion list. The genuine-integrate fixture at `tests/fixtures/u14-genuine-integrate/skills/integrate/SKILL.md` realizes a genuine integrate-skill path where the slug extractor resolves the slug to `integrate`, and u14-lint MUST FAIL for this fixture so the regression test proves the exclusion still bites on genuine skill-directory matches and that the slug-extraction fix did not silently broaden the exclusion to a no-op. Both fixtures are exercised in the same test run so a single invocation of the BATS file demonstrates the contract end-to-end: false-positive eliminated AND genuine exclusion preserved.
- **Test expectations:**
  - The u14-lint test invocation exercises both fixtures in the same run: the confusable-prefix fixture path resolves to skill slug `goals` and u14-lint passes for that path, while the genuine-integrate fixture path resolves to skill slug `integrate` and u14-lint fails for that path.
  - The slug extractor derives the skill slug from the path segment immediately after `skills/` so a path containing `integrate` as a non-skill ancestor directory segment (e.g. `tests/fixtures/u14-worktree-confusable/skills/goals/SKILL.md`) resolves to a slug that does NOT match the exclusion list.
  - A path that is not under `skills/` at all yields an empty slug from the extractor and matches no exclusion (boundary case: extraction returns no false-positive match when the `skills/` segment is absent).
  - The intended failure mode is preserved: a file under a genuine `skills/integrate/` directory boundary still trips the exclusion regardless of what its ancestor directories are named.
  - The BATS file loads the two fixture trees from `tests/fixtures/u14-worktree-confusable/` and `tests/fixtures/u14-genuine-integrate/` via repo-relative paths so the test is reproducible from any worktree checkout location and does not depend on the working-directory string.
  - The replaced substring-match logic is removed (not left in as a fallback) so the false-positive cannot regress through a code path that still scans the absolute path for the exclusion token.
---
task_id: 41
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G15]
dependencies: []
loc_estimate: 100
---

### Task 41: Replan boundary-with-Goals section in skills/replan/SKILL.md and OWNS update in skills/replan/owns-defers.md
- **Phase:** 1
- **Target files:**
  - `skills/replan/SKILL.md` (Modify) — append a new `## Boundary with Goals` H2 section that codifies the Replan-side promotion contract for `future-goals.md`. The section declares: Replan promotes ONLY fully-Formal future-goals entries (entries whose frontmatter carries `id:` and `type:` AND whose body contains all three required Goals subsections `## Problem`, `## Why we care`, `## What we know so far`) into the next phase's `goals.md`; partial-Formal entries (frontmatter `id:` present but missing `type:` or missing any of the three required subsections) are SKIPPED; prose-only Idea entries are SKIPPED; Replan does NOT mint IDs, does NOT author acceptance criteria, and does NOT convert Ideas into Formal goals. The section also declares the hand-off report shape: Replan emits a per-run hand-off report that enumerates (a) each promoted Formal entry by `id:` and `title:` and (b) each skipped entry (partial-Formal or Idea) with the explicit reason for the skip (which required field or subsection was missing for partial-Formal, or "prose-only Idea" for fully informal entries). Goals retains sole authority to formalize skipped entries on a subsequent user-invoked Goals run.
  - `skills/replan/owns-defers.md` (Modify) — extend the OWNS list with an explicit "Boundary with Goals: Formal-vs-Idea schema check on `future-goals.md` entries during phase-boundary promotion, plus the hand-off report shape (promoted Formal entries enumerated; skipped partial-Formal and Idea entries enumerated with skip reason)" entry; extend the DEFERS list with an explicit "Idea formalization (minting new `id:`, assigning `type:`, authoring `## Problem` / `## Why we care` / `## What we know so far` subsections) — DEFERS to Goals on a subsequent user-invoked run" entry. The OWNS update declares this responsibility belongs to Replan (not Goals), so the Replan reviewer enforces the boundary contract via the standard SKILL ↔ owns-defers consistency check.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Codifies the Replan ↔ Goals boundary contract for v0.7 by adding a `## Boundary with Goals` section to `skills/replan/SKILL.md` and a matching OWNS/DEFERS update to `skills/replan/owns-defers.md` so the Replan reviewer enforces it. Replan promotes ONLY fully-Formal future-goals entries (entries with complete Formal-shape frontmatter — `id:`, `type:` — AND all three required Goals subsections `## Problem`, `## Why we care`, `## What we know so far`) to current-phase `goals.md`. Partial-Formal entries (entries that carry an `id:` but are missing `type:` or are missing one of the three required subsections) and prose-only Idea entries are SKIPPED with explicit acknowledgment in the hand-off report. The hand-off report enumerates both promoted Formal entries (by `id:` and `title:`) and skipped entries (with the explicit reason for the skip — which required field or subsection was missing for partial-Formal entries, or "prose-only Idea" for fully informal entries) so users can manually promote partial-Formal entries to Formal via a subsequent Goals invocation. The OWNS update declares this responsibility belongs to Replan (the Formal-vs-Idea schema check, the promotion decision, and the hand-off report shape), and the DEFERS update declares that Idea formalization (minting IDs, assigning types, authoring required subsections) belongs to Goals — keeping deliberate user-intent capture in Goals where it belongs and preventing silent scope expansion at phase boundaries. Source authority is `skills/replan/SKILL.md` (the section is the canonical boundary statement); `skills/replan/owns-defers.md` mirrors the OWNS/DEFERS so the Replan reviewer's source-of-truth pin enforces the boundary on every Replan run.
- **Test expectations:**
  - `skills/replan/SKILL.md` contains a `## Boundary with Goals` H2 section.
  - The section states Replan promotes ONLY fully-Formal `future-goals.md` entries (frontmatter `id:` + `type:` AND all three required subsections `## Problem`, `## Why we care`, `## What we know so far`) to current-phase `goals.md`.
  - The section states partial-Formal entries (have `id:` but missing `type:` or missing any of the three required subsections) are SKIPPED, not promoted.
  - The section states prose-only Idea entries are SKIPPED, not promoted.
  - The section states Replan does NOT mint IDs, does NOT author acceptance criteria, and does NOT convert Ideas into Formal goals.
  - The section declares the hand-off report shape: enumerates promoted Formal entries (by `id:` and `title:`) AND skipped entries (partial-Formal and Idea) with the explicit reason for the skip.
  - `skills/replan/owns-defers.md` OWNS list contains the Boundary-with-Goals responsibility entry (Formal-vs-Idea schema check on `future-goals.md` entries plus the hand-off report shape).
  - `skills/replan/owns-defers.md` DEFERS list contains the Idea-formalization deferral entry (minting IDs, assigning types, authoring required subsections — DEFERS to Goals).
---
task_id: 42
task_type: code
model: sonnet
phase: 1
goal_ids: [G15, G14]
dependencies: [T13, T41]
loc_estimate: 100
---

### Task 42: test-replan-boundary-with-goals BATS pin and future-goals-mixed-shape fixture
- **Phase:** 1
- **Target files:**
  - `tests/unit/test-replan-boundary-with-goals.bats` (Create) — BATS pin that exercises Replan's promotion step against the `tests/fixtures/future-goals-mixed-shape.md` fixture and asserts the Boundary-with-Goals contract authored in T41. The pin sources `tests/helpers/skill-markdown.bash` (T13) for H2/H3 section extraction against `skills/replan/SKILL.md`'s new `## Boundary with Goals` section and against `skills/replan/owns-defers.md`'s OWNS / DEFERS sections. The pin asserts: (a) only the fully-Formal fixture entry is promoted to next-phase `goals.md`; (b) the partial-Formal entry (carries `id:` but missing `## What we know so far` subsection) is NOT promoted; (c) the prose-only Idea entry is NOT promoted; (d) the hand-off report enumerates the one promoted Formal entry by `id:` and `title:`; (e) the hand-off report enumerates the partial-Formal entry as skipped with the explicit reason naming the missing required subsection (`## What we know so far`); (f) the hand-off report enumerates the prose-only Idea entry as skipped with the explicit reason "prose-only Idea". The pin also asserts (via `skill-markdown.bash`'s extract-and-grep wrapper) that the Boundary-with-Goals section in `skills/replan/SKILL.md` declares the promotion-only-of-Formal-entries rule and the hand-off report shape.
  - `tests/fixtures/future-goals-mixed-shape.md` (Create) — mixed-shape `future-goals.md` fixture carrying exactly three entries: (1) one fully-Formal entry with frontmatter `id:` and `type:` set, body containing all three required subsections (`## Problem`, `## Why we care`, `## What we know so far`); (2) one partial-Formal entry with frontmatter `id:` set, body containing `## Problem` and `## Why we care` but MISSING `## What we know so far` (this distinguishes partial-Formal from prose-only Idea — it has structure but is incomplete); (3) one prose-only Idea entry — a single prose paragraph with no frontmatter and no `##` subsections at all. The three entries are clearly labeled so the BATS pin can address each by name and the hand-off report can be matched against expected per-entry reasons.
- **Dependencies:** T13, T41
- **LOC estimate:** ~100
- **Description:** Creates the BATS pin and the mixed-shape fixture that together enforce the Replan Boundary-with-Goals contract authored in T41 against an exercised promotion run. The fixture `tests/fixtures/future-goals-mixed-shape.md` carries three deliberately-shaped entries — one fully-Formal entry (frontmatter `id:` and `type:` plus all three required subsections `## Problem`, `## Why we care`, `## What we know so far`), one partial-Formal entry (frontmatter `id:` present but missing the `## What we know so far` subsection), and one prose-only Idea entry (a single paragraph with no frontmatter and no subsections) — so the pin can distinguish all three classifier branches from one fixture. The BATS pin asserts the promotion outcome: only the fully-Formal entry is promoted into next-phase `goals.md`; the partial-Formal entry is NOT promoted (skipped as a partial-Formal entry; the hand-off report names the missing required subsection as the skip reason); the prose-only Idea entry is NOT promoted. The pin then asserts the hand-off report shape codified in T41: the report enumerates the one promoted Formal entry by `id:` and `title:`, AND enumerates both skipped entries with explicit reasons — the partial-Formal entry is enumerated with the reason naming the missing required subsection (`## What we know so far`), and the prose-only Idea entry is enumerated with the reason "prose-only Idea". The pin sources the shared `tests/helpers/skill-markdown.bash` helper from T13 to extract and validate the `## Boundary with Goals` section in `skills/replan/SKILL.md` and the OWNS/DEFERS sections in `skills/replan/owns-defers.md`, confirming the runtime promotion behavior matches the authored contract. The pin satisfies G15 (Replan boundary enforcement under exercised promotion) and the G14 helper-consumer pattern (uses `skill-markdown.bash` for section-bounded markdown assertions rather than inlining the extractor).
- **Test expectations:**
  - The fixture `tests/fixtures/future-goals-mixed-shape.md` carries exactly three entries: one fully-Formal, one partial-Formal (frontmatter `id:` present but missing `## What we know so far` subsection), one prose-only Idea.
  - The BATS pin's promotion assertions (the fully-Formal entry is promoted; partial-Formal is NOT promoted; prose-only Idea is NOT promoted; the hand-off report enumerates promoted-by-id-and-title and per-skip reasons) are **documentation-shape assertions** against the `## Boundary with Goals` section in `skills/replan/SKILL.md` extracted via `tests/helpers/skill-markdown.bash` (skill prose is the contract surface a BATS file can observe; the Replan promotion step itself is skill-body prose for a Claude agent, not an executable script the BATS harness can invoke). The pin's BATS layer asserts that the codified contract in the skill prose names exactly the promotion outcomes and skip reasons enumerated for the fixture entries (Formal promoted, partial-Formal skipped naming `## What we know so far`, prose-only Idea skipped naming "prose-only Idea"); the runtime promotion behavior is exercised as **phase-acceptance** at Integrate time when the Replan agent actually runs against the fixture during a real phase-boundary handoff. This disambiguation closes the silent-pass risk where a runtime ignoring the contract would still pass markdown-shape BATS assertions: the pin honestly documents that the BATS surface is documentation-shape only, and the runtime behavior is gated separately at Integrate.
  - The pin sources `tests/helpers/skill-markdown.bash` (T13) and uses its H2/H3 extractor to assert the `## Boundary with Goals` section in `skills/replan/SKILL.md` declares the promotion-only-of-Formal-entries rule.
  - The pin uses the helper's extract-and-grep wrapper to assert the `## Boundary with Goals` section declares the hand-off report shape (enumerates promoted Formal entries AND skipped entries with reason).
  - The pin uses the helper to assert `skills/replan/owns-defers.md` OWNS list contains the Boundary-with-Goals responsibility entry and DEFERS list contains the Idea-formalization deferral entry.
---
task_id: 43
task_type: code
model: sonnet
phase: 1
goal_ids: [G4]
dependencies: [T33, T36]
loc_estimate: 40
conditional: true
conditional_precondition: T33 spike report decision == Path B
---

### Task 43: G4 Path B — activate cache_control marker emission on Anthropic provider config entries (conditional on T33 spike outcome)
- **Phase:** 1
- **Conditional:** This task executes ONLY if the T33 spike report at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` records a Path B decision line (the `Agent({})` dispatch path does NOT cache stable prefixes automatically). If the spike report records Path A (platform auto-caching is sufficient), T43 is a NO-OP and the implementer's terminal DONE report records `status: skipped` with the verbatim spike-decision token captured as the skip rationale. The conditional gating is evaluated by the Implement orchestrator (per the `## Task Specs` preamble `conditional:` / `conditional_precondition:` contract) by reading the recorded decision line in the T33 spike report file before the implementer dispatch begins, AND verifying the report's freshness via the `g4-cache-probe.lock` run-ID match contract established by T33 and consumed by T36.
- **Target files:**
  - `<artifact-dir>/config.md` (Modify) — for each `providers:` entry that targets an Anthropic-compatible endpoint and carries `supports_prompt_cache: true`, set the entry's `emit_cache_control_markers:` field to `true`. The exact set of provider entries flipped on Path B is enumerated in the T33 spike report's Path B decision body. No other config fields are touched.
- **Dependencies:** T33, T36
- **LOC estimate:** ~40
- **Description:** Implements G4 Mechanism A Path B per the design.md contract by activating the `emit_cache_control_markers:` config flag on the Anthropic provider entries that T33's spike measurement determined require explicit marker insertion. The dispatcher logic that EMITS `cache_control` fields is owned by T03 and is gated by the dual-flag combination (`supports_prompt_cache: true` AND `emit_cache_control_markers: true`); T43 does NOT modify `scripts/run-third-party-llm.sh`. T03 ships with `emit_cache_control_markers:` defaulting to `false` for every provider entry — this is the load-bearing default that keeps T33's spike measurement uncontaminated, since the dispatcher emits no `cache_control` fields during the probe regardless of `supports_prompt_cache:` values. T43's contribution on Path B is the one-flag-flip per provider entry that activates marker emission downstream of the measurement. Mechanism B (the section-anchor index from T34/T35) ships unconditionally and is unaffected by T43. The implementer reads the T33 spike report (with run-ID freshness verification per the T33 lock-file contract) to determine the path: on Path A, T43 is a NO-OP and the implementer's terminal DONE report records `status: skipped` with the spike-decision token as rationale; on Path B, the implementer enumerates the provider entries named in the T33 report's Path B decision body and sets `emit_cache_control_markers: true` on each. The Plan acceptance criterion for Slice 7 Path B is satisfied by T36's `test-cache-hit-rate.bats` Path B fixtures (which assert dual-flag-gated `cache_control` presence in the assembled request body) running green after T43's config edit lands.
- **Test expectations:**
  - When the T33 spike report at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` is absent at T43 dispatch time, OR is present but malformed (parse fails), OR contains no recognizable Path A / Path B decision line, the Implement orchestrator's conditional-precondition evaluation exits with a loud diagnostic naming the failure mode (missing / malformed / unparseable-decision-line) and the implementer's terminal DONE report records the failure rather than silently defaulting to either skip or implement. No edits are made to `<artifact-dir>/config.md` in the failure case.
  - When the T33 spike report exists but its `run_id:` does not match the `run_id:` recorded in the colocated `g4-cache-probe.lock` sentinel file (i.e., the report is stale per the freshness contract T33 establishes and T36 enforces), T43's conditional-precondition evaluation exits with a loud diagnostic naming the stale-report condition and the implementer's terminal DONE report records the failure. No edits are made to `<artifact-dir>/config.md` in the stale-report case.
  - When the `g4-cache-probe.lock` file exists but its content cannot be parsed to extract a `run_id:` value (e.g., the file is empty, contains only whitespace, is binary/truncated, or contains no line matching the `run_id:` key pattern), T43's conditional-precondition evaluation treats the lock as malformed, exits with a loud diagnostic naming the malformed-lock condition (distinct from the stale-report and absent-lock diagnostics), and makes no edits to `<artifact-dir>/config.md`.
  - When the T33 spike report's decision line selects Path B, the implementer dispatch sets `emit_cache_control_markers: true` on each `providers:` entry enumerated in the spike report's Path B decision body. After the edit, every named provider entry's `emit_cache_control_markers:` field is `true` (and `supports_prompt_cache: true` is preserved from T01's prior config state). Provider entries NOT named in the spike report's Path B decision body retain their default `emit_cache_control_markers: false` value — T43 does not touch unrelated entries. The implementer's terminal DONE report enumerates each flipped provider entry by name.
  - When the T33 spike report's decision line selects Path A, the implementer dispatch is short-circuited per the `conditional:` contract: no edits are made to `<artifact-dir>/config.md` and no edits are made to `scripts/run-third-party-llm.sh`. The implementer's terminal DONE report records `status: skipped` with the verbatim Path A decision token captured as rationale (so an auditor can confirm the conditional task ran and correctly chose skip, distinguishing skip-with-rationale from never-dispatched). The Slice 7 Path B acceptance bullet is satisfied vacuously per the conditional criterion language.
  - The dual-flag dispatcher behavior (T03 emits `cache_control` ONLY when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set) is verified at Path B activation time by re-running T36's `test-cache-hit-rate.bats` Path B fixtures after T43's config edit — the fixtures observe `cache_control` field presence on the assembled JSON request body's stable-prefix message block at the flipped provider entries, and observe no `cache_control` field on entries where `emit_cache_control_markers:` remains `false`. T43 itself adds no new BATS file; the contract surface is owned by T36 and by T07's dispatcher-pin truth-table coverage.
