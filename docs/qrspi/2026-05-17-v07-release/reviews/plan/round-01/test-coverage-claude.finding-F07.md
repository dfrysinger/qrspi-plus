---
finding_id: R1-F07
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T24 lacks a safe-default test expectation — a gap that design.md Decision 10 makes load-bearing.

Design.md Decision 10 states: "A task spec that does not set these fields [reference_gate, reference_artifact, ui, lift_source] should behave exactly like a v0.6 task. Plan, Parallelize, and Implement should treat the absence of each field as the safe default."

This is the most important correctness property of the entire Slice 5 schema migration: the new fields must be purely additive. However, T24's test expectations focus entirely on the positive cases (field presence, paired-field enforcement, SPEC OVERRIDES SOURCE requirements, migration) and do not include a safe-default test.

A safe-default test expectation would read something like: "A task spec with no reference_gate:, reference_artifact:, ui:, or lift_source: fields is written and processed without error, produces no paired-field diagnostic, triggers no visual-fidelity reviewer dispatch, and triggers no reference-gate pause — behaving identically to a pre-Slice-5 task spec."

Without this expectation, the test suite for T24 could pass entirely even if the implementation breaks backward compatibility with old task specs. The safe-default behavior is the contract that protects all pre-existing task specs across the entire repo from being broken by the Slice 5 schema migration, and it needs an explicit test expectation.
