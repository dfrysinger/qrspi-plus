---
finding_id: R1-F06
reviewer: test-coverage-claude
artifact: plan.md
task: Task 34
severity: medium
change_type: correctness
---

# T34 — block-hash trailing-whitespace normalization invariance not exercised

## What

Task 34 (G5 Plan post-approval split idempotency) DoD specifies:

> Hash calculation is documented as sha256 hex, no salt, over the normalized
> source `### Task N` block; **normalization strips trailing whitespace from
> each line and preserves all other characters and line breaks**.

The Test expectation echoes the documentation:

> The hash calculation is verified as sha256 hex with no salt over the
> normalized source `### Task N` block, where normalization strips trailing
> whitespace from each line and preserves all other characters and line
> breaks.

But there is no test fixture exercising the *invariance* the normalization
exists to guarantee. The normalization rule's whole purpose is that two
plan.md edits that differ only in trailing whitespace should produce the same
hash, so a whitespace-only edit doesn't trigger the
"plan.md task block has changed" halt diagnostic.

Test expectations cover:

- Block-hash header presence ✓
- Hash calculation shape ✓
- Mismatch halt path ✓
- Missing-header halt path ✓
- Malformed-header halt path ✓
- Hand-edit preservation (when hash matches) ✓
- Quick-fix path ✓

They do NOT cover:

- "Edit `plan.md` `### Task N` block to add/remove trailing whitespace on N
  lines; re-run split; verify hash still matches and the task file is safe-
  skipped (no false-positive mismatch halt)."
- "Edit `plan.md` `### Task N` block to add/remove a blank line in the
  middle of the block (blank line = empty line, which is NOT trailing
  whitespace on the prior content line); re-run split; verify hash differs
  and the mismatch halt fires (positive control that normalization does NOT
  collapse blank lines)."

## Why this is a test-coverage problem

Test criteria 4 (Test Expectation Quality, falsifiable): there exists an
implementation that would fail this expectation. The current test recipe
verifies hash *calculation* shape but not normalization *behavior*. An
implementation that strips ALL whitespace (instead of trailing whitespace
only) or one that strips no whitespace at all would both satisfy the existing
test expectations as written, because no fixture distinguishes those
implementations.

The whole load-bearing reason for trailing-whitespace stripping (per design.md
## G5) is editor-driven whitespace churn between commits. A test that doesn't
exercise the invariance can't prevent regressions where an
over-aggressive normalizer collapses a meaningful edit, or where an
under-aggressive normalizer flags a no-op edit as a conflict.

## Falsifiable alternative

Extend the T34 Test expectations with two paired fixtures:

- "Whitespace-invariance fixture: edit `plan.md` `### Task N` block to add
  trailing spaces/tabs on every line; rerun the split; assert the existing
  `tasks/task-NN.md` is safe-skipped (no mismatch halt) and the file is not
  rewritten."
- "Blank-line-sensitivity fixture: edit `plan.md` `### Task N` block to
  insert or delete a blank line within the block body (not adjacent to the
  task heading boundaries); rerun the split; assert the mismatch halt fires
  with the documented `task-NN.md exists but its source block in plan.md has
  changed…` diagnostic."

These two fixtures jointly pin the normalization scope to "trailing
whitespace only" with falsifiable positive and negative controls.

## References

- plan.md ### Task 34 — DoD line 4, Test expectation line 2.
- design.md ## G5 — normalization rule scope and editor-driven-churn
  rationale.
