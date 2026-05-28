---
artifact: design
reviewer: scope-claude
round: 1
finding_id: scope-claude-F04
severity: low
change_type: scope
file: design.md
section: "Test Strategy"
lines: 129
---

# F04: Test Strategy G2 specifies shell-command-level test procedure

## Evidence

Test Strategy G2 says: "Integration test that simulates the implementer commit flow (Write scratch + `git add -A` + `git status --porcelain` shows scratch absent from index)."

## Rule violated

This crosses from design-level test strategy (what type of test, what layer, what behavior is verified) into assertion-adjacent procedure. The explicit git command sequence and the output assertion ("shows scratch absent from index") are Implement / TDD territory per the DEFERS contract ("Full assertion text → Implement (TDD)").

## Required fix

Reduce to behavior-level framing: e.g., "Integration test verifying that the scratch file does not appear in the staged index when a simulated commit flow runs."

## Convergence note

Partial convergence with scope-codex F01 (which flagged per-test-file layout in the same Test Strategy section). Both findings target the Test Strategy section but for different boundary signals.
