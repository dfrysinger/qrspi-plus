# tc-claude · Finding F02 · Round 09

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** cumulative diff to d889166  
**Change type:** coverage gap (dead-code / zero mutation resistance)  
**Severity:** medium

---

## Description — `in_scalar` is dead code; the block-scalar mutation-resistance claim is unsupported

### Location
`tests/unit/test-agent-frontmatter-no-model.bats`, lines 41–45:

```awk
n == 1 {
  if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
  else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
  print
}
```

### What the code does — and what it does not do

`print` is **unconditional** — it executes for every line where `n == 1`,
regardless of the value of `in_scalar`.  The two branches in the block above
only mutate `in_scalar`; they do not gate the `print` call.

Therefore `in_scalar` has **no effect on function output** in the current
implementation.  The algorithm actually does exactly this:

> Strip trailing CR from every line; print every line that falls between the
> first and second column-0 `---` delimiter.

The `in_scalar` tracking is vestigial.  It was meaningful in an earlier
version of the code where a guard `(!in_scalar)` protected the `n++`
increment inside the `/^---$/` block.  The scalar-at-end fix (sf.F01)
removed that guard and unconditionally increments `n`, making `in_scalar`
a no-op everywhere else.

### Why this is a test-coverage problem

The block-scalar test at lines 183–211 is annotated as testing **sf.F02
"block-scalar tracking"**, claiming it exercises the `in_scalar` mechanism.
It does not.  The test passes because `/^---$/` is anchored at column 0 and
the fixture's `  ---` is indented — not because of `in_scalar`.

This means:

1. **No test detects removal of all `in_scalar` tracking code.**  Deleting
   lines 42–43 (`in_scalar = 1 / in_scalar = 0`) and line 36
   (`in_scalar = 0` before `n++`) produces identical output for every
   existing fixture.  The full test suite still goes green.

2. **A developer who adds output-gating via `in_scalar` would introduce a
   real regression without any test catching it in the correct direction.**
   For example, changing `print` to `if (!in_scalar) { print }` would
   suppress `description: |` and block-scalar-content lines from the
   frontmatter output.  The block-scalar test (line 183) would still pass
   because `model: sonnet` comes *after* the block scalar ends (in_scalar
   is reset to 0 by the `^[^[:space:]]` guard before `model:` is printed),
   so the grep would still find it.  The missing `description: |` line
   would go unnoticed.

3. **The test comment at line 30–35 states that the fix "tracks block-scalar
   context so a bare `---` at column 0 inside a block scalar is not mistaken
   for the closing delimiter."**  In valid YAML, block scalar content is
   always indented — a column-0 `---` cannot appear inside a block scalar.
   The protection actually comes entirely from the `/^---$/` column-0 anchor,
   not from `in_scalar`.  The comment is correct in its reasoning
   ("column-0 `---` cannot appear inside a block scalar") but wrong in
   implying `in_scalar` provides the guard.

### Concrete mutations that pass all 8 tests undetected

**Mutation A — remove all `in_scalar` tracking:**
```diff
  n == 1 {
-   if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
-   else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
    print
  }
```
All 8 tests pass. Output is identical.

**Mutation B — add output suppression during in_scalar:**
```diff
  n == 1 {
    if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
    else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
-   print
+   if (!in_scalar) { print }
  }
```
The block-scalar test (line 183) still passes because `model: sonnet` is
printed (in_scalar is reset to 0 before the `model:` line).  The missing
`description: |` and `  ---` lines go undetected since no test asserts
the *complete* frontmatter output — only that `model:` is or is not present.

### Recommended fixes

**Option A — Simplify by removing the dead code and updating comments:**

```awk
_frontmatter() {
  awk '
    { gsub(/\r$/, "") }
    /^---$/ {
      n++
      if (n == 1) { next }
      if (n == 2) { exit }
    }
    n == 1 { print }
  ' "$1"
}
```

Update the block-scalar test comment to explain the real mechanism:
> "A bare `---` inside a block scalar is always indented; `/^---$/` only
> matches column-0, so indented `---` content is never treated as a
> closing delimiter."

**Option B — Make `in_scalar` functional and test the output contract:**

If `in_scalar` is kept for documentation/forward-compatibility purposes,
add an assertion that verifies the *complete* frontmatter output of a
block-scalar fixture (not just `model:` presence):

```bash
@test "[_frontmatter] block-scalar fixture: complete output equals expected" {
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-output-completeness.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-complete
description: |
  some text
model: sonnet
---
EOF
  local got
  got=$(_frontmatter "$fixture")
  local expected
  expected=$'name: qrspi-test-complete\ndescription: |\n  some text\nmodel: sonnet'
  [ "$got" = "$expected" ] || {
    echo "frontmatter output mismatch"
    echo "  expected: $expected"
    echo "  got:      $got"
    return 1
  }
}
```

This test would detect Mutation B (suppressed lines), providing real
mutation resistance.
