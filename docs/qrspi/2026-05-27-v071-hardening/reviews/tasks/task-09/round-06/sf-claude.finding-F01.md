---
finding_id: R6-F01
severity: low
change_type: correctness
referenced_files: [tests/unit/test-agent-frontmatter-no-model.bats]
artifact: tests/unit/test-agent-frontmatter-no-model.bats
round: 6
reviewer: sf-claude
closes: ~
new_path_introduced_by_r5: true
---

**Title:** Second `[r5-sf.F01]` scalar-at-end test is vacuously correct — cannot detect a regression

**Location:** `tests/unit/test-agent-frontmatter-no-model.bats` (diff lines 123–146, second new `@test` block)

**Test name:** `[r5-sf.F01] frontmatter with block-scalar last key and no body model: still clean`

**The problem:**

The test fixture body intentionally has no `model:` key anywhere:

```bash
cat >"$fixture" <<'EOF'
---
name: qrspi-test-scalar-at-end-clean
description: |
  some description text
  more description text
---
body starts here
no model key anywhere in this body
EOF
```

The verification is:

```bash
offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
[ -z "$offending_line" ] || { … return 1 }
```

The test passes when `offending_line` is empty. But `offending_line` is empty in **two distinct scenarios**:

1. `_frontmatter` exits correctly at the closing `---` and emits only the frontmatter (no `model:` there) → correct behaviour ✓
2. `_frontmatter` **fails to exit** and reads the full file — but since there is no `model:` in the body either, `grep` still finds nothing → test passes as a **false green** ✗

This means the test cannot distinguish the fixed implementation from a broken one that over-reads past the closing `---`. If the R5 fix were reverted (restoring the `!in_scalar` guard), this test would still pass because its body contains no `model:`.

**Contrast with the first scalar-at-end test:**

The companion test `[r5-sf.F01] frontmatter ending with block-scalar key exits cleanly at closing ---` has `model: something at body start` in the body, so an over-reading implementation would produce a non-empty `offending_line`, causing that test to correctly fail RED. That test fully covers the regression; the second test adds no incremental diagnostic power.

**Impact:**

Low — the first scalar-at-end test provides real coverage. The second test is redundant and vacuously safe. If someone later removes or modifies the first test, the second provides zero regression protection for the scalar-at-end bug.

**Fix options:**

(a) Change the body to include a line matching `^model:` (same as the first test) so both tests independently detect over-reading. Example:
```
body starts here
model: this line should not appear in frontmatter output
```
Then assert `[ -z "$offending_line" ]` — passes only if `_frontmatter` exited at `---`.

(b) Replace the grep-based assertion with a line-count check:  assert that `_frontmatter` emits at most N lines (where N = number of frontmatter keys), so over-reading into an unbounded body always fails.

(c) Remove the second test as redundant — the first scalar-at-end test fully covers the regression scenario.
