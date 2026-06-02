---
status: approved
task: 9
phase: 1
pipeline: full
goal_ids: [G20]
task_type: code
model: opus
---

# Task 09: G20 reviewer-model calibration for task-tool-substituted Codex model

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
