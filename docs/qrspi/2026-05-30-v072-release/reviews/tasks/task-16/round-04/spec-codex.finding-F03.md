---
finding_id: R4-F03
reviewer: spec-codex
round: 4
severity: medium
change_type: correctness
referenced_files:
  - skills/implement/SKILL.md:580-581
---
implement/SKILL.md:580-581 (§ Per-Task Telemetry Emission) telemetry schema still encodes the retired four-layer chain: the `routing_decision` object is `(role, provider, model, layer)` and `layer is one of trusted_path, 1a, 1b, 2, 3 per the chain above`. Post-G22 the resolution mechanism is the Tier Resolution Chain (layers: --tier-override / agent tier: / default_tier: / hardcoded medium); `1a/1b/2/3` and the role/provider/model framing are the retired four-layer-chain enumeration. FIX: update the telemetry layer enum and routing_decision shape to the tier-precedence vocabulary so the telemetry corpus matches the actual resolver. ORCHESTRATOR-VERIFIED via sed.
