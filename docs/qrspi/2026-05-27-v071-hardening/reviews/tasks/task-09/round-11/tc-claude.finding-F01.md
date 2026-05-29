# tc-claude · Finding F01 · Round 11

**Task:** T9 – Remove `model:` from agent frontmatter
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Commit under review:** cf52a40 (R10 folded-scalar + complete-output assertion)
**Delta scope:** a73ecb8..cf52a40 (+109 lines)
**Change type:** Test comment inaccuracy / overstated mutation-resistance claim
**Severity:** low (documentation only — no test logic defect)

---

## Summary

R9 tc.F01 and tc.F02 are addressed at the behavioural level. The `>` fixtures
are present, both `>` scenarios (model-after and scalar-at-end) are covered,
and the tc.F02 complete-output assertion genuinely catches Mutation B. One
residual issue: the comment in the first new test overstates what mutation it
catches, which is misleading for future maintainers.

---

## Detailed Analysis

### tc.F01 — Folded scalar (`>`) fixtures

**Status: addressed in spirit; comment is inaccurate.**

Two new tests were added:

| # | Test name | Assertion |
|---|-----------|-----------|
| 9 | `[r10-tc.F01] folded scalar (>): model: key after folded block scalar is detected` | `[ -n "$offending_line" ]` — model: IS found after `description: >` |
| 10 | `[r10-tc.F01] folded scalar-at-end: _frontmatter exits cleanly with no false positive` | `[ -z "$offending_line" ]` — body model: is NOT found when `>` is last key |

Both tests are **behaviorally meaningful** and exercise the `>` code path
end-to-end. They verify:
- A `>` block scalar does not prevent subsequent frontmatter keys from being
  output (test 9)
- A `>` block scalar as the last key does not cause the scanner to over-read
  into the document body (test 10)

**However, the comment in test 9 (diff lines 11–15; file lines 300–304) is
inaccurate:**

```text
# This test uses > so that the mutation [|>]->[|] (dropping folded-scalar
# support) is caught. Without this test, that mutation survives the full
# suite and leaves folded-scalar files silently un-linted.
```

This claim is wrong. Tracing the mutation `[|>]→[|]` through the production
`_frontmatter` awk:

```awk
n == 1 {
  if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }   ← only branch changed
  else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
  print                                                       ← unconditional
}
```

`print` is unconditional — `in_scalar` never gates output. With the mutation:
- Processing `description: >` → `in_scalar` remains 0 instead of being set to 1
- `model: sonnet` still hits the `else if` branch (which short-circuits because
  `in_scalar` is 0), then is printed unconditionally
- `offending_line` is still non-empty → test 9 still **passes** with the mutation
- The mutation remains fully unobservable, exactly as the implementer acknowledged

The same reasoning applies to test 10: the `/^---$/` block unconditionally
resets `in_scalar = 0` and increments `n` (the scalar-at-end fix from sf.F01
removed the old `(!in_scalar)` guard), so the closing `---` terminates the scan
regardless of whether `in_scalar` was ever set by the `>` path.

**Impact of the inaccuracy:** The comment tells future maintainers "this test
is a mutation detector for `[|>]→[|]`." It is not. A developer who later
simplifies the regex to `[|]` only will see the test pass and conclude the
change is safe for `>` files — it is safe (since `in_scalar` is dead code), but
the comment gives false assurance about the mechanism rather than the truth.

**Recommended correction to the test comment:**

```bash
# tc.F01: the production awk regex [|>] handles both literal (|) and folded
# (>) block scalars. All prior tests use only |. This test uses > to provide
# behavioural coverage of the folded-scalar path and confirm that model: keys
# following a > block scalar are correctly detected in the frontmatter output.
#
# Note: the in_scalar variable does not gate print (print is unconditional),
# so the mutation [|>]->[|] is not independently detectable via this test —
# that mutation is unobservable because in_scalar is dead code. The value of
# this test is end-to-end coverage of the > code path, not mutation-resistance
# against the regex character class specifically.
```

---

### tc.F02 — Complete-output assertion

**Status: fully addressed.** ✅

Test 11 (`[r10-tc.F02] complete-output`) makes three independent assertions
against the raw `_frontmatter` output for a `description: |` fixture:

1. `grep -qE '^description: \|'` — the block-scalar key line is present
2. `grep -q 'indented body line one'` — the indented body content is present
3. `grep -qE '^model: sonnet'` — the post-scalar key is present

Tracing Mutation B (`print` → `if (!in_scalar) { print }`):
- `description: |` sets `in_scalar = 1`; then `!in_scalar` is false → line
  **not printed**
- Assertion 1 fails immediately → test goes **RED** ✓

The implementer's report that "test 11 went RED with the guard" is confirmed by
code tracing. This test provides genuine mutation resistance against Mutation B.

---

### Regression check

The 8 prior tests (lines 49–298) are unchanged. The 3 new tests add tests 9,
10, and 11, giving a total of 11. No prior test logic is touched.

---

## Verdict

| Finding | Status | Action required |
|---------|--------|-----------------|
| R9 tc.F01 — `>` fixture absent | Addressed (behavioural coverage added) | Optional: correct test comment |
| R9 tc.F02 — no complete-output assertion | **Fully resolved** — test 11 catches Mutation B | None |
| Regression of prior 8 tests | None detected | None |
| Test comment inaccuracy (test 9, lines 300–304) | Present — overstates mutation-resistance | Low-priority documentation fix |

The R10 delta resolves the substance of both R9 findings. The one residual
issue is the misleading comment in test 9; it is documentation-only with no
impact on test correctness or pass/fail behaviour. No blocking action required.
