---
finding_id: R2-F03
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1248-L1263]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T42 creates a BATS pin at `tests/unit/test-replan-boundary-with-goals.bats` that "runs Replan's promotion step against the fixture and asserts the fully-Formal entry is promoted to next-phase `goals.md`." This framing implies the BATS test executes an actual promotion operation against a fixture file and checks that the correct entries appear in the output `goals.md`.

However, Replan's promotion step is authored as skill-body prose in `skills/replan/SKILL.md` — it is guidance for a Claude agent, not an executable shell function or script that a BATS harness can invoke. A BATS file cannot call the Replan skill directly. The T42 description clarifies that the pin "sources `tests/helpers/skill-markdown.bash` (T13) for H2/H3 section extraction against `skills/replan/SKILL.md`'s new `## Boundary with Goals` section" — which means the pin is asserting the text of the skill contract, not the runtime promotion behavior.

If the BATS assertions about promoted/not-promoted entries (test expectations (b)–(f), covering which fixture entries appear in next-phase `goals.md` and what the hand-off report says) are written as markdown-content assertions against the skill prose rather than as execution-result assertions, they would vacuously pass even if the actual Replan agent implementation ignores the contract entirely. Callers (the broader plan acceptance) would never know that the promotion behavior was never actually exercised at BATS time.

This is a silent-pass risk by design: the test expectation says "runs Replan's promotion step" but the implementation-level signal (skill prose extraction) makes that impossible in a BATS context without a runnable promotion script. The result is a test that claims to exercise promotion but only asserts documentation shape.

Resolution: T42 must explicitly disambiguate between two valid approaches: (a) require that Replan's promotion step is implemented as an executable script (e.g., `scripts/replan-promote.sh`) that the BATS pin can invoke against the fixture — this makes the behavioral assertions real; OR (b) reframe T42's test expectations (b)–(f) as Integrate-time behavioral assertions (observable only when the actual Replan agent runs) and convert the BATS pin to documentation-shape assertions only, marking the promotion-output assertions as phase-acceptance rather than unit-BATS assertions. Option (a) closes the silent-pass path. Option (b) honestly documents the limitation.
