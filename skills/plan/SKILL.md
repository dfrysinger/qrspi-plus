---
name: plan
description: Use when prior artifacts are approved and the QRSPI pipeline needs detailed task specs — breaks structure into ordered tasks with test expectations, dependencies, and LOC estimates (full pipeline requires design+structure; quick fix requires only goals+research)
---

# Plan (QRSPI Step 7)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Plan skill to create detailed task specs."

## Overview

Break the structure into ordered, self-contained tasks following vertical slices and phases from the design. Each task spec includes exact file paths, descriptions, test expectations, dependencies, and LOC estimates. Large plans (6+ tasks) fan per-task specs out to sub-subagents.

## Plan OWNS / Plan DEFERS

!cat skills/plan/owns-defers.md

## Artifact Gating

Read `config.md` to determine pipeline mode. If `config.md` doesn't exist or has no `route` field, refuse to proceed and tell the user to re-run Goals. The `route` field is authoritative; `pipeline` is informational (see using-qrspi Config File).

**Full pipeline (`pipeline: full`) — required inputs:**

- `goals.md` — `status: approved`
- `research/summary.md` — `status: approved`
- `design.md` — `status: approved`
- `structure.md` — `status: approved`
- `phasing.md` — `status: approved`

**Quick fix (`pipeline: quick`) — required inputs:** `goals.md`, `research/summary.md` — each `status: approved`. Design and Structure don't exist on quick.

If any required artifact is missing or not approved, refuse to run and name the missing artifact. Read `config.md` to determine whether Codex reviews are enabled.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Plan validates `pipeline`, `route`, `second_reviewer`, and (when `pipeline: quick`) `question_budget`.

<HARD-GATE>
Do NOT produce plan.md without all required artifacts approved (full: goals + research + design + structure; quick: goals + research).
Do NOT use placeholder content in task specs: no TBD, TODO, "similar to Task N", "add appropriate handling".
Every task spec must be self-contained — an implementation agent reading only that task must have everything it needs.
</HARD-GATE>

## Execution Model

**Subagent** produces `plan.md` overview. For large plans (6+ tasks), per-task specs farm out to sub-subagents (one per task) to keep context manageable. Iterative with human feedback.

## Phase-Scoped Content Rules

plan.md contains ONLY current-phase tasks. Each task must reference goal IDs that exist in goals.md. Tasks for goals not in the current phase must not appear. The `goal_ids` frontmatter list (e.g. `[G1, G2]` — see ID-Hygiene Contract below) must contain only IDs in goals.md.

## Task Sizing

Each task implements **exactly one observable behavior** — one request handler, one use case, one user-visible change. The task title names exactly one feature, with no `+` joining feature names and no two distinct verbs joined by `and`.

**LOC budget per task:** Target ~100 LOC (matches OpenAI AGENTS.md). Policy ceiling 200 LOC — split unless `sizing_exception` (post-split frontmatter) or **Sizing exception** bullet (in-plan) names one of: schema migration, CI scaffolding, reusable primitives.

**"LOC" = implementation source only** (across files in `Target files:` excluding `tests/`). Test code has no ceiling but should be roughly 1.5–2× impl LOC. 100 src + 250 test = fine; 250 src needs `sizing_exception` or split.

**Why:** SWE-Bench Pro reports median patch 107 LOC / 4.1 files at ~23% frontier-model success (GPT-5, Opus 4.1). OpenAI AGENTS.md targets ~100 lines per agentic task. Our 200-LOC ceiling sits at the lower bound of Cisco/SmartBear's code-review sweet spot with margin for QRSPI scaffolding. Multi-feature titles like `auth + allowlist + rename + admin` are the visible symptom; the cause is bundling N request handlers into one task, re-coupling slices that vertical-slice decomposition exists to separate.

**Splitting protocol.** A task >200 LOC splits into N tasks at or below ~100 LOC, each implementing one handler with explicit dependency ordering. Closed exception set: schema migration, CI scaffolding, reusable primitives. Mark `sizing_exception: <reason>` (frontmatter, post-split) or **Sizing exception** bullet (in-plan), and explain in Description.

**Floor — a task is too small if any hold:**
- Does not traverse the layers needed for its behavior (UI-only, schema-only, mock-only, test-only)
- Produces no observable behavior change when merged alone (pure refactor with no callers, scaffold with no consumer)
- Depends on a sibling task to compile or pass tests
- Cannot be merged to main alone (must batch with peers to ship)

Failing a floor check → merge into the parent task that gives it observable behavior; do not ship sub-atomic tasks.

## Schema-Migration Task Shape

A **schema-migration task** applies an identical mechanical change to N files of the same shape (e.g., deleting one frontmatter key from every agent file). This is the narrow exception to the LOC ceiling and file-count guidance. The full contract — eligibility, the mandatory `sizing_exception: schema-migration` + `sizing_rationale:` + `structural_lint:` trio, the script-path ERE, the diff-must-be-non-empty rule, and the six plan-spec defect conditions — lives in `references/schema-migration-task-shape.md`. Read that reference whenever authoring or reviewing such a task. The plan reviewer (`agents/qrspi-plan-reviewer.md` § Schema-migration exception review) enforces the same six defects.

## Multi-Actor Flow Check

!cat skills/_shared/multi-actor-flow-check.md

## Process

### Plan Overview Subagent

**Inputs:** `goals.md`, `research/summary.md`, `design.md`, `structure.md`, prior feedback files.

**Task:** Break the structure into ordered tasks following vertical slices and phases.

1. **Pre-fanout absorption-map gate.** Before drafting any per-task spec, run `scripts/design-absorption-markers.sh <design-path>` and ingest the absorbed-goal redirect map (`<absorbed-ID> → <absorbing-ID|"no-task">`). For any goal ID present in the map, DO NOT draft a standalone task; if the original intent surfaces residual work that genuinely needs implementation, attach it to the absorbing CD's task scope, NOT to a new "post-<absorbing-ID> cleanup" wrapper task. If residual work genuinely fits nowhere in the surviving goal/CD set, halt with BLOCKED and surface the case to the user instead of manufacturing a task home.
2. Break structure into ordered tasks following vertical slices and phases from `design.md`.
3. Each task spec includes: exact file paths to create/modify; description; test expectations in plain language (behaviors, inputs/outputs, edge cases, error conditions); dependencies; LOC estimate.
4. No placeholders, no TBDs, no "similar to Task N" — each spec is self-contained.

**PRECONDITION:** `skills/_shared/prompt-prose-detection.md`, `skills/_shared/prompt-prose-writer-addition.md`, and `skills/_shared/prompt-prose-test-expectations-clause.md` MUST exist on disk; halt with a named diagnostic if any is missing rather than proceeding with empty include content.

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-writer-addition.md

!cat skills/_shared/prompt-prose-test-expectations-clause.md

**Small plans (<6 tasks):** overview subagent writes the full merged `plan.md` directly. **Large plans (6+):** overview subagent writes `plan.md` overview only; per-task specs dispatch to sub-subagents — **one per task**. The fan-out shape is load-bearing for per-spec focus; a single merged-author subagent optimizes for cross-spec consistency over per-spec depth and drops edge cases.

### Quick-Fix Plan Behavior

When `config.md` has `pipeline: quick`: the plan subagent receives `goals.md` + `research/summary.md` only (no design/structure) and produces a **single-task plan** directly — no sub-subagent dispatch, no merge/split lifecycle. The task spec derives file paths and test expectations from research findings and goals; merged `plan.md` carries both overview and the single spec. After approval, the task writes to `tasks/task-01.md` and `plan.md` reduces to overview-only. Review round, human gate, and approval process are identical to full pipeline.

### Sub-Subagent Dispatch (Large Plans Only)

**Compaction checkpoint: pre-fanout.** Per-task spec-generation fan-out — one subagent per task. The orchestrator's post-fanout merge re-aggregates output into `plan.md`; that re-aggregation is where context saturation bites. See using-qrspi `## Compaction Checkpoints`.
Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — plan", description: "per-task spec fan-out merges into plan.md; user decides /compact." })`.

**Sub-subagent inputs:** `plan.md` overview; relevant `structure.md` sections; `design.md` (for per-goal `Acceptance` blocks + vertical-slice context); `skills/plan/owns-defers.md` (the layer-depth clamp — without it, sub-subagents drift into Implement/Structure scope: algorithm pseudocode, regex grammar, literal-value hard-coding, line-numbered citations, exact `@test` counts, shebang/file-mode specifics); the three `skills/_shared/prompt-prose-*` shared files included at Plan Overview Subagent above (re-checked at dispatch; same PRECONDITION).

Each sub-subagent writes `tasks/task-NN.md` — **and ONLY that file**. Sub-subagents MUST NOT create or modify any implementation file (script, test, SKILL.md, agent body, etc.) the task describes; those land in Implement. After all complete, Plan appends each task file as a section to `plan.md` and deletes the individuals — single document is the only source of truth during review.

### Per-Task Classification (`task_type` and `tier`)

Every task spec sets `task_type` and `tier` in frontmatter (the per-task `model:` field is retired by G22 / design.md CD-1). `task_type` selects the TDD or lightweight implementer dispatch chain; `tier` is consumed by the Tier Resolution Chain (`scripts/_resolve-lib.sh`), which maps the tier to a `(vendor, model)` pair via `config.md`'s `model_routing:` block — NOT a per-invocation override.

**`task_type` dispatch:**
- **Absent or `code`** — TDD path: when `task_type: code` (or absent), the test-writer dispatches first, then the implementer, with the RED-verification gate between them. Absent `task_type:` defaults to the TDD path identically. **Dispatch order: test-writer → RED-verification gate → implementer.**
- **`lightweight`** — when `task_type: lightweight`, the lightweight-only dispatch fires: no test-writer, no RED gate. **Dispatch order: implementer only.** Implement dispatches `qrspi-implementer-lightweight` directly.

TDD-task specs must carry an explicit dispatch-ordering note in `## Description` or atop `## Test Expectations`:

> Dispatch order: test-writer → RED-verification gate → implementer.

Lightweight tasks omit this note.

**Step 1 — Classify.** Default `code`. Assign `lightweight` when the task's primary deliverable is prompt prose OR non-prompt prose / docs / config with no executable behavior to test. Apply the detection in `skills/_shared/prompt-prose-detection.md` (included at Plan Overview Subagent above; PRECONDITION re-asserted — halt with a named diagnostic if missing). Mixed-deliverable tasks require ALL target files to satisfy the lightweight test; otherwise default to `code` and split per Goal-Specificity if genuinely mixed. Prompt prose NEVER lands on the TDD path.

**Step 2 — `tier`** (run after `task_type`):
- `lightweight` → `tier: low`. No exception.
- `code` → `tier: high` if **any** of: `Target files` count > 3; any target matches a core-surface glob (`skills/**/SKILL.md`, `skills/_shared/**`, `agents/qrspi-implementer*.md`, `agents/qrspi-implementer-lightweight*.md`, `skills/reviewer-protocol/**`, `skills/implementer-protocol/**`); fix-task spawned by Replan (`fix_task_retry: true`); carries `sizing_exception`.
- Otherwise → `tier: medium`.

**Operator override.** `tier:` is editable before plan approval — the heuristic is a default, not a contract. **Absent fields.** Plans omitting `task_type:` and `tier:` are read by Implement as `code` with `default_tier:` from `config.md` and a one-line warning at dispatch — no hard failure.

### Plan Document Structure (During Review)

The template below embeds information-mapping patterns: claim-before-evidence, one-paragraph-per-claim, scannable bullets, required structural slots (Phase / Target files / Dependencies / LOC estimate / Description / Test expectations). No brevity directives — they degrade factual reliability (Phare benchmark, Hakim). Per-task specs are short by structural design.

!cat skills/_shared/evergreen-output-rule.md

```markdown
---
status: draft
phase_start_commit: null
test_writer_tier: null   # optional: low | medium | high. When unset, per-task `tier:` drives co-escalated qrspi-test-writer dispatch (high-tier co-escalates implementer + test-writer per design.md CD-1). Set only to pin test-writer tier independent of per-task tier.
---

# Implementation Plan

## Overview
{Phase structure, task ordering, dependency graph}

## Phase N: {name}
{Tasks in this phase, ordering rationale}

### Phase N Acceptance Criteria

Per-phase criteria observable end-to-end at phase boundary (independent of any single task):
- [ ] {Criterion 1}
- [ ] {Criterion 2}

(Per-task criteria live in each `tasks/task-NN.md`'s `## Test Expectations`; this block captures cross-task observable behavior at phase end.)

---

## Task Specs

### Task 1: {name — one observable behavior; no `+` joining feature names; no two distinct verbs joined by `and`}
- **Phase:** 1
- **Target files:** {exact paths, create/modify}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Sizing exception:** {only for legitimate bundles; reason ∈ {schema migration, CI scaffolding, reusable primitives}}
- **Description:** {observable-behavior sentence first, then context. Plain language; no function signatures (→ Structure); no pseudocode (→ Implement); no architecture rationale (→ Design).}
- **Test expectations:**
  - {behavior 1 — plain language; no `expect(...)` or assertion code (→ Implement-TDD)}
  - {edge case 1}
  - {error condition 1}

### Task 2: {name}
...
```

**Per-phase acceptance block authoring.** Per-phase criteria trace upstream to `goals.md` goals but are AUTHORED in `plan.md`, not `goals.md`. The block lives directly under each `## Phase N: {name}` heading. Downstream consumers (test/SKILL.md, `qrspi-plan-spec-reviewer`, `qrspi-plan-goal-traceability-reviewer`) read these to verify end-to-end observable behavior at phase boundary.

**Conformance for per-task spec writer.** Each spec satisfies: required-section presence; claim-line ≤ 250 chars per bullet; description paragraph ≤ 150 words; section ≤ 300 words before bullets split; no brevity directives ("be concise", "brief summary", "≤ N lines" are forbidden — see lint allowlist for legitimate length-target exceptions). The DEFERS list says what NOT to include; this says how to structure what IS.

**Smoke-check requirement.** Any task adding or modifying a route, page, layout, or user-facing component MUST include a `smoke_checks:` block per [`smoke-spec.md`](smoke-spec.md). Tasks that only modify internal libraries MAY omit it.

### Project Environment Fields

Every plan declares commands the implementer gate uses to verify a task — the implementer reads these and runs them at the per-task gate (see `skills/implement/SKILL.md`):

- `build_command` — produces the project's build artifact, run after tests pass during per-task verification. Examples: `pnpm build`, `cargo build --release`, `go build ./...`, `tsc -p .`. Set to literal `'none'` only for pure-script projects with no build step; include a one-line rationale.
- `dev_command` — starts the dev server for the smoke-check gate. Required when any task declares `smoke_checks:`; optional otherwise. Examples: `pnpm dev`, `cargo run`, `python manage.py runserver`. Plans that opt into smoke checks also declare `smoke_auth:` per [`smoke-spec.md`](smoke-spec.md).

### Plan Reviewer Agents

Seven reviewer dispatches run in parallel as the review round (one unified plan-quality + five plan-artifact + one scope-reviewer). All seven run always — neither quick-fix nor full-pipeline gates any reviewer. Plan-artifact reviewers requiring `design.md`/`structure.md` emit "NOT APPLICABLE — quick-fix route" when absent (the `route` dispatch param drives this). Plan-artifact reviewers (`agents/qrspi-plan-{name}.md`) review the plan **artifact**; per-task reviewers (`agents/qrspi-{name}.md`) review task **implementations** during Implement — different bodies, different dispatch sites.

| Reviewer | Agent | Focus |
|----------|-------|-------|
| Plan Quality (unified) | `qrspi-plan-reviewer` | Cross-cutting plan-quality (completeness, no-placeholders, sizing, phase alignment, design/structure traceability on full route) |
| Spec Reviewer | `qrspi-plan-spec-reviewer` | Completeness, scope, interpretation, test coverage mapping, placeholder detection |
| Security Reviewer | `qrspi-plan-security-reviewer` | Fail-closed, input validation, auth/authz, no insecure defaults |
| Silent Failure Hunter | `qrspi-plan-silent-failure-hunter` | Swallowed errors, silent fallbacks, partial state, log-and-continue |
| Goal Traceability | `qrspi-plan-goal-traceability-reviewer` | Forward / backward trace, gap analysis, spec-to-design fidelity |
| Test Coverage | `qrspi-plan-test-coverage-reviewer` | Behavioral coverage, edge cases, error conditions, missing design scenarios |
| Scope Reviewer | `qrspi-plan-scope-reviewer` | OWNS/DEFERS boundary-drift; scope-compliance per locked Plan rules |

### Review Round

**Compaction checkpoint: pre-fanout.** Reviewer fan-out reads merged `plan.md` + `goals.md` + `research/summary.md` + `design.md` + `structure.md`; up to seven parallel Claude dispatches plus seven non-blocking Codex parallels when `second_reviewer: true`. See using-qrspi `## Compaction Checkpoints`.
Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — plan", description: "pre-fanout: reviewer fan-out (7 Claude + up to 7 Codex) reads merged plan.md + 4 prior artifacts. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`.

**Pre-dispatch diff-file emission.** Before dispatching reviewers, the orchestrator runs `git -C "<repo>" diff "<ref>" -- "<ABS_ARTIFACT_DIR>/plan.md" "<ABS_ARTIFACT_DIR>/tasks/" > "<ABS_ARTIFACT_DIR>/reviews/plan/round-NN.diff"` as a Bash redirect (diff never enters main-chat context). `<ref>` is `<base-branch>` by default, narrowed to the SHA from `reviews/plan/round-(NN-1)-commit.txt` when using-qrspi step 12's anchor-file lookup applies (validates SHA shape, halts with `anchor-file-missing:` / `sha-format-invalid:` before any `git diff` runs). Each reviewer dispatch carries `diff_file_path: <ABS_ARTIFACT_DIR>/reviews/plan/round-NN.diff` and (when narrowed) `scope_hint: <scope_set>` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract. Plan is multi-file, so scope-tagger emits file paths as tags from `referenced_files`. Omit diff redirect and parameter when the artifact directory isn't in a git repository. Follow the fail-loud contract in `using-qrspi/SKILL.md` § Standard Review Loop step 1.

**Route detection + companion preparation.** Read `config.md` for `route` (`full`|`quick`). Pass `route: full|quick` as an explicit dispatch param to every quality + plan-artifact dispatch (scope-reviewer takes no `route`). Construct wrapped companion bodies once and reuse across all six dispatches — each named artifact wrapped between `<<<UNTRUSTED-ARTIFACT-START id=<name>>>>` / `<<<UNTRUSTED-ARTIFACT-END id=<name>>>>` markers: `companion_goals` (`goals.md`), `companion_research` (`research/summary.md`), `companion_phasing` (`phasing.md`), `companion_design` (`design.md`, **full only**), `companion_structure` (`structure.md`, **full only**).

Reviewers dispatch through the universal chain (`scripts/dispatch-agent.sh --agents` → Task fan-out → `scripts/await-round.sh`). `*-claude` tags route first-party; `*-codex` route third-party. Include `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; on quick-fix routes the dispatcher omits `companion_design`/`companion_structure` automatically.

```sh
REVIEW_STEP="plan"
REVIEW_ROUND="${ROUND}"
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/plan/round-${ROUND}/"
REVIEW_ARTIFACT="plan.md"
REVIEW_AGENTS="quality-claude=qrspi-plan-reviewer,spec-claude=qrspi-plan-spec-reviewer,security-claude=qrspi-plan-security-reviewer,silent-failure-claude=qrspi-plan-silent-failure-hunter,goal-traceability-claude=qrspi-plan-goal-traceability-reviewer,test-coverage-claude=qrspi-plan-test-coverage-reviewer,scope-claude=qrspi-plan-scope-reviewer,quality-codex=qrspi-plan-reviewer,spec-codex=qrspi-plan-spec-reviewer,security-codex=qrspi-plan-security-reviewer,silent-failure-codex=qrspi-plan-silent-failure-hunter,goal-traceability-codex=qrspi-plan-goal-traceability-reviewer,test-coverage-codex=qrspi-plan-test-coverage-reviewer,scope-codex=qrspi-plan-scope-reviewer"
```

!cat skills/_shared/reviewer-dispatch-prose.md

- The default-option-2 recommendation in the Standard Review Loop is especially important here because plan reviews catch cross-file consistency / forward dependencies / migration ordering across 10+ task specs that the human cannot feasibly verify by hand.

### Apply-Fix Dispatch (Plan override of using-qrspi Apply-fix protocol step 8)

Plan's apply-fix overrides `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 8 ("Survivors → `Edit` on the artifact"). Instead of inline `Edit` from main chat, the orchestrator dispatches `agents/qrspi-plan-apply-fix.md`. The full dispatch invocation (sh block with all `--field` / `--companion` arguments) and the override rationale (plan.md's 1000–2000-line aggregate body and per-task upstream-contract dependencies exceed the safety envelope of inline `Edit`; the agent body's Step 3 upstream-contract pre-flight is the load-bearing safety property) live in `references/apply-fix-dispatch.md`. Read that reference whenever running a Plan apply-fix pass; the dispatch resolves `--model` via the Tier Resolution Chain against the agent's `tier: high` frontmatter, and passes `kept_findings_file` whenever `scripts/verifier-fan-in.sh` has run.

### Human Gate

Present merged `plan.md` to the user — overview for approval, task details for spot-checking. **Always state the review status:** "Reviews passed clean in round N" OR "Reviews found issues in round N which were fixed but not re-verified."

**On approval:**

1. **If reviews have NOT passed clean** (user chose option 1 earlier, or backward loops introduced changes after the last clean round): ask "Reviews haven't passed clean yet — run a review loop before splitting? Strongly recommended; catches cross-file inconsistencies hard to spot manually." If agreed, run the loop. If declined, proceed.
2. **Recommend compaction:** "Plan approved. Good point to `/compact` before I split tasks — the split is mechanical." Wait for compact (or decline), then proceed.
3. **Split (post-approval orchestration):** Fan out per-task spec writing, verify file set, reduce plan.md to overview-only, capture `phase_start_commit:`, then write `status: approved` — in this exact transactional order, so an approved `plan.md` is never observable on disk without all corresponding `tasks/task-NN.md` files present. The per-sub-subagent input/output contract lives in `skills/plan/post-approval-split-contract.md`.

   **N-threshold carve-out** (N = number of tasks in approved overview):
   - **N >= 3 (sub-subagent fan-out):** One sub-subagent per task in parallel. Each receives the task section from `plan.md` wrapped as untrusted artifact; the canonical task-file template (Split task file format below) carrying all Slice 5 frontmatter (`reference_gate:`, `reference_artifact:`, `ui:`, `lift_source:`, plus T43's `conditional:` / `conditional_precondition:`); the G7 ID-Hygiene Contract (`goal_ids` is metadata; do NOT echo into the body); and `output_path` (`<artifact_dir>/tasks/task-NN.md`). Each writes exactly one file. Sub-subagents MUST NOT edit `plan.md`. Rationale: parallelism + isolation savings exceed dispatch overhead at N >= 3; combined plan+specs exceeds the 600-line threshold (design line 157) at which main-chat writing saturates the review window.
   - **N <= 2 (inline main-chat split):** Write `tasks/task-01.md` (and `task-02.md`) inline. Under the 600-line threshold; dispatch overhead exceeds the saving.

   **File-count verification (both paths).** Verify the exact set `{task-01.md, ..., task-N.md}` by enumerating IDs (do NOT pass by file count alone):
   - **Duplicate-ID:** HALT `"Split verification failed: duplicate task file(s) detected: task-03.md (2 copies). Resolve before proceeding."` Do NOT write `status: approved`.
   - **Missing-ID:** HALT `"Split verification failed: expected task files not written: task-04.md. Re-run split for missing tasks before proceeding."` Do NOT write `status: approved`.

   When the exact set matches, reduce `plan.md` to overview-only (remove `## Task Specs` and all `### Task NN` blocks — they live in `tasks/`), capture `phase_start_commit:`, then write `status: approved`.

**On rejection:** Write feedback and rejected snapshot to `feedback/plan-round-{NN}.md` (standard format from `using-qrspi`), then launch a new subagent with original inputs + **all** prior feedback files. The review cycle restarts.

### Quick-Fix Auto-Approve Branch

When `pipeline: quick` and the review round produces verifier-affirmed zero kept findings, the human-approval gate is skipped and the split / `status: approved` / `phase_start_commit` capture proceed automatically. The full contract — verifier-gate precondition, the three satisfying conditions (sidecar, marker file, or `verifier_enabled: false` audit-log requirement), post-fix-round behavior, and the relationship to single-task-plan behavior — lives in `references/quick-fix-auto-approve.md`. Full-pipeline runs are unaffected.

### Merge/Split Mechanics

- **Before review:** Large plans — sub-subagents write `tasks/task-NN.md` → Plan appends them as sections to `plan.md`, deletes individuals → single doc, only source of truth. Small plans — plan subagent writes merged `plan.md` directly.
- **During review:** All changes in single `plan.md`; `tasks/` is empty.
- **After approval:** Plan splits each `### Task N` section back into `tasks/task-NN.md`, reduces `plan.md` to overview-only.

**Split task file format** (`tasks/task-NN.md`):

```markdown
---
status: approved
task: NN
phase: {phase number}
pipeline: full
goal_ids: [G1, G2]   # QRSPI-internal metadata; see ID-Hygiene Contract — do NOT echo into body
task_type: code      # code | lightweight (default: code) — see Per-Task Classification
tier: medium         # low | medium | high (default: medium) — see Per-Task Classification
# Optional fields (omit if N/A):
# sizing_exception: <schema migration | CI scaffolding | reusable primitives>  # legitimate-bundle marker
# reference_gate: true                                                          # paired with reference_artifact (Refuse-to-Write enforces)
# reference_artifact: path/to/source-of-truth.md
# ui: true                                                                      # paired with lift_source → requires SPEC OVERRIDES SOURCE body section
# lift_source: path/to/existing-source.md
# visual_fidelity_check:                                                        # MANDATORY on UI tasks when config has visual_fidelity_required: true
#   wireframe_refs:
#     - <path-or-URL-to-wireframe>
#   ui: true                                                                    # replaces legacy ui_producing (see Pre-Slice-5 migration)
---

# Task NN: {name}

- **Target files:** {exact paths, create/modify}
- **Dependencies:** {task numbers or "none"}
- **LOC estimate:** ~{N}
- **Description:** {substantive WHY only; no ID echoes — see ID-Hygiene Contract}
- **Test expectations:**
  - {behavior 1}
  - {edge case 1}
  - {error condition 1}

<!-- SPEC OVERRIDES SOURCE section — REQUIRED when frontmatter carries both
     ui: true and lift_source: <path>. List behaviors the implementer must
     NOT copy from the source and the required target behavior for each. -->
```

### SPEC OVERRIDES SOURCE authority

A per-task spec authored in `plan.md` (or split `tasks/task-NN.md`) is the authoritative definition of the task's behavior. If a `lift_source:` file carries frontmatter or body content conflicting with the spec — a stale `visual_fidelity_check.ui_producing`, a legacy `lift_source` value, any field contradicting the spec — **the spec wins**; the implementer rewrites the source to match. Load-bearing for every Slice 5 consumer (Structure, Parallelize, Implement, the visual-fidelity reviewer, and the reviewer-protocol/design-skill checklist all key on the per-task spec's frontmatter shape).

### Refuse-to-Write Contract

The Plan orchestrator refuses to write (or post-approval materialize) a task spec when either paired-field invariant is violated. Multiple violations in one plan are reported together before any task spec is written. Refusal applies to both initial authoring and sub-subagent materialization.

- **Pair 1 — Reference-gate (`reference_gate: true` ↔ `reference_artifact:`).** Either present without the other → refuse. Forward diagnostic: `"Plan refuse-to-write: task NN carries reference_gate: true without reference_artifact — add reference_artifact: <path> or remove reference_gate."` Symmetric reverse diagnostic: `"Plan refuse-to-write: task NN carries reference_artifact without reference_gate — add reference_gate: true or remove reference_artifact."`
- **Pair 2 — UI+lift-source (`ui: true` + `lift_source: <path>` ↔ `SPEC OVERRIDES SOURCE` body section).** Both fields present without the section → refuse: `"Plan refuse-to-write: task NN carries ui: true and lift_source: <path> without a SPEC OVERRIDES SOURCE body section — add the section listing behaviors not to copy and required target behavior."`

Task specs with **none** of `reference_gate:`, `reference_artifact:`, `ui:`, or `lift_source:` write and process without error — no paired-field diagnostic, no reference-gate pause, no visual-fidelity reviewer dispatch (identical to a pre-Slice-5 spec).

**Pre-Slice-5 migration.** Specs carrying `visual_fidelity_check.ui_producing` are migrated to top-level `ui:` at review or post-approval split time; full steps in `references/visual-fidelity-ui-producing-migration.md`.

### Migration: `visual_fidelity_check.ui_producing` → top-level `ui:`

When Plan encounters a pre-Slice-5 task spec carrying `visual_fidelity_check.ui_producing: true`:

1. Promote the value to a top-level `ui: true` field in the task frontmatter.
2. Remove the `ui_producing` field from inside the `visual_fidelity_check:` block.
3. Preserve all other `visual_fidelity_check:` sub-fields (e.g., `wireframe_refs:`) unchanged.
4. Log the migration in the DONE report as a one-line note per affected task.

### Pipeline + Fix-Task Fields

**Pipeline field.** Copied from `config.md`'s `pipeline` at plan time. The per-task dispatch in `implement/SKILL.md` § Per-Task Execution reads the task file's `pipeline` for per-task input gating. Implement derives run mode separately from `config.md.route` for per-phase orchestration. Who writes it: **Plan** copies from `config.md` onto every `tasks/task-NN.md`; **Test** classifies per failure (quick or full) on fix tasks; **Integrate** is always `full` on integration/CI fix tasks; **Implement baseline fix** inherits the run's mode on task-00 (writes the runtime-injected `task-00.md` with `status: approved` so the Iron Law gate passes).

**Fix task files** carry a `fix_type` field (not on regular tasks): `integration` (Integrate cross-task), `ci` (Integrate CI), `test` (Test acceptance). Fix tasks live in `fixes/{type}-round-NN/` and use the regular-task format so Implement processes them identically.

**ID-Hygiene Contract.** QRSPI-internal traceability lives in the YAML `goal_ids` field — **metadata** the implementer reads but does NOT echo into the work product. Canonical surface list: `agents/qrspi-implementer.md` § ID Hygiene, reviewed by `agents/qrspi-code-quality-reviewer.md` § 11. Plan's upstream responsibility: do NOT add `Target satisfies:`, `Goals addressed:`, `Closes <goal-ID>`, `per <decision-ID>`, or similar internal-ID prose to task-spec bodies — those invite the implementer to copy IDs into the work product. Bodies must read as standalone work specifications grounded in observable behavior. PR-body `Closes #N` (external tracker IDs only) remains valid at commit/PR altitude.

### Artifacts + Terminal State

- `plan.md` — overview + all task specs (review artifact); overview-only after approval.
- `tasks/task-NN.md` — individual task specs split out after approval (implementation artifacts).

**`phase_start_commit`.** At plan.md approval, capture HEAD via `git -C <artifact_dir> rev-parse HEAD` and write into `phase_start_commit:` alongside `status: approved`. This SHA is the diff anchor Replan and Test use to scope post-phase changes. If the artifact dir is not in a git repo, leave `phase_start_commit: null` — Replan/Test fall back to whole-codebase scope. Verification fallback (debug only): derive from `git -C <repo> log -1 --format=%H -- <artifact_dir>/plan.md` if the frontmatter value is missing or suspect; frontmatter is primary.

**Commit.** If inside a git repository, commit the approved `plan.md`, all `tasks/task-NN.md`, and `reviews/plan/` (per `using-qrspi` → "Commit after approval (when applicable)").

**Compaction checkpoint: pre-handoff.** Plan has split tasks and committed approved artifacts; synthesis + review history is no longer load-bearing. See using-qrspi `## Compaction Checkpoints`.
Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — plan", description: "pre-handoff: next skill reads plan.md + tasks/*.md on fresh context. User decides /compact." })`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `plan`. If compaction wasn't done before splitting, recommend it now.

## Test Expectations

Each per-task spec carries a `**Test expectations:**` bullet list naming observable behaviors, edge cases, and error conditions (see template above). Bullets describe behavior in plain language; the Test skill and the implementer's TDD cycle consume them as source of truth. The standard shape covers the common case where every required test lives inside `Target files:`. **Sweep tasks** break this: test files asserting on the swept property's previous values sit outside `files_in_scope`, the per-task gate never runs them, the task ships GREEN, and integrate surfaces stale-test failures.

### Sweep Task Contract

A **sweep task** removes, replaces, or enforces an invariant across many files at once (e.g., "strip `model:` from all agent frontmatter," "rename `qrspi-foo` to `qrspi-bar` across all skills"). It systematically invalidates test files that assert on the swept property's previous values, even when those tests are not in `files_in_scope`. A sweep-task plan-spec MUST include a `dependent_tests:` field in its Test Expectations (either an explicit list of test file paths the per-task gate must additionally run, or the literal `none` followed by a grep-confirmable command demonstrating zero hits). Skipping it on a sweep-shaped task is a plan-spec defect detected by the Plan reviewer's Sweep-task detection (heuristic: >5 same-extension files in `files_in_scope` plus a sweep keyword in title/description). Full eligibility, field shape, defect conditions, and worked examples (A, B) live in `references/sweep-task-contract.md`.

The canonical zero-match proof command shape is `grep -rn -- '<pattern>' tests/` — the `--` argument separator neutralizes flag-shaped patterns, and the `tests/` root is the rerun target the plan reviewer uses verbatim.

**Worked example A — explicit `dependent_tests:` path list.** A sweep stripping `model:` from all agent frontmatter lists every test that asserts on the previous values:

```markdown
- `dependent_tests:`
  - `tests/unit/test-scope-tagger-dispatch.bats` — currently asserts `model: opus` on line 38; update to assert `model:` is absent post-sweep.
  - `tests/unit/test-verifier-agent-file.bats` — currently asserts `model: sonnet` on line 7; update to assert `model:` is absent post-sweep.
```

**Worked example B — `none` plus grep-confirmed zero-match proof.** A sweep removing a property no test currently pins cites the rerunnable command:

```markdown
- `dependent_tests: none`
  - `grep -rn -- '^model:' tests/` returns zero matches as of plan-authoring time; the reviewer's re-run surfaces any new hit and demands the field be re-shaped to a path list.
```

### Cross-Task Consumer Surface

A task is **consumer-surface-touching** when its description or `files_in_scope` indicates ANY of: (a) adding/renaming/removing a function, method, class, interface, exported symbol, or other named declaration; (b) adding/renaming/removing/moving a file in `files_in_scope`; (c) changing the public signature (parameter list, return type, exceptions, side effects, visibility) of any callable in `files_in_scope`; (d) changing the schema or structure of any structured document (JSON, YAML, frontmatter, TOML, XML) in `files_in_scope` whose keys/anchors/top-level identifiers are referenced by name from other files; (e) adding/renaming/removing a documented contract (config key, env var, CLI flag, URL route, RPC method, subcommand, schema field, anchor heading, or other named extension point). A task that only modifies the body of an existing callable, edits prose without changing referenced anchor names, or fixes formatting is NOT consumer-surface-touching. The trigger fires on changes other code/documents could plausibly couple to *by name*.

When the trigger fires, the plan-spec MUST include `cross_task_consumers:` with one of two shapes:

- A **list of consumer file paths** outside `files_in_scope`, each followed on the next line by a one-sentence disposition. Vocabulary is exactly four values: `no change`, `pass-through` (behavior unchanged, file must be re-verified), `co-edit` (consumer modified inside this same task), `break-and-fix-task` (consumer intentionally broken and repaired in a named follow-up task — the follow-up task ID MUST be cited and MUST already exist in the plan).
- The literal string `none` followed on the next line by a reproducible search command (grep / rg / git grep / language-specific reference-finder) demonstrating zero consumer references outside `files_in_scope`. The reviewer re-runs and treats any hit as a defect.

Skipping `cross_task_consumers:` on a consumer-surface-touching task is a plan-spec defect. The Plan reviewer (`agents/qrspi-plan-reviewer.md` § Cross-task consumer surface detection) emits `severity: high, change_type: correctness` when the field is missing, malformed, claims `none` against a non-zero hit, names an invalid disposition, or cites a `break-and-fix-task` follow-up that doesn't exist in the plan.

**Sweep + consumer composition.** A task satisfying BOTH triggers carries `dependent_tests:` AND `cross_task_consumers:` as separate fields — they ask different questions (test files asserting on swept values vs. consumer files referencing the changed contract by name) and evaluate independently.

**Worked example C — public-symbol rename with three consumers (trigger fires).** A task renames the public function `check_codex_available` to `check_second_reviewer_available` and lists three consumer files outside `files_in_scope`:

```markdown
- `cross_task_consumers:`
  - `skills/goals/SKILL.md` — references the old helper name in its inline availability probe; `co-edit` to rename the call site inside this task.
  - `skills/implement/SKILL.md` — references the old helper name in the second-reviewer dispatch block; `co-edit` to rename the call site inside this task.
  - `tests/unit/test-codex-host-vendor-matrix.bats` — asserts on the helper-name surface as documentation, not as an executable reference; `no change` because the test was rewritten to target the host×vendor matrix and no longer pins the helper name.
```

**Worked example D — body-only bug fix (trigger does not fire).** A task fixes an off-by-one inside an existing function's body in one file. No public-signature change, no rename, no schema change. The `cross_task_consumers:` field is NOT required because the trigger does not fire on a body-only bug fix.

## Red Flags — STOP

- Placeholders: "TBD", "TODO", "implement later", "fill in details", "similar to Task N", "write tests" without specifying behaviors
- Reference to a type, function, or file not defined in any task
- Forward dependency (depends on a later task)
- Missing or wildly unrealistic LOC estimate (e.g., 10 LOC for full CRUD); LOC >200 without `sizing_exception` naming one of the closed set (see Task Sizing)
- Task title contains `+` joining feature names or two distinct verbs joined by `and` (multi-feature bundle — split); Description implies multiple request handlers / use cases (one task = one handler)
- Task fails a floor check (see Task Sizing floor)
- Task touches files from a different vertical slice without justification; phase boundaries don't align with design's phase definitions
- Quick-fix plan has more than one task (quick fix = single task by definition)
- `config.md` carries `visual_fidelity_required: true` and a task with `visual_fidelity_check.ui_producing: true` lacks a non-empty `wireframe_refs` (refuses fan-out — see Visual-fidelity hard-gate below)
- `reference_gate: true` without `reference_artifact:` (or vice versa); `ui: true` + `lift_source: <path>` without a `SPEC OVERRIDES SOURCE` body section — paired-field violations, see Refuse-to-Write Contract
- Dispatching a single merged-author subagent for all N per-task specs (any N≥6). One-subagent-per-task by design — the merged shortcut trades per-spec depth for cross-spec consistency. "One subagent is more efficient" is the rationalization the rule blocks.
- A per-task sub-subagent writes any file other than `tasks/task-NN.md` (pre-creating script, test, SKILL.md edit, or agent body). Implementation files land in Implement, never at Plan time.
- The overview-pass `plan.md` contains a `## Task Specs` H2. The overview owns Overview + Phase + dependency graph + acceptance criteria only; `## Task Specs` is created by the post-fanout merge. Collisions produce two same-named H2 sections.
- A per-task sub-subagent emits algorithm pseudocode, regex grammar, hard-coded literals (e.g. an email address), line-numbered citations, or exact `@test` counts. Fix upstream: sub-subagent inputs must include `skills/plan/owns-defers.md`.
- The plan fix-pass is dispatched without `agents/qrspi-plan-apply-fix.md` (e.g., freehand `general-purpose`). Without the agent body's Step 3 upstream-contract pre-flight, the fix-pass reverses design-approved contract directions in response to findings whose proper home is a Design or Structure amendment.

### Visual-fidelity hard-gate (pre-fanout refusal condition)

When `config.md` carries `visual_fidelity_required: true`, the Plan orchestrator runs a pre-fanout gate over merged `plan.md` and refuses reviewer dispatch when any task with `visual_fidelity_check.ui_producing: true` lacks a non-empty `visual_fidelity_check.wireframe_refs` list. The full contract — gate trigger, failure-mode diagnostics (absent-key vs empty-list vs null distinction), exemption rules for `ui_producing: false` and whole-block omission, and the present-block rule (a `visual_fidelity_check:` block that is present but malformed or missing `ui_producing:` is a **HARD parse error**, not a silent skip) — lives in `references/visual-fidelity-hard-gate.md`. Runs with the flag unset, absent, or `false` are exempt; no gate fires.

## Common Rationalizations — STOP

A table rebutting common pushback against the Iron Laws and Task Sizing rules lives in `references/common-rationalizations.md`. Read when reviewing a plan and you need a quick counter to "the implementer will figure it out" / "similar to Task N" / "splitting adds overhead" arguments.

## Worked Example + Iron Laws — Final Reminder

A good-vs-bad full task spec contrast lives in `references/worked-examples.md` — read when authoring a spec and you want a concrete reference for what passes the Iron Laws below versus what trips them.

1. **No plan.md without all required artifacts approved.** Full: goals + research + design + structure. Quick: goals + research.
2. **No placeholders in task specs.** No "TBD", "TODO", "implement later", "similar to Task N", "add appropriate handling." Every spec is self-contained.
3. **One task = one observable behavior, ~100-LOC target / ≤200 LOC ceiling.** Split before approving anything exceeding the ceiling unless `sizing_exception` names one of the closed set (schema migration, CI scaffolding, reusable primitives). Multi-feature titles (`+` joining feature names, two distinct verbs joined by `and`) are the canary. See Task Sizing for floor + empirical grounding.

Behavioral directives D1-D4 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
