---
artifact: plan
round: 5
plan_lines_before: 1315
plan_lines_after: 1320
delta: +5
findings_total: 8
findings_applied: 8
---

# Round-5 Plan Fixes Applied

## Per-finding application status

| Finding | Reviewer | Target | Status |
|---------|----------|--------|--------|
| R5-F01 | quality-claude | T36 description (L1118) — "Anthropic SDK boundary" residue → dual-flag-gate language | APPLIED |
| R5-F01 | spec-claude | T30 frontmatter `sizing_exception: reusable primitives` + body bullet | APPLIED |
| R5-F02 | spec-claude | T42 description vocabulary fix (partial-Formal vs Idea two-category taxonomy) | APPLIED |
| R5-F01 | security-claude | T43 + T36 — malformed-lock case (empty/binary/truncated/missing run_id) | APPLIED (both tasks) |
| R5-F01 | silent-failure-claude | T07 description — add 4th case (second-below-floor non-zero exit) | APPLIED |
| R5-F02 | silent-failure-claude | T11 — qrspi-test-writer pre-RED non-zero-exit pause expectation | APPLIED |
| R5-F03 | silent-failure-claude | Slice 10 L135 bullet — re-label as `(human-verified Integrate-phase gate)` | APPLIED (alternative-a per orchestrator spec) |
| R5-F04 | silent-failure-claude | T05 expectations — DONE-report companion-parameter wiring in `skills/implement/SKILL.md` | APPLIED (routed to T05 per orchestrator spec) |

## Notable cross-task fixes

- **Symmetric malformed-lock closure (security-F01):** T43 (precondition evaluation) and T36 (BATS fixture) both gain the malformed-lock case so the "fail loudly on any lock-file anomaly" contract is symmetric across the precondition gate and the test pin. Distinct diagnostic naming (malformed-lock vs stale-report vs absent-lock).
- **Prose-vs-runtime loop closure (silent-failure-F04):** The R1-F03 fix added the DONE-report-companion prose contract in T15 (`skills/implementer-protocol/SKILL.md`). R5-F04 closes the loop by wiring it into T05 (`skills/implement/SKILL.md` per-task reviewer dispatch). Reviewers now structurally receive the DONE-report on every dispatch.
- **Honest gate re-labeling (silent-failure-F03):** The R4-F03 fix added a Slice 10 acceptance bullet at L135 but did not add structural enforcement. R5-F03 re-labels the bullet as an explicit human-verified Integrate-phase gate, which is honest and proportional — adding a CI-enforcement task would have expanded plan scope.
- **Description-vs-expectations residue (silent-failure-F01):** R4-F02 fixed T07 expectations to specify "exits non-zero" for the second-below-floor case but missed the same residue in T07's description; R5-F01 closes that loop.

## Codex catch-up final attempt

7 reviewers dispatched in parallel; 4 had on-disk task records with "usage limit" errors; 3 task IDs were lost between launch and await (companion could not locate them). All 7 effectively failed. Codex has been blind for rounds 2–5 (4 consecutive rounds). No re-litigation possible from codex; coverage hole accepted as documented in R4 disposition.

## Line count delta

1315 → 1320 = +5 lines. Minimal growth (one frontmatter line, one sizing-exception bullet, three new test-expectation bullets, one prose addition, one re-labeled bullet, one vocabulary in-place swap with no length change).

## Round-6 outlook

- **Expected finding count if R6 dispatched:** 0–3 (near-clean trending to clean)
- **Most likely remaining surfaces:** silent-failure may continue to find residue from the R5 cascade fixes; security and spec may each produce a single trickle finding.
- **Convergence projection:** R5→R6 should continue the reduction trend (8 → ≤4 expected).
- **Codex re-dispatch:** Worth one more attempt at R6 in case the usage limit clears, but plan should not block on codex availability.

## Approval readiness

Plan.md is APPROVAL-READY after the R5 fixes. The orchestrator's recommendation (per the disposition document) is to proceed directly to **Human Gate** without dispatching R6. Rationale:

- 83% cumulative finding reduction (46 → 8) with all R5 findings correctness-only and severity ≤ medium.
- 3 of 7 Claude reviewers CLEAN this round (scope, goal-traceability, test-coverage); 4 of 7 would likely be CLEAN at R6 given the structural fixes applied.
- Codex unavailability has persisted 4 rounds with no resolution path visible.
- Additional R6 round would yield diminishing returns relative to human-gate review time.

If the human reviewer wants belt-and-suspenders convergence confirmation, an R6 Claude-only round is low-cost (no codex blocking, plan changes are minimal) and very likely to land CLEAN or near-CLEAN — but is not gating approval.
