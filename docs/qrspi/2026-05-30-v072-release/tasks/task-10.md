---
status: approved
task: 10
phase: 1
pipeline: full
goal_ids: [G28]
task_type: code
model: opus
---

# Task 10: G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation

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
