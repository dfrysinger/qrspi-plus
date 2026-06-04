---
finding_id: R4-F01
reviewer: spec-claude
round: 4
severity: medium
change_type: correctness
referenced_files:
  - skills/implement/SKILL.md:645
  - skills/implement/SKILL.md:858
---
Two prose locations in implement/SKILL.md retain the retired model: dispatch shape that the § Per-Task Routing pseudocode migration removed (round-04 diff changed the pseudocode to `Agent({ subagent_type: implementer_subagent })` but not these prose paragraphs). Line 645 (§ Dispatching the Implementer): `Agent({ subagent_type: "<implementer_subagent>", model: "<model>" })` AND "The agent file's frontmatter `model: inherit` is the default that the per-invocation override replaces" — agents now carry `tier:` not `model: inherit`; this describes the retired four-layer Layer-3 fallback. Line 858 (Review Fix Loop, first fix cycle): `Agent({ subagent_type: "<implementer_subagent>", model: "<model>" })` plus "same variant + model" language. FIX: drop the literal `model:` arg from both dispatch shapes (resolution is via the Tier Resolution Chain off the agent's tier:), and remove/replace the `model: inherit` Layer-3 prose. ORCHESTRATOR-VERIFIED via sed. Note: existing bats only greps hardcoded `model: "sonnet"`, so the `model: "<model>"` placeholder slipped through — coverage gap.
