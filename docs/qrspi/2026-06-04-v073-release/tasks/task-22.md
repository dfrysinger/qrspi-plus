---
status: approved
task: 22
phase: 1
pipeline: full
goal_ids: [G5]
task_type: lightweight
tier: medium
---

# Task 22: Insert Orchestration Boundary section, OBC step, batch-gate additions, and phase-base.txt write in skills/test/SKILL.md

- **Target files:** `skills/test/SKILL.md` (Modify)
- **Dependencies:** T19, T04b
- **LOC estimate:** ~110
- **Description:** `skills/test/SKILL.md` gains the verbatim HARD-RULE Orchestration Boundary section with the `reviews/test/round-NN-results.md` allowlisted-write exception named in the per-phase responsibilities list, the Step-N OBC block calling `scripts/orchestration-boundary-check.sh --phase test --artifact-dir <ABS>`, the batch-gate interactive and autopilot additions, and a phase-start write of `reviews/test/phase-base.txt`. The phase-base.txt write is named as the **first orchestrator action of the test phase** — performed before any subagent dispatch in the phase. R1, R2, R3 (load-bearing HARD-RULE positioning), R7 (verbatim phrasing the T24 lint depends on), and R8 (prose-density tightening of the non-HARD-RULE prose) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the test skill's existing structure; R2 — the HARD-RULE block (with the `reviews/test/round-NN-results.md` allowlisted-write exception named in the responsibilities list) is self-contained; R3 — HARD-RULE at the load-bearing top-of-skill position; R7 — verbatim phrasing the T24 lint and the OBC test read path depend on; R8 — prose-density tightening of the non-HARD-RULE prose.
  - The phase-start prose names the `reviews/test/phase-base.txt` write as the first orchestrator action of the test phase, performed before any subagent dispatch in the phase — so the OBC script's per-phase read path always finds a written phase-base when the OBC step runs.
- **cross_task_consumers:**
  - `tests/lint/test-integrate-test-skill-phase-base-write.bats` (T24) — disposition: `pass-through` (T24 is the anchor-phrase lint locking the `reviews/test/phase-base.txt` write-step prose this task installs; no edit to this task's deliverables required).
  - `tests/lint/test-obc-script-absent-anchor.bats` (T24b) — disposition: `pass-through` (T24b is the anchor-phrase lint locking the OBC-script-absent pre-invocation-check prose this task installs; no edit to this task's deliverables required).
  - `skills/test/SKILL.md` (T36) — disposition: `pass-through` (T36's Pass-1/2/3 trim of `test/SKILL.md` must preserve the verbatim HARD-RULE Orchestration Boundary section (with the `reviews/test/round-NN-results.md` allowlisted-write exception), the `### Step N — Orchestration boundary observability check` heading, the `obc-script-absent:` pre-invocation-check prose, and the `reviews/test/phase-base.txt` write step verbatim through the trim — HARD-RULE prose is under the "What NOT to tighten" guardrail and the anchor phrases are load-bearing for the OBC read path and the T24/T24b lints; T36's R1 expectation covers this verbatim).
- **Author note:** the design-contract drift previously deferred here (design.md § G5 OBC fail-soft vs plan dispatch-defect fail-loud) is resolved by the design.md G5 amendment landed in this branch — this task's OBC step inherits T19's now-aligned contract.
