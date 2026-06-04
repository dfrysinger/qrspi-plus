---
reviewer: silent-failure-claude
round: 3
finding: F02
severity: medium
category: vacuous-test / trivially-true assertion
file: tests/unit/test-plan-post-approval-split.bats
lines: 689–715
---

# F02 — Mismatch HALT test: "file is unchanged" assertions are vacuously true

## Test under examination

`[split] Mismatch HALT: changed plan.md block with existing file halts and leaves file untouched` (line 689).

## What the test claims to verify

That when a Case 3 mismatch is detected (stored hash ≠ re-computed hash), the orchestrator **leaves the existing `tasks/task-NN.md` file untouched**.

The test makes three grep assertions intended to confirm the file still contains its original v1 content and does not contain the amended v2 content:

```bash
# File is NOT rewritten (content unchanged — same as written).
grep -F "# Task 1: original title" "$FIXTURE_DIR/tasks/task-01.md"   # line 712
grep -F "Original body."           "$FIXTURE_DIR/tasks/task-01.md"   # line 713
! grep -F "amended title"          "$FIXTURE_DIR/tasks/task-01.md"   # line 714
```

## Why the assertions are vacuously true

The test body:
1. Writes the file once (lines 697–704) with `# Task 1: original title` and `Original body.`
2. Extracts `stored_hash` and compares it with `hash_v2` (line 708–709) — this IS meaningful.
3. Makes the three content-grep assertions (lines 712–714).

**There is no code between step 2 and step 3 that touches the file.** No simulated orchestrator write, no `sed -i`, no `cat >` — nothing. The file contains exactly what was `cat >`-written at step 1 and cannot possibly contain anything else. Each of the three assertions is guaranteed to pass from the moment the file is created.

To fail line 712, something would have had to remove or overwrite `# Task 1: original title`. Nothing does. The same logic applies to lines 713 and 714. The "file is unchanged" property is not being verified against an attempted rewrite; it is trivially true because no attempt is ever made.

## What IS covered

The meaningful assertion is at line 709:

```bash
[ "$stored_hash" != "$hash_v2" ]
```

This pins that the hash computed from version-A content differs from the hash of version-B content — i.e., that the mismatch condition *is detectable*. That is a real property.

## Risk

If an orchestrator implementation were to overwrite the task file on mismatch (the exact bug the test is designed to prevent), **this test would not catch it**, because the content assertions all fire before any simulated orchestrator action that could rewrite the file. The test gives reviewers and implementors false confidence in the "file left untouched" guarantee.

## Remediation sketch

Simulate an attempted rewrite as the failure mode, then assert the file is unchanged:

```bash
# After establishing mismatch condition:
[ "$stored_hash" != "$hash_v2" ]

# Simulate: HALT fires; orchestrator must NOT rewrite the file.
# Record the content before the hypothetical "rewrite attempt":
local content_before
content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

# A correct orchestrator does nothing here (halt path).
# A buggy orchestrator would cat > the file with v2 content.
# (No action simulated — representing the correct halt.)

local content_after
content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
[ "$content_before" = "$content_after" ]  # now: meaningful only if something could have changed it
```

In this form the assertion is still trivially true in the test body *unless* a simulated "buggy" rewrite is introduced as a conditional gate; alternatively, the test comment should be updated to acknowledge that the assertion is a doc-only pin, and the behavioral "file unchanged" guarantee is covered by the multi-task HALT test's content-comparison block at lines 964–971.
