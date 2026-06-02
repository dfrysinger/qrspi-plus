---
status: approved
task: 8
phase: 1
pipeline: full
goal_ids: [G19]
task_type: code
model: sonnet
---

# Task 08: G19 verifier wholesale-hallucination rubric class

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
