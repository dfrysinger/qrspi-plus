---
finding_id: F02
reviewer_tag: code-quality-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:271-274
artifact: tests/unit/test-change-type-partition.bats
---

# Dead loop variable: per-value coverage assertion is vacuous

In the test `"G13: all five canonical change_type values are accepted through
the same parser path"` (diff lines 447–450, bats file ~lines 271–274), the
`for` loop iterates over all five canonical values but **never uses the loop
variable `$ct`**:

```bash
for ct in style clarity correctness scope intent; do
  grep -qE "canonical-claude\.finding-F0[0-9]+\.md$" "$KEPT" \
    || { echo "kept-findings.txt missing finding files"; cat "$KEPT"; return 1; }
done
```

Every iteration runs the identical `grep -qE "canonical-claude\.finding-F0[0-9]+\.md$"` pattern against `$KEPT`.  The pattern matches if **any** canonical finding appears in the file.  Consequently:

- All five iterations succeed as soon as a single finding is present in `kept-findings.txt`.
- A run that kept only `style` (one finding) would pass this loop; a run that kept only `F01` would also pass.
- The loop body provides zero additional assurance over running the grep once — all five iterations are identical.

The comment directly above the loop says *"Every canonical value's finding must appear in kept-findings.txt"*, but the assertion does not enforce that.

## Why the `seen` cross-check doesn't fully compensate

The `seen` block that follows (lines 455–463) does read each kept path's
`change_type:` frontmatter and verifies all five values appear.  That check
is sound, but it operates on file content, not on whether a file *per se* was
listed in `kept-findings.txt`.  The vacuous loop does not add any coverage the
`seen` check lacks; it merely creates the false impression that individual
file-presence is confirmed per value.

## Suggested fix

Either remove the loop entirely (since the `seen` check does the real work) or
rewrite it to verify that each finding file actually appears in `$KEPT`,
e.g. by correlating fixture filename to loop index:

```bash
local i=1
for ct in style clarity correctness scope intent; do
  grep -qF "canonical-claude.finding-F0${i}.md" "$KEPT" \
    || { echo "kept-findings.txt missing F0${i} (change_type=$ct)"; cat "$KEPT"; return 1; }
  i=$((i + 1))
done
```

Or simply rely on the existing `seen` cross-check alone and delete the
redundant loop.
