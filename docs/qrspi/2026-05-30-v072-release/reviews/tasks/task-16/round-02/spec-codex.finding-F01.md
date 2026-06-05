---
finding_id: R2-F01
reviewer: spec-codex
round: 2
severity: medium
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md:420-423
  - skills/using-qrspi/SKILL.md:510-517
---
Residual contradiction in skills/using-qrspi/SKILL.md. The "### Dispatch routing blocks" umbrella intro (lines ~420-423) states all four blocks (providers:, model_routing:, trusted_path:, validators:) "are optional in the config.md frontmatter — their absence means dispatch falls back to agent-bundled defaults." This now contradicts the model_routing:-specific section (~lines 510-517) which (correctly, per F02 fix) states missing model_routing: FAILS LOUDLY via the shared config-validation procedure with no silent fallback. Narrow the umbrella statement to carve out model_routing: (its absence is fail-loud), or otherwise reconcile so model_routing: absence is unambiguously fail-loud everywhere. ORCHESTRATOR-VERIFIED via sed.
