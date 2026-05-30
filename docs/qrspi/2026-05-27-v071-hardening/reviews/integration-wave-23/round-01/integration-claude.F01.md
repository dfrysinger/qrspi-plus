---
finding_id: int-claude-r01-f01
severity: low
change_type: correctness
referenced_files:
  - skills/parallelize/SKILL.md:136
  - skills/parallelize/SKILL.md:307
  - skills/parallelize/SKILL.md:422
  - skills/parallelize/SKILL.md:467
  - agents/qrspi-parallelize-reviewer.md:30-32
artifact: integration-wave-23
round: 1
reviewer: integration-claude
---

# F01 — Stale "the Branch Map table" prose after T4 reshape

T4 replaced the single flat Branch Map table with multiple `### Wave N` mini-tables (`skills/parallelize/SKILL.md:132`, reviewer rule at `agents/qrspi-parallelize-reviewer.md:31`), but two pre-existing rules in the same SKILL still use the singular "the Branch Map table" formulation:

- Line 136 (Artifact spec): "parallelization.md MUST include one note per gated task **immediately after the Branch Map table**"
- Line 307 (anti-pattern list): "no `Reference gate: task-NN ...` note appears **after the Branch Map table**"

Post-reshape there is no single Branch Map table — the Branch Map is now a heading that contains N mini-tables. A literal reading of the stale prose is ambiguous between (a) after the last Wave mini-table, (b) after the Wave that contains the gated task, (c) after each Wave that contains a gated task, or (d) after the whole Branch Map block before the next H2. The Reference-Gate worked example (lines 422, 467) picks interpretation (a) by placing the note after Wave 3 (the last mini-table) and before `## Stage Commits`, but that anchor is implicit only.

**Impact is bounded:** Implement detects gates via content-scan (`Reference gate: task-` prefix per line 142), not position, so runtime behavior is unaffected. The parallelize-reviewer agent has no rule constraining gate-note placement, so the reviewer won't catch a misplaced note either. But a future author following the stale prose literally could place gate notes inside a Wave sub-section (between mini-tables), and nothing would flag it — the worked example would be the only correcting reference.

**Suggested fix:** update both occurrences to read "immediately after the Branch Map section's last `### Wave N` sub-section" (or equivalent unambiguous anchor that survives the new shape). Doc-only correction in the file T4 already modified.
