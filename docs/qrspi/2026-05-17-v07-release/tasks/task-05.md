---
task: 5
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G1, G5]
dependencies: [T01, T03]
loc_estimate: 170
sizing_exception: reusable primitives
---

# Task 05: Implement-skill per-task routing chain, citation-density validator dispatch, and G5 telemetry emission

- **Phase:** 1
- **Target files:**
  - `skills/implement/SKILL.md` (Modify) — add the per-task `model` resolution chain inside `### Per-Task Routing (task_type and model)`; wrap research-specialist dispatches with the citation-density post-output validator and trusted-model re-run; emit per-task telemetry to `reviews/telemetry/round-NN/task-NN.json`.
  - `skills/research/SKILL.md` (Modify) — document the specialist citation-density post-validation hook and the trusted-model re-run path; cross-reference the `validators.citation_density_floor:` config key documented in T01.
- **Dependencies:** T01, T03
- **LOC estimate:** ~170
- **Sizing exception:** reusable primitives — the routing chain, the citation-density validator dispatch, and the G5 telemetry emission co-deploy in one Implement-skill section because the validator and telemetry sites are observed at the same per-dispatch boundary the routing chain authors and the citation-density validator+telemetry depend on the routing chain landing first; splitting them would either duplicate the per-dispatch boundary prose or leave the validator/telemetry without a resolved provider+model to observe.
- **Description:** Wires the Slice 1 routing chain and telemetry emission into the live Implement and Research skills. In `skills/implement/SKILL.md`, the `### Per-Task Routing (task_type and model)` section gains the four-layer `model` resolution chain consumed at every implementer/reviewer dispatch site: layer 1a is the per-task spec `model:` override, layer 1b is a hardcoded dispatch-site `model:` override (the inline `model:` argument the dispatch call composes), layer 2 is a `model_routing:` role-to-provider+model lookup keyed by the agent's `model_role:` frontmatter, and layer 3 is the agent's bundled default. The `trusted_path:` match (against agent file path or role name) is documented separately as a short-circuit that wins ahead of the entire four-layer chain when matched. The same skill wraps every `qrspi-research-specialist` dispatch with a post-output citation-density check against `validators.citation_density_floor:` (default `0.05`): below-floor output triggers exactly one re-run on the trusted model; above-floor proceeds. Per-task telemetry — routing decision (resolved role, provider, model, layer that won), fix-cycle count, review-finding category counts, citation-density rerun count — is emitted to `<ABS_ARTIFACT_DIR>/reviews/telemetry/round-NN/task-NN.json` as a single JSON object per task so the G5 living-config matrix can be tuned from real data. `skills/research/SKILL.md` documents the validator hook and trusted-model re-run path and references the `validators.citation_density_floor:` config key authored in T01.
- **Test expectations:**
  - The `### Per-Task Routing (task_type and model)` section in `skills/implement/SKILL.md` enumerates the four-layer resolution chain in precedence order (1a per-task `model:` override, 1b hardcoded dispatch-site `model:` override, 2 `model_routing:` role lookup, 3 agent bundled default) and documents `trusted_path:` separately as a short-circuit that wins ahead of the four-layer chain when matched.
  - Implement-skill dispatch prose specifies that the resolved provider+model pair is forwarded to `scripts/run-third-party-llm.sh` via `--provider` and `--model`.
  - The specialist dispatch prose specifies that below-floor citation-density triggers exactly one re-run on the trusted model and that above-floor output proceeds unchanged.
  - The specialist dispatch prose specifies that when the trusted-model re-run after a below-floor result ALSO produces below-floor citation density, the validator emits a loud diagnostic naming the below-floor density value, exits non-zero (propagating a failure signal to the Implement orchestrator), and does not silently forward the below-floor output to downstream consumers — the second-below-floor outcome is observably distinct from the success path via the non-zero exit code, NOT a zero-exit-with-empty-body. The Implement skill's downstream consumer treats the non-zero exit as a specialist-dispatch failure (the orchestrator can then decide to retry on a different topic angle, escalate to opus, or proceed with degraded output) rather than as an empty success body.
  - The telemetry-emission prose names the output path shape `<ABS_ARTIFACT_DIR>/reviews/telemetry/round-NN/task-NN.json` and lists the four required fields (routing decision, fix-cycle count, finding-category counts, citation rerun count).
  - The telemetry prose states that absence of the telemetry file at task-DONE time is a loud failure, not a silent skip.
  - `skills/research/SKILL.md` documents the citation-density post-validation hook and the trusted-model re-run path, and cross-references the `validators.citation_density_floor:` key by name.
  - The legacy-config one-time warning behavior from T01 is referenced (not redefined) so Implement consumers know how resumed runs without `model_routing:` are handled.
  - The `### Per-Task Routing (task_type and model)` section authors the initial G5 routing matrix as a documented table mapping each dispatcher class (`qrspi-research-collator`, `qrspi-implementer-lightweight`, `qrspi-research-specialist`, general-purpose/Explore, `qrspi-test-writer`) to its initial routing decision (cheap-model eligible vs. trusted/conditional) with the design.md rationale carried verbatim — the matrix is the observable G5 deliverable consumed by the T07 `test-routing-matrix-application.bats` pin and by Slice 1 acceptance.
  - The Implement-skill per-task reviewer dispatch section in `skills/implement/SKILL.md` documents the DONE-report companion-parameter wiring required by the T15 implementer-protocol hygiene contract: each per-task reviewer dispatch payload carries the implementer's DONE-report body as a named companion parameter AND lists the DONE-report file path in the dispatch payload so reviewers can re-Read it during pre-flight. This closes the gap between the prose contract authored in `skills/implementer-protocol/SKILL.md` (T15) and the actual dispatch-site wiring in `skills/implement/SKILL.md`, ensuring unacknowledged hygiene hits structurally reach the reviewer rather than only being declared in protocol prose.
