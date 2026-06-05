# stitching-audit.finding-F03

**reviewer_tag:** stitching-audit
**round:** 8
**artifact:** structure
**section:** ## File Map → Slice 1.5
**severity:** medium
**change_type:** missing-downstream-test

## Finding

The R7 delta adds a Slice 1.5 File Map row for `agents/qrspi-plan-test-coverage-reviewer.md` with Addition C — a standalone inline guard ("Scope: only `task_type: code` tasks. Skip evaluation of any task with `task_type: lightweight`"). design.md L2704 anchors this as a verbatim block with anchor phrase *"Scope: only `task_type: code` tasks."*

**No test row in the Slice 1.5 File Map (or anywhere in the File Map) pins the presence and correct content of Addition C.**

The closest candidate is `tests/unit/test-author-skill-uses-cat.bats` (structure.md L129, G31+G34) which is described as: "Guard shared include usage for prompt-prose and design-boundary snippets." Addition C has **no** `!cat` include and **no** wrapper preload — it is a standalone inline addition. `test-author-skill-uses-cat.bats` will not catch a drift, omission, or misplacement of Addition C in the agent file.

design.md L2704 explicitly calls out: "Consumer #9 (`agents/qrspi-plan-test-coverage-reviewer.md`) contains Addition C verbatim at the TOP of its review-procedure section. Anchor phrase: *'Scope: only `task_type: code` tasks.'* Does NOT declare `prompt-prose-reviewer` in its `skills:` frontmatter."

This anchor phrase is the testable assertion — but no test row is specified to check it.

## Impact

If Addition C is accidentally dropped, misplaced (not at TOP of review-procedure), or silently reworded, no existing test will catch it. The consequence at runtime is that `qrspi-plan-test-coverage-reviewer` emits false-positive findings for lightweight task Test Expectations (flagging absence of RED-gate failing tests on prompt-prose tasks by design).

## Cross-check: other reviewers needing skip-lightweight guards

The Addition C rationale (design.md L2587-2592) is specific to **RED-gate coverage criteria** — only `qrspi-plan-test-coverage-reviewer` evaluates failing-test presence in plan Test Expectations. `qrspi-plan-security-reviewer`, `qrspi-plan-silent-failure-hunter`, and `qrspi-plan-spec-reviewer` review different plan attributes that apply regardless of task_type and do not check for RED-gate tests. No other plan reviewer needs an equivalent guard per the design rationale. This is not a gap in scope — the skip-lightweight guard is correctly scoped to one agent.

## Fix

Add a test row to Slice 1.5 (or expand `test-author-skill-uses-cat.bats`' scope):

```
| `tests/unit/test-plan-test-coverage-reviewer-scope.bats` | Create | Assert Addition C anchor phrase is present at the TOP of qrspi-plan-test-coverage-reviewer's review-procedure section and that the agent file does NOT list `prompt-prose-reviewer` in its `skills:` frontmatter. | G31 |
```

(Alternatively, expand the existing `test-author-skill-uses-cat.bats` to cover standalone-inline anchor phrase presence checks alongside the `!cat` include checks already guarded there.)
