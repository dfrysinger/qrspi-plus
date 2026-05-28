---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: scope-claude
---

@test BATS syntax in Task 8 test-expectations bullet (Implement-TDD layer leak)

Task 8 line 241: "An automated absence assertion (a new `@test` block in tests/unit/test-run-third-party-llm.bats)..."

@test is BATS framework syntax — a test-code structural token. Owns/defers: "Full assertion text / test code → Implement-TDD." Plain-language phrasing: "a new automated assertion in tests/unit/test-run-third-party-llm.bats greps..." — no @test token.

Fix: Replace "@test block" with plain-language phrasing.

Note: Task 3 concrete stderr prefix strings (R3 fix 10) and Task 6 [transport:] markers are PASS — observable-behavior specification, not assertion code.
