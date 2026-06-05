---
finding_id: F01
severity: minor
area: id-hygiene
file: tests/unit/test-interactive-skill-prompts.bats
lines: 28-32, 37
---

## Issue

QRSPI-internal goal IDs (`G33`, `G14`) appear in a test-file comment and in
`@test` names — the strict surface for ID Hygiene Rule 11.

```
28. # G33 / Rule 5 presence + absence contract: the literal Rule 5 phrase is
29. # Design-only per user scope (v0.7.2 self-host G14 walkthrough directive);
30. # Goals must not carry it.
...
32. @test "design/SKILL.md carries the Rule 5 simple-language-and-context phrase (G33)" {
...
37. @test "goals/SKILL.md does not carry the Rule 5 simple-language-and-context phrase (Design-only scope)" {
```

Three distinct ID-hygiene hits:

1. **Line 28 comment — `G33`.** A QRSPI-internal token in a code comment outside
   `docs/qrspi/`. Rule 11 (strict surfaces, comments split): "forbidden in code
   comments, test names, describe / it blocks, and fixture names — flag every
   occurrence outside `docs/qrspi/`, regardless of how scoped."
2. **Line 29 comment — `G14`.** Same rule. This one is the most load-bearing
   instance because `G14` references an unrelated goal (a "walkthrough
   directive") that a reader of this test file cannot resolve without leaving
   the file. It is exactly the failure mode Rule 11 targets: a run-specific
   token copied from the task spec / dialog into permanent test prose.
3. **Line 32 test name — `(G33)`.** Same rule, test-name surface.

## Why it matters

Test names and comments outlive the run that produced them. After v0.7.2 ships
and the goal-numbering re-baselines, `G14` and `G33` decay into mystery tokens
that send future readers chasing dead anchors. The behavior asserted by these
tests (Design carries the simple-language phrase; Goals does not) stands on its
own without any goal numbering.

## Suggested fix

Strip the goal IDs and let the behavioral description carry the meaning:

```bats
# Rule 5 presence + absence contract: the "use simple language and provide
# context when presenting ideas" phrase is Design-skill-only — Goals must
# not carry it.

@test "design/SKILL.md carries the Rule 5 simple-language-and-context phrase" {
  ...
}

@test "goals/SKILL.md does not carry the Rule 5 simple-language-and-context phrase" {
  ...
}
```

The `(Design-only scope)` parenthetical on line 37 is fine as-is — that is
behavioral, not an internal ID — but the matched parenthetical on line 32
should change with it for consistency.

## Out of scope

The pre-existing `#118 / #115` tracker references at lines 4–5 are not in this
round's diff and are not flagged here.
