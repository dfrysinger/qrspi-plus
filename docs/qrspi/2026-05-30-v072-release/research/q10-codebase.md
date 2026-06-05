---
status: draft
question_ids: [10]
research_type: codebase
---

# Q10: How does `skills/plan/SKILL.md` define the test expectations block and per-task spec template, including LOC ceiling guidance?

## Summary

**TL;DR:** `skills/plan/SKILL.md` defines a mandatory, flat bullet-list test-expectations block (behaviors, edge cases, error conditions in plain language) as part of a required six-field per-task spec template. LOC guidance establishes a ~100-LOC target and a hard 200-LOC policy ceiling (with a three-item closed exception set). In practice, task-09.md and task-10.md conform closely to the template, add a `**Manual Validation:**` extension section not prescribed by the template, and enumerate concrete test assertions rather than abstract behavior descriptions.

**Key findings:**
- The template's required body fields are: `Target files`, `Dependencies`, `LOC estimate`, `Description`, and `Test expectations`; each is a required structural slot per `SKILL.md:178`.
- The test-expectations block is defined as plain-language bullets covering behavior, edge cases, and error conditions — assertion code (`expect(...)`) is explicitly forbidden in the spec (`SKILL.md:224`).
- LOC ceiling: ~100-LOC target; 200-LOC policy ceiling; split required above 200 unless `sizing_exception` names one of three closed reasons: schema migration, CI scaffolding, reusable primitives (`SKILL.md:65`).
- LOC counts implementation source only (excluding `tests/`); test code has no ceiling but follows a 1.5–2× rule of thumb relative to impl LOC (`SKILL.md:67`).
- TDD tasks must carry a dispatch-ordering note ("Dispatch order: test-writer first, implementer second (RED-verification gate between)") inside `Description` or at the top of `Test expectations` (`SKILL.md:144–146`).
- The split task file template prescribes a YAML frontmatter block with required fields: `status`, `task`, `phase`, `pipeline`, `goal_ids`, `task_type`, `model`; optional commented fields: `sizing_exception`, `reference_gate`, `reference_artifact`, `ui`, `lift_source`, `visual_fidelity_check` (`SKILL.md:484–521`).
- Task-09 and task-10 exactly follow the required field set and add a `**Manual Validation:**` section not in the template — used for verifications that cannot be automated at BATS level.
- Task-09 carries `sizing_exception` (schema migration) with a one-line rationale, consistent with the closed-exception rule; LOC estimate is ~90 despite 42 target files.
- Task-10 has no `sizing_exception`; LOC estimate is ~80; three target files — stays well under the 200-LOC ceiling with no exception needed.
- Test enumeration in task-09 and task-10 is highly concrete: each bullet names a specific file, specific field, and specific expected value or assertion behavior, closely resembling assertions rather than abstract behavior statements.
- Task-10's test expectations cross-reference the structural lint file created by task-09, forming an explicit cross-task contract within the test-expectations block itself.

**Surprises:** The `**Manual Validation:**` section appears on task-09, task-08, and task-10 but is entirely absent from the template in SKILL.md — it is a de facto extension used when BATS-level automation is impractical (e.g., git introspection across 41 files, or a fresh-install smoke check). Task-05 demonstrates a `status: withdrawn` lifecycle state not described in the task-file format section of SKILL.md, suggesting at least one lifecycle path exists beyond `approved`.

**Caveats:** Only task-01 through task-10 were examined from the v071-hardening run; tasks from other runs were not checked. The `smoke-spec.md` and `owns-defers.md` companion files in `skills/plan/` were not fully read — they may define additional test-expectations conventions. The SKILL.md `!cat skills/plan/owns-defers.md` inline include directive (`SKILL.md:18`) means `owns-defers.md` content is part of the live skill but was read separately.

---

## Full findings

### Template definition in `skills/plan/SKILL.md`

#### Plan-document-level structure (review artifact, `plan.md`)

Defined at `SKILL.md:180–230`. The `plan.md` template frontmatter during review carries:
- `status: draft`
- `phase_start_commit: null`
- `test_writer_model: sonnet` (operator-overridable; comment explains when to flip to `opus`)

Per-task blocks inside `plan.md` (before split) use the heading shape:
```
### Task 1: {name — names exactly one observable behavior; no `+`; no two distinct verbs joined by `and`}
```

Required bullet fields per task (all mandatory — `SKILL.md:178,217–226`):
- `Phase`
- `Target files` — exact paths with create/modify labels
- `Dependencies` — task numbers or "none"
- `LOC estimate` — `~{N}`
- `Sizing exception` — optional; only when in closed exception set
- `Description` — observable-behavior claim first, then context; ≤150 words; no function signatures, no pseudocode, no architecture rationale
- `Test expectations` — plain-language bullets: behavior, edge case, error condition

#### Per-task spec file template (split artifact, `tasks/task-NN.md`)

Defined at `SKILL.md:482–538`. The YAML frontmatter for a split task file:

```yaml
status: approved
task: NN
phase: {phase number}
pipeline: full
goal_ids: [G1, G2]
task_type: code      # code | lightweight. default: code
model: sonnet        # sonnet | opus. default: sonnet
# Optional (commented by default):
# sizing_exception: <one-line reason>
# reference_gate: true
# reference_artifact: path/to/source-of-truth.md
# ui: true
# lift_source: path/to/existing-source.md
# visual_fidelity_check:
#   wireframe_refs: [...]
#   ui: true
```

Body structure matches the in-plan template:
```markdown
# Task NN: {name}

- **Target files:** {exact paths, create/modify}
- **Dependencies:** {task numbers or "none"}
- **LOC estimate:** ~{N}
- **Description:** {observable-behavior claim first; no ID echoes; no function signatures}
- **Test expectations:**
  - {behavior 1}
  - {edge case 1}
  - {error condition 1}
```

An optional `SPEC OVERRIDES SOURCE` HTML comment block is required (not optional) when both `ui: true` and `lift_source: <path>` are set in frontmatter (`SKILL.md:534–538`).

#### Test expectations block definition

The test-expectations block is specified at `SKILL.md:223–226`:
- Format: flat bullet list
- Content: plain language; no `expect(...)` or assertion code (those belong to Implement-TDD)
- Required bullet types: behavior, edge case, error condition (three archetypes listed in template placeholders)
- The "Test Coverage Reviewer" agent (`qrspi-plan-test-coverage-reviewer`) reviews: behavioral coverage, edge cases, error conditions, test expectation quality, missing design scenarios (`SKILL.md:260`)

The dispatch-ordering note requirement for TDD tasks (`SKILL.md:144–148`):
> "Dispatch order: test-writer first, implementer second (RED-verification gate between)."
This note must appear inside `Description` or at the top of `Test expectations`. `task_type: lightweight` tasks omit it.

#### LOC ceiling guidance

From `SKILL.md:63–79`:
- **Target:** ~100 LOC (matches OpenAI AGENTS.md guidance for autonomous-agent task scope)
- **Policy ceiling:** 200 LOC — split required above this unless `sizing_exception` is documented
- **"LOC" definition:** implementation source only, counted across files in `Target files:` excluding `tests/`
- **Test code:** no ceiling; rule of thumb 1.5–2× impl LOC for full-behavior coverage
- **Exception set (closed):** schema migration, CI scaffolding, reusable primitives
- **Exception markup:** `sizing_exception: <reason>` in post-split task frontmatter, or **Sizing exception** bullet in in-plan task spec
- **Rationale cited:** SWE-Bench Pro median patch 107 LOC / 4.1 files, ~23% frontier-model success; OpenAI AGENTS.md ~100 lines; Cisco/SmartBear 200–400 LOC code-review sweet spot

The Red Flags section (`SKILL.md:622`) makes the ceiling a stop condition:
> "LOC estimate >200 without a `sizing_exception` ... naming one of the closed exception set"

The Iron Laws section (`SKILL.md:703`) restates it:
> "One task = one observable behavior, ~100-LOC target / ≤200 LOC ceiling."

#### Conformance constraints on the spec writer

From `SKILL.md:234`:
- Required-section presence (all bullet headers are mandatory)
- Claim-line length ≤250 chars per bullet
- Description paragraph ≤150 words
- Section ≤300 words total before bullets are split
- No brevity directives anywhere ("be concise", "brief summary", "≤ N lines" are forbidden in the spec body)

---

### Representative tasks: task-09.md and task-10.md

#### task-09.md (`tasks/task-09.md`)

**Frontmatter:** `status: approved`, `task: 9`, `phase: 1`, `pipeline: full`, `goal_ids: [G7b]`, `task_type: code`, `model: opus`

**Sizing exception present:** Yes — `sizing_exception: schema migration -- 41 agent frontmatter files each receive an identical single-line 'model:' key deletion; bundled for atomicity so the no-model-field invariant is established in one commit and the structural lint (written first in RED) can sweep all 41 files in a single pass.`

This is the first of the three closed exception types (schema migration), correctly documented with a one-line rationale.

**Target files:** 42 files listed (41 agent `.md` files to modify + 1 BATS test to create). The unusual breadth of target files is precisely what motivates the `sizing_exception`.

**LOC estimate:** ~90 (below the 200-LOC ceiling even with 42 files, because each agent file gets a single-line deletion).

**Dependencies:** none

**Description:** 96 words. Leads with the observable behavior claim ("The top-level `model:` YAML frontmatter key is deleted from all 41 `agents/qrspi-*.md` files."). Names what is NOT modified (tier-name references in dispatcher prose). Ends with the dispatch-ordering note: "Dispatch order: test-writer first, implementer second (RED-verification gate between)." — consistent with `SKILL.md:144–146`.

**Test expectations (4 bullets):**
1. `tests/unit/test-agent-frontmatter-no-model.bats` contains a test that sweeps every file matching `agents/qrspi-*.md` and fails if any frontmatter block carries a standalone top-level `model:` key
2. After all 41 agent files are modified, the structural lint test passes with zero violations reported
3. All other frontmatter keys (`skills:`, `description:`, `name:`, and any agent-specific keys) are unmodified
4. The structural lint test fails clearly in RED for each file that still carries a `model:` key, providing a useful per-file failure message

Each bullet is concrete and verifiable. Bullet 2 is a GREEN-phase acceptance criterion. Bullet 4 is a RED-phase diagnostic quality criterion — unusual in that it explicitly addresses the quality of the RED failure mode itself, not just the GREEN pass.

**Manual Validation section (not in template):**
```
**Manual Validation:**
- Pre-merge: `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` for the Task 9 commit shows exactly 41 files changed, each with one line removed and zero lines added ...
```
This section is present but not prescribed by the SKILL.md template. It documents a verification step the operator must perform manually because BATS-level git introspection is impractical at this scope.

#### task-10.md (`tasks/task-10.md`)

**Frontmatter:** `status: approved`, `task: 10`, `phase: 1`, `pipeline: full`, `goal_ids: [G7b]`, `task_type: code`, `model: opus`

**No sizing_exception.** Target files: 3. LOC estimate: ~80.

**Dependencies:** Task 8, Task 9 — two cross-task dependencies.

**Description:** Highly detailed (approximately 130 words). Specifies exact concrete model IDs to populate (`claude-haiku-4.5`, `claude-sonnet-4.6`, `claude-opus-4.7-high`) and the rationale (Copilot CLI "model not available" warning avoidance with full versioned IDs). The dispatch-ordering note is embedded at the end: "Dispatch order: test-writer first, implementer second (RED-verification gate between)."

**Test expectations (7 bullets):**
1. `config.md` contains `claude-haiku-4.5` as the haiku-tier entry in `model_routing` table for both host columns
2. `config.md` contains `claude-sonnet-4.6` as the sonnet-tier entry for both host columns
3. `config.md` contains `claude-opus-4.7-high` as the opus-tier entry for both host columns
4. `config.md` contains `claude-sonnet-4.6` as the inherit-tier entry for both host columns
5. No entry in the `copilot-cli` column is a bare Claude tier short-form (the strings `haiku`, `sonnet`, or `opus` alone) that would trigger a Copilot CLI "model not available" warning
6. `skills/using-qrspi/SKILL.md` contains a Model Routing section that names `detect_host` output as the host-selection input and the `model_routing` table as the per-tier resolution source
7. The extended structural lint assertions in `tests/unit/test-agent-frontmatter-no-model.bats` fail in RED when the `model_routing` table is absent or missing a required host/tier entry, and pass GREEN when all required entries are present

Bullet 5 is a negative assertion (exclusion of bare tier names) — an error-condition archetype. Bullet 7 explicitly references the test file created in task-09, creating a documented cross-task contract within the test-expectations block.

**Manual Validation section:**
```
**Manual Validation:**
- Fresh-install smoke check: a freshly installed copy of the plugin on Copilot CLI emits zero "model not available" warnings when an agent dispatch resolves through the `model_routing` table (Design Test Strategy labels this as manual).
```

---

### Observable patterns across all 10 tasks

| Task | task_type | model | LOC est. | sizing_exception | Manual Validation | # Test expectations |
|------|-----------|-------|----------|------------------|-------------------|---------------------|
| 01   | code      | sonnet| ~90      | no               | no                | ~4                  |
| 02   | code      | sonnet| ~40      | no               | no                | ~3                  |
| 03   | code      | sonnet| ~110     | no               | no                | ~5                  |
| 04   | code      | opus  | ~120     | no               | no                | ~5                  |
| 05   | code      | sonnet| —        | —                | —                 | 0 (withdrawn)       |
| 06   | code      | sonnet| ~100     | no               | no                | ~5                  |
| 07   | code      | opus  | ~90      | no               | no                | ~4                  |
| 08   | code      | opus  | ~150     | no               | yes               | ~6                  |
| 09   | code      | opus  | ~90      | yes (schema)     | yes               | 4                   |
| 10   | code      | opus  | ~80      | no               | yes               | 7                   |

**All 10 tasks are `task_type: code`** — no lightweight tasks in this plan; all go through the TDD path.

**`model: opus` appears on tasks 04, 07, 08, 09, 10.** Cross-referencing the SKILL.md heuristic (`SKILL.md:165–170`): task-04 has 3 target files including `skills/parallelize/SKILL.md` (core surface glob match); task-07 has `skills/using-qrspi/SKILL.md` (core surface); task-08 has 9 target files (count > 3); task-09 has `sizing_exception` (explicitly listed as an `opus` trigger); task-10 has 3 target files including `skills/using-qrspi/SKILL.md` (core surface). All `opus` assignments are consistent with the documented heuristic.

**LOC estimates all stay at or below ~150** (task-08 at ~150 is the highest). No task except task-09 invokes a `sizing_exception`, consistent with the policy ceiling enforcement.

**Scope breadth in test expectations:** Tasks with a single focused behavior (task-02, ~40 LOC) have 3 test bullets; tasks with multiple observable sub-behaviors (task-10, 7 bullets covering 4 tier entries + 1 negative constraint + 1 prose check + 1 RED/GREEN lint assertion) have more. There is no fixed bullet count in the template; the count scales with the number of distinct verifiable behaviors the task produces.

**Cross-task contracts in test expectations:** Task-10 bullet 7 explicitly names the test file from task-09 and specifies its RED/GREEN behavior — the only observed case where a test-expectations bullet directly cross-references a prior task's artifact. This pattern is not prescribed by the template but is not prohibited; the template permits "error condition" bullets that happen to reference cross-task artifacts.

**The `**Manual Validation:**` section** appears on tasks 08, 09, and 10 — the three tasks where complete automated BATS coverage was deemed impractical (multi-file git diff verification in task-09; fresh-install runtime check in task-10; cache-retirement runtime check in task-08). This block is a de facto extension layer on top of the template, used when the BATS harness boundary is explicitly reached.

**Task-05 withdrawn state:** `status: withdrawn` with a three-pointer body (plan.md rationale, goals.md closure entry, evidence file path). This lifecycle path exists in practice but is not described in the split-task-file format section of SKILL.md.
