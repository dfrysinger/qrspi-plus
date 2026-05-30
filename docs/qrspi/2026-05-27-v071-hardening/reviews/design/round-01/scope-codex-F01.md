---
artifact: design
reviewer: scope-codex
round: 1
finding_id: scope-codex-F01
severity: medium
change_type: scope
file: design.md
section: "Test Strategy"
lines: 123-141
---

# F01: Test Strategy crosses Design DEFERS boundary by specifying per-test-file layout

## Evidence

`## Test Strategy` (lines 123-141) specifies per-test-file layout and concrete test placement, naming specific files like `tests/unit/test-run-third-party-llm.bats`, `tests/unit/test-skill-md-content-patterns.bats`, and a new `tests/unit/test-agent-frontmatter.bats`. The Design OWNS contract limits test strategy to test types / layers / frameworks and explicitly defers per-test-file layout to downstream artifacts.

## Required fix

Keep strategy at architecture level (what is tested, at what layer, by what test type / framework) and move file-level test allocation to Plan / Implement.

## Convergence note

Partial convergence with scope-claude F04 (which flagged shell-command-level test procedure in the G2 entry of the same section). Both findings target the Test Strategy section but for different boundary signals.
