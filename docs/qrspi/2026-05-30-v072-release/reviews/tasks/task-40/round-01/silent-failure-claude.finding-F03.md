---
reviewer: silent-failure-claude
task: 40
round: 1
finding: F03
severity: low
category: parser blind spot / silent miss
file: tests/lint/test-bats-body-assertion-guard.bats
lines: 54-72
---

# F03 — G21 walker silently ignores `$body` assertions outside `@test` blocks

## What

The awk state machine gates every `[[ "$body" ...` check on
`in_block`, which is only set to `1` inside lines following a
`^@test ` opener:

```awk
/^@test / { in_block = 1; has_guard = 0; next }
/^\}/ && in_block { in_block = 0; has_guard = 0; next }
in_block && /\[ -n "\$body" \]/ { has_guard = 1 }
in_block && /\[\[ "\$body"/ && !has_guard { printf ... }
```

Any `[[ "$body" ... ]]` assertion that lives outside an `@test` block —
e.g., inside `setup()`, `setup_file()`, `teardown()`, a helper function
sourced via `load`, or a top-level reusable assertion — is silently
skipped. The lint emits no diagnostic; the corpus walk completes green.

This is a meaningful gap because:

- The class of bug G21 is hardening against (vacuous match when `$body`
  is empty) does not care whether the assertion lives in `@test` or in
  a helper called from `@test`. A helper named `assert_body_contains`
  built around `[[ "$body" == *X* ]]` is exactly as silently-vacuous as
  the inline form the lint catches.
- The DoD language ("every `[[ "$body" ... ]]` assertion that lacks an
  earlier guard in the same block") technically scopes to `@test`
  blocks, so this is arguably by-design — but if a future refactor
  moves the R5-era pins into a shared helper, the live positive
  controls go dark and the lint silently degrades to all-green with
  zero coverage of the actual surface.

A secondary, related blind spot: the closer regex `^}` matches a
column-0 `}` regardless of context (heredoc body, multi-line string,
embedded bash function defined inside a `@test` block). A spurious
column-0 `}` mid-block flips `in_block=0` and silently disables the
lint until the next `@test`. The current corpus does not hit this, but
it is the same class of silent-miss.

## Why this matters

Silent under-coverage of the very class the rule exists to gate. If
the rule is intended to scope strictly to `@test`-block bodies, that
scope decision deserves an inline comment naming the trade-off so a
future refactor (moving assertions into helpers) does not silently
strip enforcement.

## Suggested resolution

At minimum, add an inline awk comment naming the `@test`-scoped
restriction so future readers know the helper-function surface is
intentionally uncovered. Optionally, extend the rule to flag any
`[[ "$body"` outside an `@test` block that does not have a guard on
the file level (or in the enclosing function) — but this risks
false positives in helpers that legitimately guard at their call
sites.
