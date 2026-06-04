---
reviewer: test-coverage-claude
task: 32
round: 5
finding_id: F01
severity: medium
category: missing-scenarios
files:
  - tests/unit/test-interactive-skill-prompts.bats
---

# F01 — Design finalize pass under-pins the two validation steps that the task scopes as DoD

## What the spec requires

Task-32 Test Expectations (line 57) and DoD (line 46) both explicitly require
that tests pin the Design finalize pass as performing **two distinct
validations** before the status flip:

> "Design validates every `goals.md` goal has all five fields populated,
> validates Cross-Goal Decisions well-formedness, and flips `status: draft`
> to `approved-pending-review`."

These are two named gating invariants on top of the status-flip target.

## What the tests actually pin

The only finalize-targeted assertions for Design are at
`tests/unit/test-interactive-skill-prompts.bats:169-172`:

```bash
@test "design/SKILL.md finalize pass flips status: draft to approved-pending-review" {
  grep -F "finalize" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "approved-pending-review" "$REPO_ROOT/skills/design/SKILL.md"
}
```

This test would pass even if a future edit silently:

1. Removed the "Validate that every goal in `goals.md` has a corresponding
   per-goal block in `design.md` with all five fields populated" bullet
   from the finalize pass, OR
2. Removed the "Validate the `## Cross-Goal Decisions` section is
   well-formed (each entry keyed by ID, each entry carries rationale +
   scope)" bullet.

The string `approved-pending-review` already appears elsewhere
(`approved-pending-review` is in the hand-edit prohibition sentence too),
and the word `finalize` appears multiple times in the section header
and Hand-edits sentence. Neither validation gate is anchored.

Compare to the analogous Goals test
(`tests/unit/test-interactive-skill-prompts.bats:162-167`), which
deliberately pins a finalize-block-unique phrase
(`"Validate that every locked goal"`) precisely to avoid this failure
mode — the comment in that test even calls out the risk explicitly:

```
# Pin a finalize-block-unique phrase so this test fails if the finalize block is deleted
# but the mid-phase prohibition line (which also contains "status: draft" and "approved") remains.
```

The Design test does not apply the same defensive pinning even though it
faces the same risk plus an additional one (two named validations, not
just one).

## Why this matters

Both the Cross-Goal Decisions well-formedness check and the five-field
completeness check are the only mechanical gates standing between a
half-built `design.md` and `approved-pending-review` status. The task's
whole compaction-survival story rests on the finalize pass refusing to
flip status when an invariant fails (sf-F01 from the synthesizer-failure
fix is pinned via "Only flip status if all validations pass" at lines
253–258, but the actual **validations** being enumerated are not pinned
for Design).

## Suggested fix

Add two grep anchors to the Design finalize test, using phrases unique to
the finalize bullets (the current diff uses
`"corresponding per-goal block in \`design.md\` with all five fields populated"`
and `"\`## Cross-Goal Decisions\` section is well-formed"`, both of
which appear nowhere else in `design/SKILL.md`):

```bash
@test "design/SKILL.md finalize pass flips status: draft to approved-pending-review" {
  grep -F "finalize" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "approved-pending-review" "$REPO_ROOT/skills/design/SKILL.md"
  # Pin the two named validation gates from the DoD (Test Expectations line 57).
  grep -F "all five fields populated" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Cross-Goal Decisions\` section is well-formed" "$REPO_ROOT/skills/design/SKILL.md"
}
```
