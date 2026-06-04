---
finding_id: R5-F04
severity: low
change_type: clarity
referenced_files: [skills/using-qrspi/SKILL.md]
---
Stale pre-migration "step 4" reference. The `trusted_path:` block description (~line 484) reads "...step 4 has no concrete value to return", referencing the OLD four-layer model-resolution chain (`--tier-override / model: / model_routing / agent-bundled default`) that G22/T16 replaced with the four-tier precedence chain (`--tier-override → agent tier: → default_tier: → hardcoded medium`). The new chain has no "step 4 / agent-bundled model:" concept. Misleads anyone implementing a trusted_path dispatch site. Source: sec-claude F03. Fix: replace the "step 4" language with new-schema wording (e.g. "the dispatcher uses the agent's own `tier:` via `resolve_tier` with no override — there is no agent-bundled `model:` field in the new schema").
