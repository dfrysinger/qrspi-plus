---
finding_id: R6-F02
severity: low
change_type: clarity
referenced_files: [tests/unit/test-agent-frontmatter-no-model.bats]
artifact: tests/unit/test-agent-frontmatter-no-model.bats
round: 6
reviewer: sf-claude
closes: ~
new_path_introduced_by_r5: true
---

**Title:** `in_scalar` is dead state after R5 — variable tracked but never influences any decision

**Location:** `tests/unit/test-agent-frontmatter-no-model.bats` (diff lines 38–42, `n == 1` block inside `_frontmatter`)

**Post-R5 awk implementation (relevant section):**

```awk
{ gsub(/\r$/, "") }
/^---$/ {
  # Top-level --- always terminates any active block scalar
  in_scalar = 0
  n++
  if (n == 1) { next }
  if (n == 2) { exit }
}
n == 1 {
  if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
  else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
  print
}
```

**The problem:**

Before R5, `in_scalar` guarded the delimiter counter:
```awk
if (!in_scalar) { n++; if (n==1) next; if (n==2) exit }
```
That guard was the **sole consumer** of `in_scalar`'s value for any decision. R5 removed the guard and replaced it with an unconditional `in_scalar = 0; n++; …`. The `n == 1` block still sets and clears `in_scalar`, but now:

- `in_scalar = 1` is set when a block-scalar key line is seen → the value is never subsequently read by any conditional that affects output or control flow
- `in_scalar = 0` is reset in the `else if` branch → same — written but never meaningfully read
- The `/^---$/` handler resets it unconditionally before counting → overrides whatever the `n == 1` block might have left it as

The variable has become a write-only dead variable. `in_scalar` is tracked through multiple state transitions but has zero effect on `_frontmatter`'s output.

**Why this matters for silent-failure risk:**

1. **Misleading future readers:** A maintainer reading the code sees `in_scalar` being tracked and may infer it still protects against some failure mode. It does not. A reader could conclude the scalar-at-end case is handled "by the in_scalar guard" — but the guard is gone.

2. **Style indicator regex gap hidden by dead state:** The detection regex `/:[[:space:]]*[|>][[:space:]]*$/` does not match `|-`, `|+`, `>-`, `>+` (chomping indicators trail the style character). In R4, this was a latent bug: if `in_scalar` failed to be set for `|-` forms, the old guard could still let through a stray `---`. In R5, this gap is harmless because `in_scalar` has no effect — but the dead variable obscures the fact that the regex gap exists and was silently rendered moot by the architectural change.

3. **Comment/code divergence:** The `n == 1` block's `else if` branch retained its `in_scalar` logic but `!/^---$/` was removed from the condition (diff line 41). This is correct (the `/^---$/` handler fires before `n == 1` for `---` lines, so `n == 1` never sees them). But with dead `in_scalar`, the only evidence of this correctness argument is in the commit comments, not the code structure.

**Clarification on R4-F01 closure:**

R5 **fully closes** R4-F01. The unconditional `in_scalar = 0; n++` sequence means the closing `---` is always counted regardless of scalar state — the scalar-at-end silent path no longer exists. The two new `[r5-sf.F01]` tests exercise this path (subject to R6-F01's caveat on the second test).

**Fix:**

Remove the now-dead `in_scalar` tracking from the `n == 1` block entirely, since it serves no purpose:

```awk
n == 1 {
  print
}
```

The comment explaining the scalar-at-end rationale (lines added at diff 17–21) is sufficient to document why no `in_scalar` guard is needed. Alternatively, keep a minimal comment noting that `in_scalar` was removed when the unconditional reset was adopted.

**Severity note:**

This is a clarity issue, not a correctness or runtime failure. `_frontmatter` produces correct output with the dead variable present. The risk is future maintainer confusion about what protects against block-scalar false-positives.
