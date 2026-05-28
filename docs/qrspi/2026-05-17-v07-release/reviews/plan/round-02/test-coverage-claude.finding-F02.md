---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L564-L568]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T16 test expectations are exclusively documentation-shape assertions with no behavioral test expectation. All four test bullets for T16 assert content in `skills/integrate/SKILL.md` — that it "names .github/workflows/ci.yml as the canonical CI workflow file," that it "states that Integrate queries the workflow run status," that it "requires success of all jobs," and that "no prior wording…contradicts." These are all documentation-shape checks: they verify the markdown prose content, not any observable runtime behavior.

The design.md G17 test strategy requires a "Reviewer-pass test" — a concrete integration-level observation that Integrate actually gates on the CI workflow. T16 produces no BATS pin (T19 is the CI-shape pin for the workflow file itself, but T16 is the skill prose edit). However, T16's test expectations are the contract that T19's shape-pin will key against. None of T16's test expectations describe the behavioral outcome when the CI gate is queried: what happens when all jobs pass (gate clears, dependents dispatch), or what happens when any job fails (gate blocks with a named diagnostic naming the failed job). The phrase "requires success of all jobs in the workflow run as the gate condition rather than a subset" is a documentation-shape assertion about what the prose says, not a behavioral assertion about what happens at runtime.

Add at least one behavioral test expectation that describes the outcome observable to a caller: e.g., "When the `gh` CLI query for the head commit shows all `lint` and `bash32` jobs with status `success`, the Integrate gate clears and the next Integrate step proceeds" AND "When any job in the workflow run reports status other than `success`, the Integrate gate produces a named diagnostic identifying the failed job and does not proceed." These are verifiable by a T23-style BATS fixture or an Integrate-level integration test at the phase-acceptance tier.
