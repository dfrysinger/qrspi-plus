---
task: 24
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10, G11]
dependencies: []
loc_estimate: 180
sizing_exception: schema migration
---

# Task 24: Introduce Plan-skill per-task spec frontmatter contract for reference-gate and UI fields with SPEC OVERRIDES SOURCE authority

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
