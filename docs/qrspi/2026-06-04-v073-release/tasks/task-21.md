---
status: approved
task: 21
phase: 1
pipeline: full
goal_ids: [G5]
task_type: lightweight
tier: medium
---

# Task 21: Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/integrate/SKILL.md

- **Target files:** `skills/integrate/SKILL.md` (Modify)
- **Dependencies:** T19, T04b
- **LOC estimate:** ~110
- **cross_task_consumers:**
  - `tests/lint/test-integrate-test-skill-phase-base-write.bats` (T24) — disposition: `pass-through` (T24 is the anchor-phrase lint locking the `reviews/integration/phase-base.txt` write-step prose this task installs; no edit to this task's deliverables required).
  - `tests/lint/test-obc-script-absent-anchor.bats` (T24b) — disposition: `pass-through` (T24b is the anchor-phrase lint locking the OBC-script-absent pre-invocation-check prose this task installs; no edit to this task's deliverables required).
  - `skills/integrate/SKILL.md` (T36) — disposition: `pass-through` (T36's Pass-1/2/3 trim of `integrate/SKILL.md` must preserve the verbatim HARD-RULE Orchestration Boundary section, the `### Step N — Orchestration boundary observability check` heading, the `obc-script-absent:` pre-invocation-check prose, and the `reviews/integration/phase-base.txt` write step verbatim through the trim — HARD-RULE prose is under the "What NOT to tighten" guardrail and the anchor phrases are load-bearing for the OBC read path and the T24/T24b lints; T36's R1 expectation and the R7 § Untrusted Data Handling/load-bearing-anchors guardrail cover this verbatim).
- **Description:** `skills/integrate/SKILL.md` gains the verbatim HARD-RULE Orchestration Boundary section (the "MAIN CHAT ONLY ORCHESTRATES" block plus per-phase responsibilities, "does NOT" list, and "Why this rule matters in Integrate" rationale — all self-contained, no cross-skill references). A new `### Step N — Orchestration boundary observability check` block lands before the batch-gate step calling `scripts/orchestration-boundary-check.sh --phase integration --artifact-dir <ABS>`. The batch-gate section gains interactive-menu and autopilot branched-default additions surfacing the OBC report. The phase-start prose names the `reviews/integration/phase-base.txt` write (recording `integration_base_sha=<HEAD-SHA>` for the OBC script to read) as the **first orchestrator action of the integrate phase** — performed before any subagent dispatch in the phase. R1, R2, R3 (load-bearing HARD-RULE at the top of the skill body — the section the orchestrator must internalise first), R7 (verbatim phrasing the T24 lint and the OBC script's phase-base read path depend on), and R8 (prose-density tightening of the non-HARD-RULE prose; the HARD-RULE block itself is verbatim and not tightened) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the integrate skill's existing structure; R2 — the verbatim HARD-RULE block, the responsibilities list, the "does NOT" list, and the rationale are self-contained (no cross-skill references); R3 — HARD-RULE block lands at a top-of-skill position the orchestrator must internalise first; R7 — verbatim phrasing of the design.md G5 § Solution (a) prose-design block (the T24 lint and the OBC integration read path depend on the literal phrasing of the phase-base.txt write step); R8 — prose-density tightening of the non-HARD-RULE prose (HARD-RULE itself is not tightened — "what NOT to tighten" guardrail covers verbatim contract blocks).
  - The phase-start prose names the `reviews/integration/phase-base.txt` write as the first orchestrator action of the integrate phase, performed before any subagent dispatch in the phase — so the OBC script's per-phase read path always finds a written phase-base when the OBC step runs.
- **Author note:** the design-contract drift previously deferred here (design.md § G5 OBC fail-soft vs plan dispatch-defect fail-loud) is resolved by the design.md G5 amendment landed in this branch — this task's OBC step inherits T19's now-aligned contract.
