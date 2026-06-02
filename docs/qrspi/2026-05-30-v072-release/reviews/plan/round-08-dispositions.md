---
round: 8
step: plan
scope: broaden (vs main)
reviewers_dispatched: 14
clean: 12
findings: 2
verifier_scored: 2
kept: 1
dropped: 1
---

## Round-08 summary

**Scope:** broaden — full diff vs main (r7's scope-set was `<full>`, forcing broaden per convergence rule).

**Reviewer fan-out (14):**
- 7 Claude reviewers: spec, quality, scope, security, silent-failure, test-coverage, goal-traceability → **all CLEAN**
- 7 Codex reviewers: spec, quality, scope, security, silent-failure, test-coverage, goal-traceability → 5 CLEAN + 2 findings

### Findings

| ID | Reviewer | Severity | Change-type | Score | Disposition |
|---|---|---|---|---|---|
| F01 | quality-codex | high | correctness | **72** | **KEPT — fix applied** |
| F01 | goal-traceability-codex | high | correctness | 15 | DROPPED (< 70 correctness floor) |

### KEPT — quality-codex.F01 (E1)

**Finding:** Round-07's E1 fix added Test Expectation L1408 ("Repo-wide grep audit asserts zero remaining live references to `docs/prompt-design-guide.md` outside historical CHANGELOG entries"). Verified by codex: 43 non-CHANGELOG matches exist across legitimate planning artifacts (`docs/qrspi/.../structure.md`, `docs/qrspi/.../research/q05-q06-codebase.md`, `.restructure-v2/`, `plan.md.bak-pre-merge`, etc.) — the audit as written is unfulfillable and would fail the Test phase.

**Fix applied:**
- L1400 (DoD): "No stale `docs/prompt-design-guide.md` references remain in **runtime surfaces** (grep over `skills/`, `agents/`, `scripts/`, and top-level docs returns zero matches; planning artifacts under `docs/qrspi/` and `.restructure-v2/` and historical CHANGELOG entries are intentionally excluded — they describe the migration, they don't consume the path)."
- L1408 (Test Expectations): "**Runtime-surface grep audit** (over `skills/`, `agents/`, `scripts/`, and top-level docs; excluding `docs/qrspi/` planning artifacts, `.restructure-v2/` intermediate structure work, and historical CHANGELOG entries) asserts zero remaining live references to `docs/prompt-design-guide.md` (matches DoD invariant — fails the build on any stale source-of-truth reference in a runtime-consumer surface)."

DoD and Test Expectations stay in sync — both scoped to the same whitelist of runtime-consumer surfaces.

### DROPPED — goal-traceability-codex.F01 (verifier 15)

**Finding:** G25/G29 lack forward task-to-test trace.

**Disposition:** DROP. This re-raises the round-02-adjudicated absorbed-by-CD-1 disposition (see checkpoint 074 "moot-goals surgery committed"). Plan.md currently documents the absorbed disposition explicitly at L11 ("Goals G25, G26, G29 — and G24's four facets — are absorbed by CD-1; no separate v0.7.2 task ships under those IDs"), L50, and L102. Design.md ## G25 / ## G29 / ## G26 sections establish the consolidation rationale. The reviewer surfaced no new evidence; the verifier scored it 15 (well below the 70 correctness floor) because the absorbed disposition is the deliberate, well-documented adjudicated outcome.

## Process notes (v0.7.3 plugin friction)

- **Codex chat-only returns recurred:** 5 of 7 Codex reviewers returned chat-only on r8 despite explicit canonical-filename prompt priming. Pattern reconfirmed; same workaround (orchestrator-side materialization).
- **Tagger H2 parser worked this round:** Last round's en-dash fallback was avoided by including line-range guidance in the tc-codex prompt. The quality-codex finding cited `L1400, L1408` (comma-separated, ASCII), and the tagger correctly bound to the enclosing `## Task Specs` H2.
- **The "till clean" loop earned its keep:** Round-07's E1 fix introduced a defect (over-broad grep) that round-08 caught at verifier score 72. Without the broaden-round, this would have shipped as a broken Test phase expectation.

## Next action

- Round-09 dispatch: broaden vs main (r8 scope-set = `## Task Specs`, r7's was `<full>` → broaden per convergence rule; backward-loop flag NOT set).
