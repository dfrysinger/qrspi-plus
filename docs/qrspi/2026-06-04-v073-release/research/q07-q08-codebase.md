---
status: draft
question_ids: [7, 8]
research_type: codebase
---

# Q7, Q8: Apply-Fix Protocol — Per-Step Upstream-Artifact List and Full vs. Quick-Fix Artifact Gating

## Summary

**TL;DR:** The per-step upstream-artifact list for the apply-fix protocol is documented in `skills/using-qrspi/SKILL.md` § Standard Review Loop (step 4, verifier dispatch) at lines 827–838; it covers eight pipeline steps (Goals through Replan) but excludes Plan, Implement, Integrate, and Test. Full-pipeline and quick-fix modes differ substantially in which artifacts each step requires, with the differences documented in two places: the high-level table in `skills/using-qrspi/SKILL.md` § Artifact Gating (lines 210–226) and the detailed HARD-GATE contract in `skills/implement/SKILL.md` § Artifact Gating (lines 70–117).

**Key findings:**
- The per-step upstream-artifact list lives in `skills/using-qrspi/SKILL.md:827–838` under the `upstream_paths` parameter description of the verifier dispatch block; it is organized as a labelled text enumeration, one step per line.
- Eight pipeline steps have canonical entries: Goals, Questions, Research, Design, Phasing, Structure, Parallelize, and Replan. Plan, Implement, Integrate, and Test have no canonical entries in that list.
- Every step also receives two SKILL paths appended unconditionally: `skills/<step>/SKILL.md` and `skills/using-qrspi/SKILL.md`.
- The Artifact Gating section in `skills/using-qrspi/SKILL.md` (lines 210–226) is the primary place where per-step prerequisites are stated for all pipeline steps in both modes.
- Full-pipeline Implement requires seven artifacts (including `parallelization.md`, `design.md`, `phasing.md`, `structure.md`); quick-fix Implement requires only five (dropping those four). Plan and Test also have smaller prerequisite sets in quick-fix mode.
- The per-task dispatch table (`implement/SKILL.md:98–105`) distinguishes `pipeline: quick` from `pipeline: full` at the individual task level, independently of the route-level mode.

**Surprises:** The per-step upstream-artifact list in the verifier dispatch block (Q7's subject) does not include Plan, Implement, Integrate, or Test steps at all — only the eight artifact-producing steps up to Replan. The `Replan` entry uses a placeholder value `replan-trigger-source` rather than a concrete artifact path.

**Caveats:** The `skills/integrate/SKILL.md` and `skills/plan/SKILL.md` files were not fully read; their internal artifact gating prose may add further detail not captured by the using-qrspi summary table. The `build/skills/` directory contains parallel copies of the skill files; only the canonical `skills/` directory versions were read.

---

## Full findings

### Q7: Per-step upstream-artifact list organization and canonical entries

#### Location and structure

The per-step upstream-artifact list is embedded in **`skills/using-qrspi/SKILL.md`**, lines **827–838**, inside the verifier dispatch parameter derivation block within "§ Standard Review Loop" (step 4 — verifier fan-out). The text reads:

```
Per-step upstream-artifact lists:
  Goals:       (no upstream artifacts; SKILL paths only)
  Questions:   goals.md
  Research:    goals.md, questions.md
  Design:      goals.md, questions.md, research/summary.md
  Phasing:     goals.md, design.md
  Structure:   goals.md, design.md, phasing.md
  Parallelize: goals.md, design.md, structure.md
  Replan:      plan.md, replan-trigger-source
SKILL paths appended on every step:
  skills/<step>/SKILL.md
  skills/using-qrspi/SKILL.md
```

The list appears as part of the `upstream_paths` parameter description (`skills/using-qrspi/SKILL.md:805–838`). The `upstream_paths` parameter is a newline-separated list of absolute paths passed to `qrspi-finding-verifier` so it can read pipeline-context documents. The parameter carries two categories: (a) the upstream artifacts the current step consumes per pipeline order, and (b) the SKILL paths for lazy-Read context.

#### Pipeline steps with canonical entries

The following eight pipeline steps have canonical entries in the list:

| Step | Canonical upstream artifacts |
|------|------------------------------|
| Goals | (none — SKILL paths only) |
| Questions | `goals.md` |
| Research | `goals.md`, `questions.md` |
| Design | `goals.md`, `questions.md`, `research/summary.md` |
| Phasing | `goals.md`, `design.md` |
| Structure | `goals.md`, `design.md`, `phasing.md` |
| Parallelize | `goals.md`, `design.md`, `structure.md` |
| Replan | `plan.md`, `replan-trigger-source` |

**Steps with no canonical entry:** Plan, Implement, Integrate, and Test have no entries in this list. This matches the verifier's scope: verifier dispatches in the Standard Review Loop are described for artifact steps only (i.e., single-file reviewed artifacts). The Standard Review Loop in `using-qrspi/SKILL.md` defines `artifact_path` as applicable to `{goals, questions, research, design, phasing, structure, parallelize, replan}` (`skills/using-qrspi/SKILL.md:815–817`). Plan, Implement (per-task code), Integrate, and Test use different dispatch structures.

#### SKILL paths

The two SKILL paths appended on every step are:
- `skills/<step>/SKILL.md` (where `<step>` is the dispatching step name)
- `skills/using-qrspi/SKILL.md`

These are present on every step including Goals (which has no upstream artifacts), making Goals' full `upstream_paths` list exactly those two SKILL files.

#### Cross-reference: Artifact Gating prerequisite table

A parallel (but different) per-step prerequisite list appears in **`skills/using-qrspi/SKILL.md`**, lines **210–226**, under "§ Artifact Gating". That section lists run-time prerequisites for each skill's entry condition (not the verifier dispatch's `upstream_paths`). The two lists are related but not identical — the Artifact Gating table covers all pipeline steps including Plan, Implement, Integrate, and Test, and it distinguishes full-pipeline from quick-fix mode.

---

### Q8: Artifact gating differences between full-pipeline and quick-fix modes, and documentation locations

#### Route-level step differences

The pipelines themselves differ structurally (`skills/using-qrspi/SKILL.md:37–49`):

- **Full pipeline:** Goals → Questions → Research → Design → Phasing → Structure → Plan → Parallelize → Implement → Integrate → Test → Replan
- **Quick fix:** Goals → Questions → Research → Plan → Implement → Test

Quick fix omits Design, Phasing, Structure, Parallelize, and Integrate entirely — those steps have no prerequisites to satisfy because they do not run.

#### Per-step prerequisite differences (both modes)

Documented in **`skills/using-qrspi/SKILL.md:210–226`**:

| Step | Full pipeline prerequisites | Quick fix prerequisites |
|------|----------------------------|------------------------|
| Goals | None (first step) | None (first step) |
| Questions | `goals.md` approved | `goals.md` approved |
| Research | `questions.md` approved | `questions.md` approved |
| Design | `goals.md`, `research/summary.md` approved | _(step does not run)_ |
| Phasing | `goals.md`, `questions.md`, `research/summary.md`, `design.md` approved | _(step does not run)_ |
| Structure | `goals.md`, `research/summary.md`, `design.md`, `phasing.md` approved | _(step does not run)_ |
| Plan | `goals.md`, `research/summary.md`, `design.md`, `phasing.md`, `structure.md` approved | `goals.md`, `research/summary.md` approved |
| Parallelize | `plan.md`, `tasks/*.md`, `phasing.md`, `config.md` approved | _(step does not run)_ |
| Implement | `parallelization.md`, `plan.md`, `tasks/*.md` / `fixes/…`, `design.md`, `phasing.md`, `structure.md`, `config.md` | `plan.md`, `tasks/*.md` / `fixes/…`, `goals.md`, `research/summary.md`, `config.md` |
| Integrate | All `reviews/tasks/`, `design.md`, `phasing.md`, `structure.md`, `parallelization.md`, `config.md` | _(step does not run)_ |
| Test | `goals.md`, `design.md`, `phasing.md` approved, `fixes/` dir, merged implementation | `goals.md`, `research/summary.md` approved, `fixes/` dir, merged implementation |

#### Detailed Implement artifact gating

The most detailed gating specification is in **`skills/implement/SKILL.md`**, lines **70–117**, § Artifact Gating:

**Full pipeline required inputs** (`skills/implement/SKILL.md:74–82`):
- `parallelization.md` with `status: approved`
- `plan.md` with `status: approved`
- `tasks/*.md` (current phase) or `fixes/{type}-round-NN/*.md`
- `design.md` with `status: approved`
- `phasing.md` with `status: approved`
- `structure.md` with `status: approved`
- `config.md`

**Quick fix required inputs** (`skills/implement/SKILL.md:84–90`):
- `plan.md` with `status: approved`
- `tasks/*.md` (typically one) or `fixes/{type}-round-NN/*.md`
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `config.md`

The HARD-GATE at `skills/implement/SKILL.md:111–117` enforces these requirements: "Do NOT dispatch implementer subagents without the mode-appropriate approved inputs (full: `parallelization.md`; quick: approved `tasks/*.md` or approved `fixes/{type}-round-NN/*.md` per the dispatch shape)."

#### Per-task input routing (inside Implement)

Beyond the run-level gating, each individual task file carries a `pipeline` field that controls which artifacts are loaded into that task's implementer and reviewer prompts. This is documented in **`skills/implement/SKILL.md`**, lines **94–106**, § Per-Task Input Routing:

| Input | `pipeline: quick` | `pipeline: full` |
|-------|-------------------|------------------|
| `task-NN.md` (full text) | Yes | Yes |
| `goals.md` approved | Yes | Yes |
| `research/summary.md` approved | Yes | No |
| `design.md` approved | No | Yes |
| `structure.md` approved | No | Yes |
| `parallelization.md` approved | No | Yes |

The `companion_pipeline_inputs` dispatch parameter (`skills/implement/SKILL.md:657`) carries the appropriate set: "full pipeline: `goals.md`, `design.md`, `structure.md`, `parallelization.md` excerpts; quick fix: `goals.md`, `research/summary.md`."

#### N=1 dynamic skip: Artifact Gating suspension

A special case documented at **`skills/implement/SKILL.md:290`**: when exactly one task is in the batch, a dynamic skip branch fires that bypasses Parallelize and Integrate. For this branch, "the standard Artifact Gating requirement for `parallelization.md` with `status: approved` (see § Artifact Gating — Full pipeline) is **suspended**." The `branch: skip-parallelize-integrate` audit label in the config append records that this suspension is in effect.

#### Summary of documentation locations

| Content | Primary location |
|---------|-----------------|
| Pipeline routes (full vs. quick) | `skills/using-qrspi/SKILL.md:37–49` |
| Per-step prerequisite list (all steps, both modes) | `skills/using-qrspi/SKILL.md:210–226` |
| Detailed Implement gating (full vs. quick, with HARD-GATE) | `skills/implement/SKILL.md:70–117` |
| Per-task input routing table | `skills/implement/SKILL.md:94–106` |
| `companion_pipeline_inputs` dispatch parameter | `skills/implement/SKILL.md:657` |
| N=1 skip / parallelization.md suspension | `skills/implement/SKILL.md:290` |
| Quick-fix route behavioral semantics | `skills/using-qrspi/SKILL.md:400–408` |
