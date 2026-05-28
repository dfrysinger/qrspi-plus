---
finding_id: R2-F09
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1144-L1152]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T38 test expectations are entirely documentation-shape assertions. All eight T38 bullets check that the `## Commit hygiene invariants` section "exists," "enumerates exactly three invariants," "states" each invariant's property, "states explicitly" that the three compose, "preserves" the file-based convention, and "does not enumerate" the literal command order. These are all prose-content checks verifiable by grep.

The design.md G12 test strategy is not quoted in design.md's own test-strategy section (the G12 section is not visible in what I read), but the Slice 8 acceptance criterion states "The three architectural invariants for commit hygiene hold and are observable in test output." T38's test expectations produce nothing observable in test output — all the observable behavior is in T39's BATS pin.

This mirrors the T31/T32 split: T38 authors the contract, T39 authors the pin. But unlike T31 which at least carries cross-task behavioral linkage in T32, T38's test expectations do not cross-reference T39 as the behavioral test, nor do they include any behavioral expectation independently. An implementer of T38 who writes the correct section prose but introduces a subtle error (e.g., staging-before-scratch stated as "staging operation begins before the scratch file is written" instead of "completes before") would satisfy all of T38's test expectations but break T39's BATS pin. T38 should carry at least one cross-reference to T39's pin as the behavioral verification of the three invariants, OR should add one inline behavioral expectation such as "T39's `test-commit-hygiene-invariants.bats` asserts the three invariants declared in this section hold across a representative implementer commit cycle — the declared invariant names and their described properties must match exactly what the BATS pin tests."
