---
finding_id: R3-F02
reviewer: spec-codex
round: 3
severity: medium
change_type: correctness
referenced_files:
  - skills/implement/SKILL.md:560
  - skills/implement/SKILL.md:615
---
implement/SKILL.md retains stale retired-routing prose. Line 560 says "The Implement-skill consumes the matrix at every dispatch through the four-layer chain above" and line 615 dispatches `Agent({ subagent_type: "qrspi-test-writer", model: <resolved per the four-layer routing chain in § Per-Task Routing> })`. Post-G22 the resolution mechanism is the tier-resolution chain owned by scripts/_resolve-lib.sh; "four-layer chain" language and the `model: <resolved...>` dispatch-arg shape are retired. Update both to reference the Tier Resolution Chain and tier-resolved (vendor,model). The role-keyed "#### G5 Initial Routing Matrix" surrounding these lines should likewise be reconciled to the tier vocabulary (DoD: "remove the role-keyed G5 matrix"). ORCHESTRATOR-VERIFIED via sed.
