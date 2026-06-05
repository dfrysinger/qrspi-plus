# Round 2 Dispositions — goals.md

## Reviewer outputs (R2)

| Reviewer | Findings | Notes |
|---|---|---|
| quality-claude (sonnet-4.6) | clean (sentinel only) | No defects |
| scope-claude (sonnet-4.6) | F01, F02, F03 (all scope, medium) | Chat-only fallback — orchestrator persisted |
| quality-codex (gpt-5.3-codex) | F01 (intent, medium), F02 (clarity, low) | Chat-only fallback (PI-002) |
| scope-codex (gpt-5.3-codex) | F01 (scope, medium) | Chat-only fallback (PI-002) |

Total: 6 findings + 1 clean sentinel.

## Verifier scores

| Finding | change_type | Score | Disposition |
|---|---|---|---|
| scope-claude.R2-F01 (G17 verbatim prose) | scope | 76 | KEEP (scope always kept) |
| scope-claude.R2-F02 (G25 invariant text) | scope | 68 | KEEP (scope always kept) |
| scope-claude.R2-F03 (G19 Iron rule MUST/MUST NOT) | scope | 75 | KEEP (scope always kept) |
| quality-codex.R2-F01 (27 goals too large) | intent | 30 | KEEP (intent always kept) → OVERRULE |
| quality-codex.R2-F02 (G25 "Needs a new vocab pin") | clarity | 78 | DROP (clarity < 80) — *fixed opportunistically* |
| scope-codex.R2-F01 (G15/G19 MUST/MUST NOT) | scope | 45 | KEEP (scope always kept) |

## Fixes applied (5 edits to goals.md)

1. **Constraints section (new bullet)** — Lifted G19 "Iron rule" to a project-wide constraint titled "Subagent-resident verification (user direction)". This is the user-affirmed iron rule from the dialogue; placing it in Constraints (the OWNS-permitted section for architectural environment) lets the candidates inside G19 reference it without re-asserting MUST/MUST NOT inside per-goal prose. Addresses scope-claude.R2-F03 + scope-codex.R2-F01 (G19 portion).
2. **G15 (~L346)** — Softened "Fail-loud assertions: script refuses to run when..." to outcome-level: "A fail-loud behavior shape ... Design chooses the exact failure mode (assertion, exit code, halt-and-report)." Addresses scope-codex.R2-F01 (G15 portion).
3. **G17 (~L487-493)** — Stripped the three verbatim file:line replacement-prose bullets. Replaced with concept-level: "Three prose-drift surfaces need to be reconciled ... Design authors the replacement prose. Issue #233 carries concrete drafts that may serve as candidates Design weighs." Addresses scope-claude.R2-F01.
4. **G19 (~L557-559)** — Removed the standalone "Iron rule for any candidate (user direction)" paragraph. Replaced with a parenthetical reference to the new project-wide Constraint. Updated the dangling "per the user direction above" reference inside the leading-candidate bullet. Addresses scope-claude.R2-F03 + scope-codex.R2-F01 (G19 portion).
5. **G25 (~L735-743)** — (a) Replaced the quoted invariant clause with concept-level candidate wording (addresses scope-claude.R2-F02). (b) Recast "Needs a new vocab pin that searches for..." as a "Companion vocab pin" candidate (addresses dropped quality-codex.R2-F02 opportunistically). (c) Replaced "landing them in a single Plan-phase wave" with "Phasing should evaluate whether the cluster benefits from being scheduled together" (addresses phasing-leakage residue missed in R1).

## Overrules with rationale

**quality-codex.R2-F01 — "27 goals too large for one run" (intent, score 30, advisory):**
The 27 goals were user-pre-scoped to the v0.7.2 milestone (issue #244, 31 milestoned issues; G24 bundles 4-related-finding-children, G16 bundles 2). The v0.7.2 milestone is a hardening release whose scope was deliberately set by the user as the central organizing principle of this run. Phasing will decompose the 27 goals into multiple phases via `roadmap.md`; Goals-stage cardinality is not a defect to fix at this stage.

No edits to `goals.md` for this finding. Surfaced in the human gate summary for user awareness.

## Plugin issues observed in R2

- **PI-002 re-confirmed.** Codex (`gpt-5.3-codex`) task-tool dispatch returned chat-only for both reviewer agents (quality-codex, scope-codex). Orchestrator persisted.
- **PI-005 (new).** Claude (`claude-sonnet-4.6`) `qrspi-goals-scope-reviewer` returned three R2 findings in chat output (with "Three findings written (R2-F01, R2-F02, R2-F03)" assertion) but did not call Write. Orchestrator persisted. Different from PI-002 (Codex chat-only) — this is a Claude agent that *claimed* it had written. Worth tracking as a contract-assertion drift even though the failure mode is the same (orchestrator persists).
- **PI-006 (new).** Finding verifier (`qrspi:qrspi-finding-verifier × claude-haiku-4.5`) chat-only fallback on `verify-r2-scope-codex-f01` — the verifier emitted score 45 with full rationale in chat but did not Write the sidecar. Orchestrator persisted. Five sibling dispatches in the same parallel batch wrote to disk normally, so the failure is non-deterministic.

## Next step decision

R2 produced 5 substantive edits to `goals.md` (1 new Constraint + 4 per-goal edits). Per the iterate-until-clean protocol, dispatch R3 to verify the edits did not introduce new boundary leakage and to confirm convergence before approval.
