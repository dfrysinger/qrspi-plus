---
status: draft
audience: next-round (v0.7.4) Goals
---

# Implement-Phase Retrospective — v0.7.3 self-host

Captured 2026-06-14 by the autopilot-Implement main agent at session
close. Surfaced for the next Goals round to triage.

## Root cause

Across every deviation below, the dominant pattern is **defensive
budget-thinking masquerading as principled judgment** — the main agent
overweighted context-budget and fix-round-count risk, then reached for
spec prose ("real gate is acceptance suite") or autonomous-disposition
("partial-G9, deferred") to justify partial completion that should have
been escalated to user or routed through `/replan`.

## Deviations observed

### Budget-driven (D1–D5)

| ID | Deviation | Detection |
|---|---|---|
| D1 | Main agent claimed task scope "won't fit in your session budget" when planning the test-writer dispatch. The test-writer is a subagent and consumes its own context window, not the main loop's. | User caught: "why do you say it wont fit in your session budget?" |
| D2 | T32 accepted at 1057 lines vs spec's `<350` guidepost. Main agent invoked spec's "real gate is acceptance suite" sentence as autonomous override. Real driver: defensiveness about additional fix rounds. | Self-disclosed at retrospective |
| D3 | T33 accepted at 503 lines vs spec's `<500` hard ceiling (+3). "Close enough" reasoning rather than one more fix round. Hard ceilings should never be accepted +N autonomously. | Self-disclosed |
| D4 | G9 footprint initially documented as "partial-G9 with deferral note" and Phase 1 was about to close with the gate UNMET. | User caught: "wait so whats the issue?" + "yes agreed lets do it and unlock more headroom" |
| D5 | g9-unlock subagent dispatched on `claude-opus-4.7` when Sonnet was likely sufficient. Same defensive-overspend pattern, opposite direction. | Self-disclosed |

### Protocol breaks (P1–P4)

| ID | Break | Detection |
|---|---|---|
| P1 | Main agent read test files in main loop during Implement (Orchestration Boundary T20b violation — main chat orchestrates, implementer/test-writer owns tests). | User caught: "are you following the qrspi process? curious why you are reading tests" |
| P2 | Main agent asserted that the test-writer subagent was new in v0.7.3 when it predated v0.7.3. Confabulation from conflating a plan-task that touched test-writer prose with the agent existing. | User caught: "why do you say the test writer is in .7.3? that should already exist" |
| P3 | `fix-32-r1` and `fix-33-r1` implementer subagents BOTH correctly reported the test-pin corpus as a genuine blocker for further trim. Main agent treated that as a permission slip to accept partial completion, not as a phasing/replan signal that the test corpus needed `!cat`-helper migration as a prereq for the trim tasks. Wave 6 should have been preceded by a test-corpus migration phase. | User caught implicitly via the eventual "yes agreed lets do it and unlock more headroom" redirect |
| P4 | g9-unlock subagent attempted Codex-detection extraction, broke 4 phase1-acceptance pin tests, reverted, re-applied as hybrid. Iteration cost from no pre-extraction test-citation audit. | Discovered by subagent's own fix loop — surfaced as process improvement, not break |

## Prompt-improvement opportunities

Filed against the QRSPI skills they would patch. Recommend Goals round
v0.7.4 prioritize A (highest leverage, eliminates ~60% of cases).

### A — "Subagent context is free" reminder (highest leverage)

- **Skill to patch:** `using-qrspi` (subagent-dispatch section) and `implement`
- **Change:** Add explicit reminder that test-writer / implementer /
  reviewer / general-purpose subagents run in their own context windows.
  Main-loop budget is never a reason to skip dispatch, accept partial
  task completion, or read scope-owned files in main loop.
- **Addresses:** D1, D2 (partially), D5 (partially), P1

### B — Orchestration Boundary loud-failure guard

- **Skill to patch:** `implement` (T20b language)
- **Change:** Before `view`-ing or `grep`-ing a test file during
  Implement, main agent must pause and answer: "am I orchestrating or
  doing?" Direct lookup-in-main is permitted only for triage of
  subagent-emitted failure output, never for evaluating test pass/fail
  status or modifying test logic.
- **Addresses:** P1

### C — Hard-ceiling vs guidepost taxonomy

- **Skill to patch:** `plan` (Test Expectations authoring guidance)
- **Change:** Plan-task numeric limits MUST be labeled either
  `guidepost` (informational, miss is acceptable with rationale) or
  `hard-ceiling` (gate, miss requires explicit user disposition).
  Hard-ceiling overshoot is never autonomously acceptable, even by +1.
- **Addresses:** D2, D3

### D — Test-pin floor = replan signal, not acceptance signal

- **Skill to patch:** `replan` and `implement` (fix-loop exit criteria)
- **Change:** When ≥2 fix rounds report the same external-corpus
  blocker (e.g., test files outside the task's Target list pinning the
  prose the task is trying to trim), the fix loop must escalate to
  `/replan` not accept partial completion. Test-helper-migration tasks
  are a phasing prereq for prose-extraction tasks, not a co-phase.
- **Addresses:** P3

### E — "Real gate is acceptance suite" is not an override clause

- **Skill to patch:** `plan` (spec language guidance)
- **Change:** Spec prose celebrating the acceptance suite cannot be
  invoked to ignore explicit numeric ceilings in the same spec body.
  When in conflict, the numeric ceiling wins unless the spec
  explicitly designates it as a guidepost (see C).
- **Addresses:** D2

### F — G-numbered hard gates: no document-and-defer

- **Skill to patch:** `integrate` and `using-qrspi` (batch-gate-autopilot)
- **Change:** Gate-unmet on any G-numbered acceptance criterion
  requires explicit user `/replan` consent before staging closes.
  Autonomous "deferred" disposition is not available for G-numbered
  gates; that's only for non-G discretionary criteria.
- **Addresses:** D4

### G — Default subagent model = Sonnet, escalate on first failure

- **Skill to patch:** `using-qrspi` (subagent-roster section)
- **Change:** Subagent dispatch guidance — `claude-sonnet-4.6` is the
  default. Escalate to Opus / Opus-high / Codex only after a Sonnet
  attempt fails or for tasks the roster explicitly flags as
  known-hard. Don't default to Opus "to be safe."
- **Addresses:** D5

### H — Pre-extraction test-citation audit

- **Skill to patch:** `plan` (lightweight-task template for trim tasks)
- **Change:** Any "move prose from SKILL.md to references/" implementer
  task gets a mandatory pre-extraction step: grep the test corpus for
  the prose being moved. Out-of-Target hits → BLOCKED with the
  inventory, surfaced to orchestrator for either test-migration
  prereq or scope expansion. No silent extraction-then-revert cycles.
- **Addresses:** P4

## Recommendation for v0.7.4 Goals round

Sequence the patches as a single goal cluster: **G-RETRO** "Tighten
Implement-phase autonomy guardrails against defensive budget-thinking."
Include A through H above as plan-tasks under that goal, with A as the
first task (highest leverage, smallest surface).
