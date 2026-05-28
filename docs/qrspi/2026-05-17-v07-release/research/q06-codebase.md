---
status: draft
question_ids: [6, 7]
research_type: codebase
---

# Q6, Q7: Plan-skill sub-subagent dispatch, post-approval split step, and task-file templates

## Summary

**TL;DR:** `skills/plan/SKILL.md` orchestrates plan generation in two regimes: small plans (<6 tasks) where one "Plan Overview Subagent" writes the merged `plan.md` directly, and large plans (6+ tasks) where the overview subagent emits an overview-only `plan.md` and then fans out per-task generation to sub-subagents (one per task) that each write a `tasks/task-NN.md` file. The post-approval split step lives in the "Human Gate → On approval → step 3" section of the SKILL flow (SKILL.md lines 416–423) and is mirrored in the "Merge/Split Mechanics" section (lines 443–447). There is no separate template file under `templates/` — the canonical task-file template is embedded inline in `skills/plan/SKILL.md` under "Split task file format" (lines 449–487), and the in-plan task-spec template is embedded under "Plan Document Structure (During Review)" (lines 168–218). The `templates/` directory at the repo root contains only `tsc-probe.ts` (not a markdown template).

**Key findings:**
- Sub-subagent dispatch is documented in "Sub-Subagent Dispatch (Large Plans Only)" (SKILL.md lines 119–132). It is gated by plan size (≥6 tasks), uses one sub-subagent per task (or related group), and each sub-subagent writes `tasks/task-NN.md` consuming `plan.md` overview + relevant `structure.md` sections + `design.md`.
- The orchestrator (Plan skill) then reads all returned task files, appends them as sections to `plan.md`, and deletes the individual files — creating a single source of truth during review (SKILL.md line 132).
- A compaction checkpoint ("pre-fanout") is documented at lines 121–123 with a `TaskCreate` recommendation before the fan-out.
- The post-approval split step is in "Human Gate" → "On approval" step 3 (lines 421–423): "Split task sections into individual `tasks/task-NN.md` files, then reduce `plan.md` to overview-only, then write `status: approved` in `plan.md` frontmatter." The ordering is explicit to avoid a transient state where downstream skills see an approved plan but no task files.
- Quick-Fix mode bypasses sub-subagent dispatch (lines 107–117): a single-task plan is produced directly; after approval the single task is still written to `tasks/task-01.md`.
- The canonical `tasks/task-NN.md` frontmatter (lines 451–475) declares: `status`, `task`, `phase`, `pipeline`, `goal_ids` (list), `task_type` (code | lightweight, default code), `model` (sonnet | opus, default sonnet), optional `sizing_exception`, and optional `visual_fidelity_check` block (with `wireframe_refs` list and `ui_producing` boolean).
- The canonical body section contract for `tasks/task-NN.md` (lines 477–487) requires: `# Task NN: {name}` H1, then bullet sections **Target files**, **Dependencies**, **LOC estimate**, **Description**, and **Test expectations** (sub-bulleted behavior / edge case / error condition).
- The in-plan (during-review) task-spec template differs slightly (lines 204–215): bullets include **Phase**, **Target files**, **Dependencies**, **LOC estimate**, optional **Sizing exception**, **Description**, **Test expectations**.
- Fix-task files (lines 499–504) additionally carry `fix_type: integration | ci | test` and live under `fixes/{type}-round-NN/`.
- Smoke-check binding: tasks adding/modifying routes, pages, layouts, or user-facing components must include a `smoke_checks:` block per `skills/plan/smoke-spec.md`.
- Visual-fidelity binding: when `config.md` carries `visual_fidelity_required: true`, UI-producing tasks must include `visual_fidelity_check.wireframe_refs` — enforced by a pre-fanout hard-gate (lines 548–556).

**Surprises:**
- The repository's top-level `templates/` directory holds only one file, `tsc-probe.ts`, and does not contain any markdown task template. All task-file templates are inline in `skills/plan/SKILL.md`.
- The in-plan task-spec template and the split task-file template are not identical: the in-plan version uses `### Task N` headings with a **Phase** bullet, while the split per-file version uses an `# Task NN` H1 with `phase:` in frontmatter instead.

**Caveats:** Investigation scope was limited to `skills/plan/` (SKILL.md, owns-defers.md, smoke-spec.md) and the repo's `templates/` directory. I did not exhaustively trace downstream consumers (`skills/implement/`, `agents/qrspi-implementer*.md`, `skills/test/`, `skills/integrate/`, `skills/parallelize/`) for additional template constraints they impose on `tasks/task-NN.md`. Field semantics described above are quoted from `skills/plan/SKILL.md`; conformance against downstream readers was not verified.

## Full findings

### Q6: Sub-subagent dispatch structure and post-approval split-into-task-files step

**Execution-model gating (SKILL.md lines 52–53, 105–106).** The SKILL declares: "**Subagent** produces `plan.md` overview. For large plans (6+ tasks), individual task specs are farmed out to sub-subagents (one per task or related group) to keep context manageable. Iterative with human feedback." Sub-subagent dispatch is unambiguously size-gated:
- `<6 tasks`: "the overview subagent writes the full merged `plan.md` directly (overview + task specs in one document)." (line 103)
- `≥6 tasks`: "the overview subagent writes `plan.md` with only the overview section (phase structure, task ordering, dependency graph). Individual task specs are dispatched to sub-subagents." (line 105)

**Sub-Subagent Dispatch section (lines 119–132).** This is the explicit fan-out section. It documents:
1. A pre-fanout compaction checkpoint (lines 121–123) with the rationale: "Per-task spec-generation sub-subagent fan-out: one subagent per task; aggregate output is large and the orchestrator must hold all returned task files plus the merged plan.md for the upcoming review round. Saturated context at this site corrupts the single-source-of-truth invariant on merge." A `TaskCreate({ subject: "Recommend /compact (pre-fanout) — plan", ... })` is dispatched as the user-facing prompt.
2. Sub-subagent inputs (lines 127–130): `plan.md` overview, relevant sections of `structure.md`, `design.md` (for test strategy and vertical slice context).
3. Merge contract (line 132): "Each sub-subagent writes `tasks/task-NN.md`. After all complete, the Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files — creating a single document as the only source of truth during review."

Notably, the SKILL does not specify the agent file or model used for sub-subagent dispatch — it says only "sub-subagents" generically. The dispatch is described prosaically, not with an explicit `Agent({ subagent_type: ..., model: ... })` call signature as appears elsewhere in the SKILL for reviewer dispatches.

**Per-task classification step (lines 134–162).** Every task spec — whether emitted by the merged-plan subagent OR by a per-task sub-subagent — must set `task_type` and `model` in its frontmatter. The SKILL provides explicit assignment rules (lightweight glob match, default code; opus when target files >3, core-surface glob match, fix-task retry, or sizing_exception; otherwise sonnet).

**Where the post-approval split-into-task-files step lives.** Two coordinated sites in the SKILL flow describe the split. The active, authoritative location is "Human Gate" → "On approval" (lines 411–423):

> **On approval:**
>
> 1. If reviews have NOT passed clean ... ask the user before proceeding ...
> 2. **Recommend compaction before splitting:** "Plan approved. This is a good point to compact context (`/compact`) before I split tasks into individual files — the split is mechanical and doesn't need the full conversation history." Wait for the user to compact (or decline), then proceed.
> 3. **Split:** Split task sections into individual `tasks/task-NN.md` files, then reduce `plan.md` to overview-only, then write `status: approved` in `plan.md` frontmatter. This ensures `tasks/*.md` files exist before `plan.md` is marked approved, avoiding a transient state where downstream skills see an approved plan but no task files.

The same split is summarized in "Merge/Split Mechanics" (lines 443–447):

> - **Before review:** For large plans (6+ tasks), sub-subagents write `tasks/task-NN.md` files → Plan skill reads all task files, appends them as sections to `plan.md`, then deletes the individual `tasks/task-NN.md` files → single document is the only source of truth during review. For small plans (<6 tasks), the plan subagent writes the merged `plan.md` directly.
> - **During review:** All changes happen in the single `plan.md` — `tasks/` directory is empty, no dual source of truth.
> - **After approval:** Plan skill splits each `### Task N` section back into `tasks/task-NN.md` files, then reduces `plan.md` to overview-only (removing the appended task specs). No duplication.

The split is described as **main-chat work performed by the Plan skill orchestrator itself**, not delegated to a sub-subagent. No `Agent(...)` dispatch is documented for the split step.

**Quick-fix branch (lines 107–117).** Quick fix mode bypasses sub-subagent fan-out entirely. The plan subagent produces a single-task plan directly; after approval, "the single task is written to `tasks/task-01.md` and `plan.md` is reduced to overview-only (same mechanics as full pipeline, but always exactly one task)." (line 115)

**Quick-fix auto-approve branch (lines 425–441).** When `pipeline: quick`, the human-approval gate is conditionally skipped after a review round produces zero kept findings (with verifier-gate precondition). When the gate fires, "the split, `status: approved` write, and `phase_start_commit` capture proceed automatically without waiting for user input." (line 427)

**`phase_start_commit` capture (lines 511–515).** Coincident with the split + `status: approved` write, the SKILL captures `git rev-parse HEAD` into `plan.md` frontmatter's `phase_start_commit:` field.

**Terminal-state commit (line 521).** "If the artifact directory is inside a git repository, commit the approved `plan.md`, all `tasks/task-NN.md` files, and the `reviews/plan/` directory."

### Q7: Canonical task-file templates and frontmatter/section contracts

**Repo-level `templates/` directory.** `/Users/dfrysinger/Documents/claude-workspace/qrspi-marketplace/qrspi-plus/templates/` contains exactly one file: `tsc-probe.ts`. There is no `templates/task-NN.md` or any markdown task template at this location. Searches for `task-NN` and `tasks/task-` across `skills/plan/` and `templates/` returned only references to the inline templates inside `skills/plan/SKILL.md` (no separate template file).

**Inline template 1 — In-plan during-review task-spec format (`skills/plan/SKILL.md` lines 168–218).** Under "Plan Document Structure (During Review)", a markdown fenced block defines the merged `plan.md` template, which embeds per-task spec stanzas. The `plan.md` frontmatter declares:

```yaml
status: draft
phase_start_commit: null
test_writer_model: sonnet   # one of: sonnet | opus. default: sonnet.
```

The per-task spec stanza inside the merged plan uses `### Task N: {name}` headings, with these required bullets (lines 204–214):
- **Phase:** {N}
- **Target files:** {exact paths, create/modify}
- **Dependencies:** {task numbers or "none"}
- **LOC estimate:** ~{N}
- **Sizing exception:** {only present when the task is a legitimate bundle — schema migration, CI scaffolding, reusable primitives}
- **Description:** {claim-before-evidence; plain language; no signatures, no pseudocode, no rationale}
- **Test expectations:** bulleted behavior 1 / edge case 1 / error condition 1 (each a sub-bullet)

Per-phase acceptance criteria block (lines 183–198) lives under each `## Phase N: {name}` heading as a `### Phase N Acceptance Criteria` subsection containing checkbox bullets.

Conformance constraints documented at lines 220–222: required-section presence (every bullet header above is required); claim-line ≤ 250 chars per bullet; description paragraph ≤ 150 words; section ≤ 300 words total before bullets are split; no brevity directives anywhere.

**Inline template 2 — Split per-file task format (`skills/plan/SKILL.md` lines 449–487).** Under "Merge/Split Mechanics" → "Split task file format", a markdown fenced block defines the post-approval `tasks/task-NN.md` template:

```markdown
---
status: approved
task: NN
phase: {phase number}
pipeline: full
goal_ids: [G1, G2]   # QRSPI-internal traceability metadata
task_type: code      # one of: code | lightweight. default: code.
model: sonnet        # one of: sonnet | opus. default: sonnet.
# Optional: sizing_exception: <one-line reason>
# Optional visual-fidelity binding block:
# visual_fidelity_check:
#   wireframe_refs:
#     - <path-or-URL-to-wireframe>
#   ui_producing: true
---

# Task NN: {name}

- **Target files:** {exact paths, create/modify}
- **Dependencies:** {task numbers or "none"}
- **LOC estimate:** ~{N}
- **Description:** {what this task accomplishes — substantive WHY only; no ID echoes}
- **Test expectations:**
  - {behavior 1}
  - {edge case 1}
  - {error condition 1}
```

**Frontmatter contract for `tasks/task-NN.md`.** Required fields, semantics, and authoring rules:

- `status` — `approved` after split; the SKILL writes this value as the final step of the on-approval flow (line 421).
- `task` — task number (NN).
- `phase` — phase number this task belongs to.
- `pipeline` — copied from `config.md`'s `pipeline` value at plan time (line 491). Permitted values: `full`, `quick`. The implementer per-task dispatch reads this for per-task input gating.
- `goal_ids` — list of IDs from `goals.md` (e.g., `[G1, G2]`). Phase-scoped: line 57 — "must contain only IDs of goals in goals.md" and only goals in the current phase. Strictly metadata; the body must not echo these IDs (ID-Hygiene Contract at lines 489–490).
- `task_type` — `code | lightweight`, default `code`. Lightweight assignment rules at lines 138–148 (glob match against `skills/**/SKILL.md`, `skills/**/templates/*.md`, `agents/qrspi-*.md`, `docs/**/*.md` excluding `docs/qrspi/**`, `*.md` at repo root). Edge cases: mixed targets → `code`; frontmatter-only `agents/*.md` edit → `lightweight`; new file creation uses planned final path.
- `model` — `sonnet | opus`, default `sonnet`. Assignment rules at lines 150–158: lightweight → sonnet (no exception); code → opus if target files >3, core-surface glob match, fix-task retry (`fix_task_retry: true`), or `sizing_exception` present; otherwise sonnet. Operator-overridable before plan approval (line 160).
- `sizing_exception` — optional; "Reason must be one of: schema migration, CI scaffolding, reusable primitives." Justifies a deliberate bundle (multi-handler or >200 LOC).
- `visual_fidelity_check` — optional block; mandatory only on UI-producing tasks when `config.md` carries `visual_fidelity_required: true`. Sub-fields: `wireframe_refs:` (list, one entry per cited wireframe artifact) and `ui_producing:` (boolean). Enforced by a pre-fanout hard-gate at lines 548–556. Whole-block omission treated as `ui_producing: false`; present-block-missing-`ui_producing` is a hard parse error.

**Fix-task frontmatter additions (lines 499–504).** Fix-task files additionally carry `fix_type: integration | ci | test`, written by Integrate or Test. Fix tasks are stored under `fixes/{type}-round-NN/` and follow the same format as regular tasks so the Implement skill processes them identically.

**Body section contract for `tasks/task-NN.md`.** The split template prescribes:
1. H1: `# Task NN: {name}` — task title naming exactly one observable behavior. The Task Sizing section (line 61) forbids `+` joining feature names and forbids "two distinct verbs joined by `and`".
2. **Target files** bullet — exact paths to create/modify. Per the comment at line 464: "Target files are aspirational; deviation discipline lives in the per-task spec reviewer."
3. **Dependencies** bullet — task numbers or "none". Forward dependencies are forbidden (line 537 Red Flag).
4. **LOC estimate** bullet — `~N`. Target ~100 LOC; policy ceiling 200 LOC (line 64); >200 LOC requires `sizing_exception` (line 539 Red Flag).
5. **Description** bullet — substantive WHY only; "no ID echoes" per the ID-Hygiene Contract (line 489); plain language; no function signatures (defers to Structure), no pseudocode (defers to Implement), no architecture rationale (defers to Design).
6. **Test expectations** sub-bullet list — behaviors, edge cases, error conditions. Plain language only; no `expect(...)` or assertion code (defers to Implement-TDD).

**Optional smoke-check block (per `skills/plan/smoke-spec.md`).** Tasks adding/modifying a route, page, layout, or user-facing component MUST include a `smoke_checks:` block (lines 224 of SKILL.md; full convention in `smoke-spec.md`). Required fields per entry: `path`, `auth` (`none | signed-in | admin`), `expect_status`. Optional: `expect_body_contains`, `expect_body_not_contains`, `expect_location`, `expect_link_href_pattern`. The plan-level `smoke_auth:` sibling field declares the project's auth-scaffolding recipe.

**Project-level environment fields on `plan.md` (lines 226–233).** Not on per-task files, but consumed by the per-task implementer gate: `build_command` and `dev_command` (the latter required when any task declares `smoke_checks:`).

**Cross-skill ownership notes.** Plan OWNS (per `owns-defers.md`): ordered task specs, test expectations in plain language, dependencies, LOC estimates. Plan DEFERS: function signatures/type definitions/parameter shapes → `structure.md`; full assertion text / `expect(...)` / test code → Implement-TDD; line-by-line logic / control flow / pseudocode → Implement; architecture decisions and trade-offs → `design.md`; phasing / vertical-slice authoring / replan-gate criteria → `phasing.md`. Boundary-drift lexical signals enumerated at `owns-defers.md` lines 28–34 trigger scope-reviewer findings.
