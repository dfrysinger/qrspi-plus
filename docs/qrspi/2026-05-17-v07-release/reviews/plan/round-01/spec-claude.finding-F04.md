---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:233-257
artifact: plan
round: 1
reviewer: spec-claude
---

Task 05 bundles three distinct observable behaviors across two distinct target files without a sizing exception.

**What is bundled:**
1. Per-task model-resolution chain (four-layer) added to `skills/implement/SKILL.md`.
2. Citation-density post-output validator dispatch + trusted-model re-run added to the same `skills/implement/SKILL.md`.
3. Cross-skill documentation of the citation-density hook added to `skills/research/SKILL.md`.

These are three distinct behaviors with independent test expectations (the routing chain is independently verifiable; the citation-density validator is independently verifiable; the `skills/research/SKILL.md` cross-reference is independently verifiable). The task title signals the bundle explicitly: "Implement-skill per-task routing chain, citation-density validator dispatch, **and** G5 telemetry emission" — three clauses.

The LOC estimate is ~170, within the 200-LOC budget per task, so the bundling concern is about distinct observable behaviors, not LOC overflow. The applicable rule is: each task should have at most one distinct observable behavior unless a sizing exception is declared. No `sizing_exception` is declared for T05.

The closest valid exception category from the closed set is `reusable primitives` (if the claim is that the routing chain, validator, and telemetry are inseparable primitives that must land together) or there is no matching exception (in which case the task should split). The description does argue the three are co-deployed in the same Implement-skill section, but the citation-density validator and the routing chain are independently testable and independently deployable without the other.

**Proposed split:**
- T05a: Add the four-layer model-resolution chain to `skills/implement/SKILL.md` → `### Per-Task Routing` section. Test: resolution-chain section enumerates all four layers in precedence order.
- T05b: Add citation-density post-output validator and telemetry emission to `skills/implement/SKILL.md` + cross-reference in `skills/research/SKILL.md`. Depends on T05a. Test: validator triggers exactly one trusted re-run below floor; telemetry record exists at `reviews/telemetry/`.

If the plan author determines the behaviors are inseparable at this layer of abstraction, adding `sizing_exception: reusable primitives` with the rationale that the routing chain, validator, and telemetry are co-deployed in one skill section would document the decision explicitly and satisfy the exception rule.
