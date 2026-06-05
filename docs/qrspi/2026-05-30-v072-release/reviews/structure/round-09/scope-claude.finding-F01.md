---
finding_id: R9-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L129]
artifact: structure
round: 9
reviewer: scope-claude
---

Boundary drift — embedded literal assertion text in a Phase-2 file-map row.

The R8 fix at line 129 expands the `tests/unit/test-author-skill-uses-cat.bats` row to read:

> "...additionally pin the standalone Addition C anchor phrase (`\"Scope: only `task_type: code` tasks.\"`) at the TOP of `agents/qrspi-plan-test-coverage-reviewer.md` so silent drift or misplacement of the scope guard is caught."

The parenthetical embeds the **literal, quoted phrase the test will assert on** ("Scope: only `task_type: code` tasks."). The Structure OWNS/DEFERS rule set explicitly defers this content downstream:

- DEFERS: "Test assertion code → Implement (TDD)."
- DEFERS: "Per-task LOC, full assertion text, per-task commit ranges, line-by-line logic → Plan / Implement."
- DEFERS: "Actual prompt or SKILL.md text content → Plan / Implement."
- And the closing paragraph of `owns-defers.md` names this exact pattern as the canonical boundary-drift example: "embedding a literal compaction-callout sentence rather than just the placement site".

Structure owns "Test file layout (behavior level) … the behavior each test file exercises at a one-line description level. Not assertion code, not assertion text." Naming the placement site (`agents/qrspi-plan-test-coverage-reviewer.md` TOP of review-procedure section) and the behavior (guards the Addition C scope-anchor against drift / misplacement) is in-scope; quoting the literal anchor string is not — that wording belongs in the Plan/Implement task that authors the .bats assertion and in the agent file that carries the inline Addition C text. If the anchor wording shifts during Plan/Implement, structure.md becomes a second source of truth that can silently disagree with the test and the consumer agent.

**Suggested fix.** Strip the literal quoted phrase from the row and leave the behavior-level description. For example:

> "Guard shared include usage for prompt-prose and design-boundary snippets; additionally guard the standalone Addition C scope-anchor at the TOP of `agents/qrspi-plan-test-coverage-reviewer.md` so silent drift or misplacement of the scope guard is caught."

The exact anchor phrase belongs in plan.md's per-task `## Test Expectations` block (or in the implementing .bats file), not in structure.md.
