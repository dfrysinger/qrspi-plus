---
finding: F02
reviewer: cq-claude
round: 5
task: 1
severity: low
category: cleanliness / missing-orientation-comment
file: tests/unit/test-run-third-party-llm.bats
lines: 537-551
---

# F02 — LF regression-guard test script assembly lacks an "expected output" comment

## What the code does

The Bullet-5 (LF regression guard) test constructs a 4-line bash script via
eight sequential `printf` calls to embed a literal LF byte inside a
single-quoted bash argument:

```bash
# tests/unit/test-run-third-party-llm.bats  lines 537-551
local test_script="$FIXTURE_DIR/lf_test.sh"
{
  printf '%s\n' '#!/usr/bin/env bash'
  printf 'die() { exit 1; }\n'
  printf '. %s\n' "'$fn_file'"
  printf '_control_char_check %s ' "'x-lf-header'"
  printf "'"
  printf 'safe'
  printf '\012'
  printf "injected'\n"
} > "$test_script"

run bash "$test_script"
[ "$status" -ne 0 ]
```

The comment above the block explains *why* the technique is used ("Single-quoted
strings spanning newlines are valid bash") but does **not** show *what* the
resulting file contains.

## What goes wrong

A reader must mentally simulate all eight `printf` calls and their
concatenation to verify that the output is:

```
#!/usr/bin/env bash
die() { exit 1; }
. '/path/to/ctrl_fn.sh'
_control_char_check 'x-lf-header' 'safe
injected'
```

The critical step — that `printf '\012'` inserts a literal LF *inside* the
single-quoted argument (not outside it, which would terminate the argument
and break the syntax) — is not visually obvious from the printf sequence
alone.  Specifically:

- `printf '_control_char_check %s ' "'x-lf-header'"` leaves an unterminated
  line (no `\n`).
- `printf "'"` opens the second argument's single-quote on the same line.
- `printf 'safe'` writes the start of the value.
- `printf '\012'` writes a bare LF — which closes the first line of the
  script file but is *inside* the single-quoted bash argument (valid bash
  syntax for multi-line single-quoted strings).
- `printf "injected'\n"` closes the single-quote and terminates the statement.

A misread of the assembly (e.g., believing the LF terminates the argument
rather than spanning the string) would cause a reviewer to incorrectly flag
the test as syntactically wrong, or cause a future editor to "fix" it in a
way that breaks the LF-detection property silently.

## Recommended fix

Add a single-line comment immediately before the `run bash` call showing the
resulting script structure.  Inline representation sufficient for clarity:

```bash
  printf "injected'\n"
} > "$test_script"
# Assembled script calls: _control_char_check 'x-lf-header' $'safe\ninjected'
# The second argument contains a literal 0x0A byte inside the single-quoted string.

run bash "$test_script"
[ "$status" -ne 0 ]
```

This makes the test self-documenting: a reader can verify at a glance that
the LF is *inside* the argument and thus exercises `_control_char_check`'s
LF detection path.
