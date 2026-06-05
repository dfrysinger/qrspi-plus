---
artifact: goals
round: 4
reviewer: quality-claude
status: clean
disk_write_blocker: "Claude sonnet-4.6 via Copilot CLI task tool returned chat-only — quote: 'per the environment instruction that this reviewer's only output channel is response text'. Orchestrator-persisted. CRITICAL PI-010 UPDATE: disk-write blocker affects Claude pair too, not just OpenAI-family. Root cause is Copilot CLI host environment, not vendor."
---

# Quality review (round 4 narrow amendment): CLEAN

All four touched surfaces (G6 sharpening, G28, G29, Cross-Cutting Notes) pass all goals-specific quality checks. Zero findings.

## G6 sharpening — PI-010 candidate #8

Problem-frame preserved: the added paragraph frames the new proximate-cause hypothesis as evidence ("v0.7.2 self-host confirmed 5/5 chat-only returns") and introduces the host-switch idea exclusively as "New candidate Design should weigh" (candidate #8). The verifying counter-experiment is proposed as a falsifiability step, not a commitment. The original problem statement (chat-only returns; suppression vs. recipe ambiguity) is sharpened, not replaced. Source line updated to include #260.

## G28 — Apply-fix protocol convergent-evidence exception

- type field: exploratory (concrete)
- Exactly 3 subsections (Problem / Why we care / What we know so far)
- 4 candidates each with explicit trade-off, framed "Design should weigh"
- Source: #261, two dispositions files

## G29 — Reviewer dispatch contract escape hatch

- type field: known-fix (concrete)
- Exactly 3 subsections
- 3 candidates each with trade-off
- Source: #262, commit reference

Note (non-blocking): "What we know so far" makes a strong analytical assertion — "The path-based variant is strictly stronger prompt-injection defense than the wrapped-body variant" — that effectively favors candidate #2. This is empirical security reasoning, not a protocol commitment; three candidates with explicit trade-offs are still presented for Design to weigh. The known-fix classification is defensible because the ad-hoc workaround was field-tested across R1+R2 (4 dispatches, no fidelity loss); the "known" part is the pattern, not which variant Design selects.

## Cross-Cutting Notes

- G28/G29 added to reviewer-pipeline cluster with individual rationale
- New cross-cluster co-schedule note (G6/G29 sharing reviewer-protocol/SKILL.md surface)
- G7/G12/G13/G28 resolution-path link added
- No new top-level Out of Scope or acceptance-criteria section

## Frontmatter

status: approved → status: draft — Correct. File re-opened for amendment, appropriately marked draft pending this approval round.
