---
reviewer: test-coverage-claude
task: 32
round: 5
finding_id: F02
severity: low
category: missing-scenarios
files:
  - tests/unit/test-interactive-skill-prompts.bats
---

# F02 — Goals finalize test does not pin the `approved` status-flip target inside the finalize block

## What the spec requires

Task-32 Test Expectations (line 57):

> "Goals validates locked goal completeness, optionally appends Purpose
> if absent, and flips `status: draft` to `approved`."

The finalize-time flip target (`approved`, not `approved-pending-review`)
is the load-bearing differentiator between the two skills' end-state
contracts.

## What the tests actually pin

`tests/unit/test-interactive-skill-prompts.bats:162-167`:

```bash
@test "goals/SKILL.md finalize pass flips status: draft to approved" {
  grep -F "finalize" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "Validate that every locked goal" "$REPO_ROOT/skills/goals/SKILL.md"
}
```

The test name claims to verify the `draft → approved` flip, but the
assertions only verify (a) the word `finalize` and (b) the
completeness-validation sentence. The actual `Flip frontmatter
`status: draft` to `status: approved`.` line is never grep-anchored.

A future edit could silently change the finalize bullet to
`approved-pending-review` (matching Design) and this test would still
pass.

## Suggested fix

Add a grep anchor for the literal finalize-block flip sentence (which
is unique within `goals/SKILL.md` — `approved-pending-review` does not
appear anywhere in that file):

```bash
@test "goals/SKILL.md finalize pass flips status: draft to approved" {
  grep -F "finalize" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "Validate that every locked goal" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "Flip frontmatter \`status: draft\` to \`status: approved\`" \
    "$REPO_ROOT/skills/goals/SKILL.md"
  # Goals must not drift toward Design's flip target.
  run grep -F "approved-pending-review" "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}
```

The negative grep on `approved-pending-review` doubles as a regression
guard against cross-contamination from the Design SKILL contract.
