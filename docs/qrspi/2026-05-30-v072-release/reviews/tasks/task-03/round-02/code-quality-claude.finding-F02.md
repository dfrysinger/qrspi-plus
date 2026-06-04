---
finding_id: R2-F02
severity: low
change_type: style
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats:158
artifact: task-03
round: 2
reviewer: code-quality-claude
---

# F02 — QRSPI-internal goal ID `G6` in new bats test comment (low · style)

**Convergence:** Same as `code-quality-codex.finding-F01.md` — G-token leak (G6/Task-03 in R2 test comments). Two independent reviewers caught it.

The new test comment added in round-02 (line 158 of `test-per-finding-file-emission.bats`) reads:

```
# Pins the post-split self-description: after G6/Task-03 moved the disk-write
```

`G6` is a QRSPI-internal goal ID. Per the ID hygiene rules, QRSPI-internal IDs (G/R/D/T/Q-prefixed numeric tokens) are forbidden in code comments, test names, `describe`/`it` blocks, and fixture names outside `docs/qrspi/`. The flag-target for this rule is run-specific tokens copied from the task spec into the diff — `G6` appears in the task-03 spec's `goal_ids` field and was copied into this comment.

The same issue exists at the pre-existing line 46 of the same file (`# (post-G6 split …)`) but that line is not part of the round-02 diff.

**Fix:** Replace `G6/Task-03` with task-neutral wording that conveys the same orientation:

```
# Pins the post-split self-description: after the reviewer-protocol skill split moved the disk-write
```

This retains the WHY (it's a post-split regression guard) without embedding the run-specific goal ID.
