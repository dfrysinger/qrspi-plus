---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T07's test expectations for test-config-model-routing.bats are missing the "same fixture dual-path" requirement that design.md makes load-bearing.

Design.md lines 82–83 state: "Layer-1 sub-precedence test: a task whose tasks/task-NN.md carries model: opus dispatching through a call site with a hardcoded model: 'sonnet' override resolves to opus (layer 1a wins over layer 1b); a task with no model: field on its task spec dispatching through the same call site resolves to sonnet (layer 1b active in the absence of 1a). Both cases verified in the same fixture so the tie-break is not silently lost."

T07's test expectations cover "precedence ordering across all four layers" and "trusted-path short-circuit" but the critical "same fixture dual-path" constraint from the design is not present. Without this constraint, a test writer could verify each case in separate fixtures — and if one fixture is wrong, the sub-layer tie-breaker could silently pass without the contradiction being detectable.

Similarly, design.md line 81 specifies: "Model-role resolution test: an agent file with model_role: cheap_reviewer AND model: sonnet resolves to deepseek-v3 at dispatch when config.md's model_routing.cheap_reviewer maps to deepseek-v3; remove the cheap_reviewer entry from model_routing: and the same agent resolves to sonnet via the concrete-model: fallback (both resolution paths verified)." This dual-path requirement for model-role resolution is also absent from T07's test expectations.

Add to T07's test expectations:
- The layer-1a vs. layer-1b tie-break is verified in a single shared fixture showing both resolution outcomes (not separate fixtures that could independently pass without validating the priority order).
- The model-role resolution fallback is verified in a single fixture showing both with and without the role-map entry (role present resolves to configured model; role absent falls back to concrete model: value).
