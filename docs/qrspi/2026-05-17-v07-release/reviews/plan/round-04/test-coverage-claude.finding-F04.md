---
finding_id: R4-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L440-L441, docs/qrspi/2026-05-17-v07-release/plan.md:L496-L498]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T11's test expectations (line 440–441) specify that when a RED-verification adapter exits `1` (unrecognized runner output), the gate pauses with a diagnostic that "distinguishes adapter-classification-failure from `infrastructure-failure`." This is a distinct pause state — a third pause category beyond `infrastructure-failure` and `vacuous-RED`. T11 further states this expectation requires "at least one behavioral test expectation observes the gate's runtime behavior end-to-end."

However, T13's `test-red-verification-gate.bats` test expectations (lines 496–498) enumerate only four scenarios: "pass-case (all-fail and mixed), pause-case (vacuous-RED), and pause-case (infrastructure-failure) classifications against each of the four framework adapters from T10." The adapter-exit-1 pause case (where the adapter's classification of the output is itself unrecognized) is absent from T13's enumerated cases.

The round-1 test-coverage-claude.R1-F03 finding required "at least one behavioral test expectation," which was applied (T11 now has line 440–441). But the downstream BATS observation in T13 was not updated to include this case. The result is that T11 declares an observable behavior (the gate's distinguishing diagnostic on adapter exit 1) that no BATS fixture exercises.

This is a gap: T11's behavioral expectation at line 440–441 cannot be verified by the Test skill without a fixture in T13 that triggers adapter exit 1 and observes the distinct diagnostic output. Without this, the distinguishing-diagnostic requirement is declared but unfalsifiable at the BATS level.

Fix: Add to T13's `test-red-verification-gate.bats` test expectations: "The pin also exercises the adapter-exit-1 case (at least one adapter receives a fixture whose output matches none of its classification rules and returns exit 1), and asserts the RED-verification gate emits a distinguishing diagnostic different from the `infrastructure-failure` diagnostic and does NOT dispatch the implementer — this is the fourth pause scenario alongside vacuous-RED and infrastructure-failure."
