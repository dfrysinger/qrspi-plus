---
finding_id: R2-F05
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L873-L878]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T28 test expectations lack a behavioral test for the wave_context dispatch case and do not specify what happens when `wave_context:` is present but malformed or when the upstream `structure.md` `## UI Reference Affordances` section is absent.

The test expectations for T28 are four documentation-shape assertions: the agent body "documents consumption of" various inputs. The fifth bullet "No duplicate or parallel visual-fidelity reviewer agent file is created" is a scope-confinement check. None of T28's test expectations specify:

1. A behavioral test that when `wave_context:` IS present AND contains references to sibling findings, the reviewer's output (emitted finding files) contains at least one explicit cross-reference to a named sibling task OR an explicit "no relevant sibling context found" statement — this is the observable described in T28's third bullet but framed as a documentation-shape check ("the body documents…the reviewer's output must contain…") rather than as a concrete test fixture.

2. What happens when `## UI Reference Affordances` in `structure.md` is ABSENT but the reviewer receives a task with `lift_source:` — does the reviewer fail loudly? Fall back gracefully? The test expectations for T28 say "the body documents consumption of `## UI Reference Affordances` from `structure.md` when present" but "when present" implies there is also a "when absent" case that is unspecified.

3. What happens when `wave_context:` is present but malformed (e.g., markers present but body empty, or body present but no per-task entries) — the reviewer should fail loudly or produce a diagnostic, but T28's test expectations describe only the happy path.

The T30 pin five covers the gate-pause integration but not the visual-fidelity reviewer's own output shape. Add at least one behavioral test expectation to T28 stating: "A BATS or integration fixture dispatching the refined agent with a wave_context: companion containing one sibling finding entry produces a finding file referencing the sibling task by ID or an explicit statement that no relevant sibling context was found — observable in the emitted finding files."
