# cs-claude · Finding F01 · `in_scalar` state machine is vestigial dead code

**File:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Lines:** 36, 42–43 (worktree lines 36, 42–43)
**Severity:** Polish / Non-blocking
**Category:** Dead Code / Unnecessary Complexity

---

## What the code does today

The `_frontmatter` helper awk script maintains an `in_scalar` boolean to track
whether the current line is inside a YAML block-scalar value (a key ending with
`|` or `>`):

```awk
{ gsub(/\r$/, "") }
/^---$/ {
  in_scalar = 0          # ← resets the flag
  n++
  if (n == 1) { next }
  if (n == 2) { exit }
}
n == 1 {
  if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }  # ← sets the flag
  else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 } # ← resets the flag
  print
}
```

`in_scalar` is set, reset, and checked — but it **never gates any output or any
delimiter-counter increment**. The only effect of the `else if` branch is to
reset `in_scalar` to the value it already becomes on the next column-0 `---` hit
anyway.

## Why the state machine is dead

The purpose stated in the comment block (sf.F02) is to prevent an indented `---`
inside a block scalar from being mistaken for the closing frontmatter delimiter.
But the `/^---$/` regex already provides that discrimination without any help:

- `^` anchors to the start of the record (after `gsub` strips `\r`)
- `$` anchors to the end of the record
- An indented `---` such as `  ---` has leading whitespace and therefore does
  **not** match `/^---$/`

No `in_scalar` tracking is needed to distinguish the two cases — the regex alone
is sufficient.

The `in_scalar = 0` reset in the `/^---$/` block is a survivor of an earlier
draft that had a guard of the form `if (!in_scalar) { n++ }`. The scalar-at-end
fix (sf.F01 round 5) removed that guard and made `n++` unconditional. Once the
guard was removed, `in_scalar = 0` became a no-op (it resets a value that is
never consulted for the counter), and the `else if` branch became self-referential
dead code.

## All four edge-case tests still pass after removal

| Test | Why it still passes |
|---|---|
| CRLF | `gsub(/\r$/, "")` is unchanged |
| block-scalar indented `---` | `  ---` never matched `/^---$/`; no change |
| scalar-at-end closing `---` | `n++` is unconditional; no `!in_scalar` guard |
| body prose out of scope | `n == 1` guard still restricts `print` window |

## Proposed simplification

```awk
{ gsub(/\r$/, "") }
/^---$/ { n++; if (n == 1) { next }; if (n == 2) { exit } }
n == 1  { print }
```

Three rules, no state variables beyond `n`.  The comment block above
`_frontmatter` can be reduced to two bullet points (CRLF stripping; column-0
`---` anchor already excludes indented block-scalar content).

Also update the docblock: sf.F02 note ("track block-scalar context") would become
"the `/^---$/` anchor already excludes indented block-scalar content — no
context tracking required."
