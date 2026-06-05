---
finding_id: F03
reviewer_tag: code-simplifier-claude
round: 4
severity: suggestion
category: verbose-patterns
files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# `printf '%s\n' "$yaml"` repeated eight times where `echo "$yaml"` suffices

## What's happening

In `[AC5]` of `test-phase1-acceptance.bats`, the variable `$yaml` holds the
multi-line output of an `awk` extraction (always a non-trivial YAML block with
embedded newlines). Every field assertion and diagnostic print in the test
uses the form:

```bash
printf '%s\n' "$yaml" | grep -qE 'some-field:'
  || { echo "..."; printf '%s\n' "$yaml"; return 1; }
```

This form (`printf '%s\n'`) is the right choice when `$var` might be a
**single token without a trailing newline**, since `echo "$var"` would add a
newline and `printf '%s'` would not. But here `$yaml` already contains
embedded newlines (it is a YAML block produced by `awk`), so `printf '%s\n'`
and `echo "$yaml"` produce identical byte sequences: both append exactly one
`\n` after the last line of content.

The pattern appears **eight times** in AC5:

- 5 positive field assertions (lines piping to `grep -qE '^\s*-?\s*summary:'`, `finding_paths:`, `defect_class:`, `representative_score:`, `threshold:`)
- 3 negative assertions (bare `score:`, `contributing_findings:`, `observation_summary:`)
- 3 diagnostic prints inside the `if` error branches

## Suggested simplification

Replace every `printf '%s\n' "$yaml"` with `echo "$yaml"`:

```bash
# Before
printf '%s\n' "$yaml" | grep -qE '^\s*finding_paths:' \
  || { echo "..."; printf '%s\n' "$yaml"; return 1; }

# After
echo "$yaml" | grep -qE '^\s*finding_paths:' \
  || { echo "..."; echo "$yaml"; return 1; }
```

Alternatively, since all assertions operate on the same variable, the YAML
could be written to a temporary file once (or piped via a process substitution)
to avoid eight repeated subshell forks — but that is a performance micro-
optimisation and less readable than the simple `echo` substitution. The
`echo` form is the minimal readable win.

**Behavioural equivalence:** `printf '%s\n' "$yaml"` where `$yaml` ends in a
newline produces the same bytes as `echo "$yaml"`. Since `awk` always outputs
a trailing newline, this is safe. No test logic changes.
