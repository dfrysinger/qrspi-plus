---
artifact: design
reviewer: quality-codex
round: 1
finding_id: quality-codex-F03
severity: medium
change_type: test-coverage
file: design.md
section: "Test Strategy"
disposition: dismissed
---

# F03: Test strategy does not provide the required full test-level taxonomy (contract and e2e are missing)

## Evidence

The Test Strategy section details unit and integration coverage per goal, plus one structural-lint and one smoke note. It does not explicitly define contract-test coverage or e2e-test coverage and what each validates.

## Required fix (as suggested)

Add explicit contract and e2e test layers (with responsibilities and representative assertions) alongside existing unit/integration coverage.

## Disposition: DISMISSED

This codebase's test taxonomy is `tests/unit/` + `tests/integration/` + `tests/acceptance/` (all BATS). There is no formal contract layer — QRSPI agents are internal; there is no external API surface with contracted consumers. The "e2e" layer in this taxonomy is the acceptance suite, which v0.7.1 does not expand beyond the G7a-driven restructuring already noted.

Adding "contract" and "e2e" test layers would be cargo-cult application of a generic web-app testing taxonomy that does not match this codebase's structure.

The finding's suggested fix also asks for "representative assertions" — which is structurally incompatible with the QRSPI Design DEFERS contract (assertion text is owned by Implement / TDD), confirmed by scope-codex finding F01 against the same Test Strategy section. Adding assertions would create a scope violation flagged by the scope reviewer in the next round.

## Orchestrator action

No artifact change applied. Round-2 reviewer will be informed via round1_resolution that this finding was dismissed with documented rationale.
