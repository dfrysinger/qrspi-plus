---
round: 07
artifact: design
status: fixing
---

# Round 07 dispositions

## Findings inventory

- quality-claude: 1 finding (low=1)
- scope-claude: 0 findings (clean — 6th consecutive scope-clean round)
- quality-codex: 2 findings (high=1, medium=1)
- scope-codex: 0 findings (clean)

Total: 3 findings. All accept.

Round trend: 10 → 3 → 5 → 4 → 2 → 4 → 3. Severity weight is dropping (round 7 has 1 high but more lows; round 6 had no highs). Scope reviewers stable clean.

## Per-finding dispositions

### R7-F01 quality-codex (HIGH) — accept. Pre-implementer RED gate doesn't distinguish fail-for-right-reason from infra failure

The G6 round-4 fix added "Implement runs the test-writer's tests once before dispatching qrspi-implementer. If any pre-implementation test passes, orchestrator pauses." That catches vacuous-success but NOT infrastructure failures (syntax error, missing import, broken fixture setup, assertion that never reaches intended behavior). A test file with a syntax error trivially "fails", unblocking the implementer against a broken test.

**Fix:** Strengthen the gate. The gate must verify each pre-implementation test fails for the expected task-spec reason. Pause on:
- Any test that PASSES pre-implementation (vacuous assertion or accidentally-already-satisfied).
- Any test that fails for a non-task-spec reason: syntax/parse error, import/load error, fixture/setup error, missing-symbol error, infrastructure error.

The orchestrator parses test runner output. The pass-set must be empty AND the fail-set must be 100% "assertion failures" or equivalent target-behavior-not-satisfied signals. Anything else triggers the pause.

Update G6's design-level test bullet:
- Pre-implementer RED-verification test: a `task_type: code` task with a syntax-error in the test file pauses the orchestrator at the pre-implementer gate.

### R7-F02 quality-codex (medium) — accept. G15 Formal-goal definition conflicts with Goals OWNS contract

G15 currently defines a "Formal goal" as requiring `id:`, `type:`, AND acceptance criteria. But the Goals OWNS/DEFERS contract (per `skills/goals/SKILL.md` and the strip-from-goals contract documented in the skill ecosystem) says `goals.md` does NOT carry acceptance criteria — Goals owns Problem / Why we care / What we know so far; acceptance criteria are authored by Plan in `tasks/task-NN.md` Test Expectations blocks.

If Structure/Plan follows G15 literally, Replan refuses to promote valid future goals because they don't carry acceptance criteria (which they wouldn't, per the Goals contract), OR Replan pushes plan-style acceptance criteria back into `goals.md` (which violates Goals OWNS).

**Fix:** Replace "acceptance criteria" in G15's Formal-goal definition with the actual Goals-contract fields. A Formal goal in `future-goals.md` is one carrying:
- `id:` (the load-bearing assignment that distinguishes Formal from Idea)
- `type:` (`known-fix` or `exploratory` per the Goals template)
- All three required subsections: `## Problem`, `## Why we care`, `## What we know so far`.

Update three locations:
- The Formal-vs-Idea definitions (around design.md line 651-654).
- The Replan contract bullet (around line 658).
- The Schema check on Replan side (around line 663).
- The BATS pin description (around line 676).

Replace every mention of "acceptance criteria" in G15 with the goal-template fields above. Acceptance criteria belong to Plan, not Goals/future-goals.

### R7-F01 quality-claude (LOW) — accept. Decision 3 + cross-cutting summary omit RED-verification gate

The round-4 G6 fix added the orchestrator-side pre-implementer RED-verification gate but Decision 3 and the cross-cutting "TDD test-writer split" test strategy both omit it. Phasing/Plan readers scanning summaries miss the gate.

**Fix:**
1. Decision 3 (around lines 921-927): add a sentence after the "A new agent is not needed" line: "Implement (the orchestrator) also runs a pre-implementer RED-verification gate that pauses if any pre-implementation test passes or fails for a non-task-spec reason (syntax error, missing import, fixture setup); the gate closes the protocol boundary between the two split agents."
2. Cross-cutting test strategy "TDD test-writer split" (around lines 1084-1088): add a fourth bullet: "Orchestrator pauses at the pre-implementer RED-verification gate if any pre-implementation test passes or fails for a non-task-spec reason (syntax error, import error, fixture setup)."

## Fix dispatch plan

Single fix subagent. 3 accept.

## Status

draft → fixing → (post-fix) → re-review round 08.

## Convergence assessment after round 7

If round 8 surfaces only low/medium quality-codex deeper-pass findings (no HIGH correctness defects, no scope drift), recommend close. The scope topology has been clean for 6 consecutive rounds; the goal-coverage / trade-off / test-strategy / system-diagram fundamentals are sound. Quality reviewers are doing increasingly deep semantic passes that will produce a non-zero finding count asymptotically. There is a real diminishing-returns curve here.
