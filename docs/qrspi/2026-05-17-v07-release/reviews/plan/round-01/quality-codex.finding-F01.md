---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-05-17-v07-release/plan.md:L148-L155", "docs/qrspi/2026-05-17-v07-release/plan.md:L249-L252", "docs/qrspi/2026-05-17-v07-release/design.md:L32-L44"]
artifact: plan
round: 1
reviewer: quality-codex
---

The routing-chain tasks misstate the approved model-resolution precedence. Design defines layer 1b as the hardcoded dispatch-site `model:` override and treats `trusted_path` as a separate short-circuit that wins outside the normal chain. The plan instead describes layer 1b as a hardcoded `trusted_path:` match and repeats that in the Task 05 test expectations, while Task 01's precedence sentence says "hardcoded trusted-path" rather than "hardcoded dispatch-site model." This would send implementers toward the wrong routing behavior and could drop the required layer-1b dispatch-site model override. Fix the Task 01 and Task 05 prose/tests so they preserve: per-task `model:` > hardcoded dispatch-site `model:` > `model_routing:` > agent default, with `trusted_path` checked separately as a short-circuit.
