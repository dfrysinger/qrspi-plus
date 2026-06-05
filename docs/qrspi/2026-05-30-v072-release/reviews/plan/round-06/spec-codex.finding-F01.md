---
reviewer: codex
role: plan-spec-reviewer
round: 6
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — R1–R7 reviewer-judgment test expectations on T27/T33/T37/T38

## Location

- `plan.md` Task 27, **L1542** — "**Content-semantic review applies R1-R7...**"
- `plan.md` Task 33, **L1904** — "**Implementer applies R1-R7... reviewer ... verifies...**"
- `plan.md` Task 37, **L2138** — "**Implementer applies R1-R7... reviewer verifies...**"
- `plan.md` Task 38, **L2191–L2192** — "**Apply R1-R7...**" and "**Mental-replay check... would not trigger...**"

## What's wrong

Several task `Test expectations` clauses are written as reviewer-judgment checks
rather than deterministic, reproducible acceptance conditions, so Test-phase
pass/fail cannot be mechanically verified from fixed inputs/outputs.

These checks depend on subjective interpretation ("content-semantic review",
"mental-replay"), not on concrete fixtures/assertions with expected outputs.
That breaks the spec-review requirement that author-side Test Expectations be
deterministically verifiable by Test phase, and risks false-clean outcomes
where regressions pass because reviewer interpretation differs round-to-round.

## Notes

T27/T33/T37/T38 are content-semantic prose tasks (SKILL.md edits, decisions
doc updates) where R1–R7 IS the framework for the deterministic check —
but the test-expectation language as currently written reads as
"a reviewer subjectively applies R1–R7" rather than "this fixture matches
this expected output". The fix is to either (a) reframe the R1–R7 application
as a binary grep/diff against pinned prose anchors, or (b) accept that
content-semantic tasks have a different test-altitude than code tasks and
mark these expectations as "reviewer-applied" rather than "mechanically
verifiable" to set Test-phase expectations correctly.
