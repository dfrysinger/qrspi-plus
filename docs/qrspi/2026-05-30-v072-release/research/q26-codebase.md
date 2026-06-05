---
status: draft
question_ids: [26]
research_type: codebase
---

# Q26: Artifact-content delivery to reviewer subagents — `artifact_body:` vs `artifact_path:` inventory

## Summary

**TL;DR:** The `reviewer-protocol/SKILL.md` § Reviewer Dispatch Contract specifies `artifact_body` (wrapped-inline form) as the single, unconditional mechanism for passing artifact content to reviewer subagents. The parameter `artifact_path` never appears in any reviewer dispatch shape in any per-skill SKILL.md; it appears only in scope-tagger dispatches (set to literal `null` for multi-file artifacts) and in git-diff shell commands (not dispatch parameters). No conditions or criteria for choosing between forms are defined anywhere in the current contract.

**Key findings:**
- `artifact_body` appears in all 10 per-skill reviewer dispatch shapes (goals, questions, research, design, phasing, structure, plan, parallelize, implement, integrate/test) and is specified unconditionally.
- For implement/integrate/test, the code-under-review is passed via `subject_code` (same wrapped-inline pattern, different parameter name) rather than `artifact_body`, per the note at `reviewer-protocol/SKILL.md:42` which says "`artifact_body` (or `subject_code`, per-step)".
- The research step is the one partial exception: the primary artifact (`research/summary.md`) uses `artifact_body`, but the companion `q*.md` files are passed via `companion_qfile_paths` — a list of absolute paths the reviewer agent Reads directly (explicitly labelled "path-based, not inline-concatenated" at `research/SKILL.md:151`).
- `artifact_path` appears in reviewer-adjacent contexts only: (1) scope-tagger dispatch parameters (set to `null` for multi-file steps), (2) the shell command argument `git diff <ref> -- <artifact_path>` for diff-file generation, and (3) `docs/qrspi/2026-05-30-v072-release/goals.md:849` documenting an ad-hoc v0.7.2 self-host workaround where `artifact_path` was passed instead of the wrapped body — explicitly described as outside the contract.
- The dispatch contract currently provides no conditions, thresholds, or criteria for choosing between wrapped-body inline and path-based forms.

**Surprises:** The research step's `companion_qfile_paths` (path-based) pattern is the only currently-prescribed path-based delivery mechanism in any reviewer dispatch — but it applies only to companion files, not to the primary artifact (`research/summary.md` still uses `artifact_body`). The `goals.md:849` entry explicitly documents that a path-based workaround (`artifact_path: <abs>`) was used ad hoc during the v0.7.2 self-host without any contract backing.

**Caveats:** The replan SKILL.md was not individually verified (it is listed in the Expected-Reviewer Matrix at `reviewer-protocol/SKILL.md:32` but was not a named target in this question). The scripts directory contains no `artifact_path` or `artifact_body` references — confirmed by `grep` returning no matches.

---

## Full findings

### `reviewer-protocol/SKILL.md` § Reviewer Dispatch Contract

**File:** `skills/reviewer-protocol/SKILL.md`  
**Section:** `## Reviewer Dispatch Contract` (lines 38–51)

The contract defines a fixed parameter list. The artifact-content parameter is defined at line 42:

> **`artifact_body`** (or `subject_code`, per-step) — the artifact under review wrapped between `<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>` / `<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>` markers per `## Untrusted Data Handling`.

`artifact_body` is the only content-delivery form named. No `artifact_path` parameter appears in this section. The term `artifact_path` appears at line 46 only inside a shell command illustration of diff-file generation:

> `git diff <ref> -- <artifact_path>` redirect

This is a Git command argument placeholder, not a reviewer dispatch parameter.

The `<diff_file_path>` parameter is a separate named dispatch parameter (line 46) carrying the absolute path to the pre-emitted diff file that the reviewer Reads with the Read tool — but this is the diff file, not the artifact body itself.

**No conditions for choosing between forms are defined.** The section describes `artifact_body` (inline-wrapped) as the unconditional mechanism for artifact content in all reviewer dispatches.

---

### Per-skill review sections — `artifact_body:` inventory

Each per-step SKILL.md prescribes reviewer dispatch shapes. Every shape specifies `artifact_body` as the wrapped-inline delivery parameter for the primary artifact. Below is the complete inventory by step.

#### Goals — `skills/goals/SKILL.md`

- **Line 241** (Claude quality-reviewer): `` `artifact_body`: `goals.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=goals.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=goals.md>>>` markers ``
- **Line 251** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `goals.md` body ``
- Codex dispatches (lines 260+) pass the same `artifact_body` value via `--artifact-body goals.md` flag to `run-codex-review.sh`.

Two reviewers (quality + scope), both receiving `artifact_body` inline.

#### Questions — `skills/questions/SKILL.md`

- **Line 84** (Claude quality-reviewer): `` `artifact_body`: `questions.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=questions.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=questions.md>>>` markers ``
- `companion_goals` is also wrapped inline.
- Codex dispatch (lines 94+) similarly uses `--artifact-body questions.md`.

Questions has no scope-reviewer (canonical topology). One reviewer, `artifact_body` inline.

#### Research — `skills/research/SKILL.md`

- **Line 150** (Claude quality-reviewer): `` `artifact_body`: `research/summary.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=research/summary.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=research/summary.md>>>` markers ``
- **Line 151** (Claude quality-reviewer companion): `companion_qfile_paths`: list of absolute paths to every `research/q*.md` file — *"the agent Reads each path directly — the orchestrator does NOT embed file bodies inline. This is the canonical Claude reviewer dispatch parameter for Research (path-based, not inline-concatenated)."*

**Research is the only step where a path-based delivery mechanism (`companion_qfile_paths`) appears in the prescribed dispatch shape.** However, this applies to companion files (`q*.md`), not the primary artifact (`research/summary.md` still uses `artifact_body`). The Codex pipeline for Research cannot use `companion_qfile_paths` (Codex is in a read-only sandbox), so the Codex pipeline receives only `artifact_body` for `research/summary.md`.

No `artifact_path` parameter appears in the Research dispatch shape.

#### Design — `skills/design/SKILL.md`

- **Line 158** (Claude quality-reviewer): `` `artifact_body`: `design.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=design.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=design.md>>>` markers ``
- **Line 170** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `design.md` body ``
- Companion `companion_goals` and `companion_research` also wrapped inline.
- Codex dispatches (lines 179+) pass `--artifact-body design.md`.

Two reviewers (quality + scope), both `artifact_body` inline.

#### Phasing — `skills/phasing/SKILL.md`

- **Line 113** (Claude quality-reviewer): `` `artifact_body`: `phasing.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=phasing.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=phasing.md>>>` markers ``
- **Line 127** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `phasing.md` body ``
- Multiple companion bodies also wrapped inline (roadmap, pruned-pairs, snapshots).

Two reviewers, both `artifact_body` inline.

#### Structure — `skills/structure/SKILL.md`

- **Line 154** (Claude quality-reviewer): `` `artifact_body`: `structure.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=structure.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=structure.md>>>` markers ``
- **Line 168** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `structure.md` body ``
- Four companion bodies (goals, research, design, phasing) also wrapped inline.

Two reviewers, both `artifact_body` inline.

#### Plan — `skills/plan/SKILL.md`

- **Line 284** (Claude unified quality-reviewer): `` `artifact_body`: `plan.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=plan.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=plan.md>>>` markers ``
- **Line 296** (prose description of five plan-artifact reviewers): "Each dispatch reuses the **full plan-reviewer dispatch schema** (`artifact_body` + companions + route key + output + round + reviewer_tag)"
- **Line 304** (full per-artifact reviewer enumeration): "Each prompt body carries: `artifact_body` (wrapped `plan.md`); `companion_goals`, `companion_research`, `companion_phasing` (always)…"
- **Line 307** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `plan.md` body ``

Six quality/artifact reviewers + one scope-reviewer, all `artifact_body` inline. Codex pipeline (line 327) uses `--artifact-body plan.md`.

#### Parallelize — `skills/parallelize/SKILL.md`

- **Line 179** (Claude quality-reviewer): `` `artifact_body`: `parallelization.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=parallelization.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=parallelization.md>>>` markers ``
- **Line 191** (Claude scope-reviewer): `` `artifact_body`: same untrusted-data-wrapped `parallelization.md` body ``

Two reviewers, both `artifact_body` inline.

#### Implement — `skills/implement/SKILL.md`

Implement reviewers receive code (not a single artifact file), so the parameter name changes to `subject_code` per the `reviewer-protocol/SKILL.md:42` note. The inline-wrapped form is preserved:

- **Line 879** (example prompt block): `` subject_code: <<<UNTRUSTED-ARTIFACT-START id=src/lib/cas/artifacts.ts>>> `` — code file bodies wrapped inline.
- **Line 923**: `subject_code` — concatenated wrapped bodies of every production code file changed for this task.
- **Line 929**: "Each prompt body carries: `subject_code` + `task_definition` (always)"
- **Line 1009** (visual-fidelity reviewer dispatch): `artifact_body:` block with `<<<UNTRUSTED-ARTIFACT-START id=tasks/task-NN.md>>>` wrapping the task spec body.
- **Line 1028**: `` `artifact_body` — the task spec body wrapped between `<<<UNTRUSTED-ARTIFACT-START id=tasks/task-NN.md>>>` and matching END markers ``

All inline-wrapped, no path-based form. The `artifact_path` reference at line 1204 is within the **scope-tagger dispatch** parameters (not reviewer dispatch), set to literal `null`.

#### Integrate — `skills/integrate/SKILL.md`

Integrate reviewers receive `subject_code` (multi-file code changes), not `artifact_body`:

- **Line 95**: `subject_code` — concatenated wrapped bodies of every file changed across the merged task branches, each wrapped inline.
- **Lines 102–118**: Both Claude reviewers (integration-reviewer and security-integration-reviewer) receive `subject_code`, `companion_design`, `companion_structure`, `companion_task_review_findings` — all wrapped inline. No `artifact_body` parameter.

The `artifact_path` / `artifact_body` reference at line 189 is within the **scope-tagger dispatch** parameters, set to literal `null` (Integrate is multi-file).

#### Test — `skills/test/SKILL.md`

Test reviewers receive `subject_code` (generated test code files), not `artifact_body`:

- **Line 114**: `subject_code` — concatenated wrapped bodies of every TEST file (inline-wrapped).
- **Lines 127, 135, 143**: All three Claude reviewers (spec, code-quality, goal-traceability) receive `subject_code`, `companion_plan`, `companion_goals` — all inline-wrapped.

No `artifact_body`, no `artifact_path` in test reviewer dispatches.

---

### `artifact_path` occurrences — complete inventory

The term `artifact_path` (as a potential reviewer dispatch parameter) appears in the following locations:

#### 1. Scope-tagger dispatch parameters (not reviewer dispatch)

- `skills/implement/SKILL.md:1204`: `` `artifact_path` / `artifact_body`: both literal `null` (per-task is multi-file — the tagger emits file-path tags from each finding's `referenced_files`) ``
- `skills/integrate/SKILL.md:189`: `` `artifact_path` / `artifact_body`: both literal `null` (Integrate is multi-file — the tagger emits file-path tags from each finding's `referenced_files`) ``
- `skills/using-qrspi/SKILL.md:826,838,954,965`: scope-tagger dispatch shape — `artifact_path: <abs_path>/<step>.md` for single-file artifacts, `null` for multi-file.
- `agents/qrspi-scope-tagger.md:20,34,35`: The scope-tagger agent's own description of its `artifact_path` input parameter.

In all cases, `artifact_path` belongs to the **scope-tagger** (`qrspi-scope-tagger`) dispatch contract, not the reviewer dispatch contract.

#### 2. Git diff shell command arguments (not dispatch parameters)

- `reviewer-protocol/SKILL.md:46`: `git diff <ref> -- <artifact_path>` (command placeholder)
- `using-qrspi/SKILL.md:682,685,686,1088`: `git -C "<repo>" diff "<ref>" -- "<artifact_path>"` (shell commands for diff-file generation)
- Various per-step pre-dispatch diff-emission paragraphs in goals/questions/research/design/phasing/structure/plan/parallelize SKILL.md files: the literal command `git -C "<repo>" diff "<ref>" -- "<ABS_ARTIFACT_DIR>/{artifact}.md"` — all use `<artifact_path>` as a shell placeholder, not as a dispatch parameter name.

#### 3. `qrspi-finding-verifier.md:37`

`` - `<artifact_path>` — absolute path to the artifact under review. ``

This is the finding-verifier agent's input parameter, not a reviewer dispatch parameter.

#### 4. Goals document — ad-hoc v0.7.2 self-host workaround

`docs/qrspi/2026-05-30-v072-release/goals.md:849`:

> The v0.7.2 self-host used an ad-hoc workaround: pass `artifact_path: <abs>` instead of wrapped body, and instruct the reviewer to Read the file and treat its content as if it had arrived between `<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>` / `<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>` markers. Applied across research R1 (Claude + Codex) and research R2 (Claude + Codex). No fidelity loss observed; R2 came back clean.

This documents an ad-hoc use of `artifact_path` as a reviewer dispatch parameter during the v0.7.2 self-host, explicitly described as a workaround **outside the current contract**. The surrounding G29 goal text (`goals.md:835–859`) describes multiple design options for canonizing `artifact_path` into the contract (threshold rule, unconditional path-based form, or reviewer-side dual-accept) — all framed as **proposed future changes**, not current contract.

#### 5. Historical design docs

`docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md:901,913` and `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md:44,140`: `artifact_path` appears in historical design documentation for the scope-tagger/verifier. These predate the current contract and describe the scope-tagger's dispatch shape.

---

### Conditions or criteria for choosing between forms

The current contract in `skills/reviewer-protocol/SKILL.md` § Reviewer Dispatch Contract defines **no conditions, thresholds, or criteria** for choosing between `artifact_body` (inline-wrapped) and any path-based form. The contract specifies `artifact_body` **unconditionally** for all reviewer dispatches. The path-based `artifact_path` form:

- Is not defined in the reviewer dispatch contract.
- Does not appear as a named reviewer dispatch parameter in any per-skill SKILL.md.
- Was used ad hoc during the v0.7.2 self-host as an out-of-contract workaround (documented at `goals.md:849`).

The one in-contract path-based delivery mechanism (`companion_qfile_paths` in Research, `research/SKILL.md:151`) applies only to companion files, not the primary artifact, and is specific to the Research step.
