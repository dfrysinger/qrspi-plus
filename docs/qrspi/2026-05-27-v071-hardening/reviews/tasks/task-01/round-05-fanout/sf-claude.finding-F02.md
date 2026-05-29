---
finding: F02
reviewer: sf-claude
round: 5
task: 1
severity: medium
category: swallowed-errors / missing-pipefail
file: scripts/run-third-party-llm.sh
lines: 34, 218-221
---

# F02 — No `set -o pipefail`; intermediate pipeline failures in `_control_char_check` are silently discarded

## What the code does

```bash
# scripts/run-third-party-llm.sh  line 34
set -u

# lines 218-221 — pipeline inside a command substitution
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
  | LC_ALL=C tr -d '\040-\176\200-\377' \
  | wc -c \
  | tr -d ' \t')
```

## What goes wrong

The script enables `set -u` (undefined-variable error) but **not
`set -o pipefail`**.  In a four-stage pipeline without pipefail, the
pipeline's overall exit code is determined solely by the *last* command
(`tr -d ' \t'`), regardless of whether any earlier stage exited non-zero.

Concretely, if `LC_ALL=C tr -d '\040-\176\200-\377'` fails with a non-zero
exit (e.g., SIGPIPE, `ENOMEM`, locale sub-system error), that failure is:

1. Invisible to the outer `$( ... )` command substitution — the substitution
   exit code is `tr -d ' \t'`'s exit code, which is typically 0.
2. Invisible to any caller of `_control_char_check` — the function itself
   has no mechanism to detect the failure.
3. Invisible at the call site in the `while` loop (lines 614–620) or at the
   API-key check (line 649), which check only the function's return code.

The outcome depends on what the broken intermediate stage left on the pipe:

| Broken stage produces…        | `_cc_count` value | Check result      |
|-------------------------------|-------------------|-------------------|
| No output at all              | `"0"`             | Passes — **fail-open** (see F01) |
| Partial output (some bytes)   | Count of partial  | May pass or die — unpredictable |
| Normal output despite error   | Correct count     | Correct result by luck |

The fail-open case in row 1 is the critical path.

## Scope

This is a general property of the entire script, not limited to
`_control_char_check`.  However, `_control_char_check` is the security-
critical path that the task specifically hardened, making the missing
`pipefail` most consequential there.

Other affected pipelines added by T1:
- NUL pre-flight `_raw_no_nul_bytes` (line 597): a failing `LC_ALL=C tr`
  stage would leave `wc -c` counting zero bytes, yielding `"0"`, which
  survives the numeric `case` guard but gives an incorrect count.
- `env | grep -q "^${API_KEY_ENV}="` (line 636): `env` failure is masked.

## Recommended fix

Add `set -o pipefail` alongside the existing `set -u`:

```bash
set -u
set -o pipefail
```

`pipefail` causes a pipeline to return the exit code of the rightmost
command that exited non-zero.  Inside a `$( ... )` substitution a non-zero
exit propagates, allowing the numeric guard (F01's fix) to catch it.

Note: `set -o pipefail` is a bash extension; it is not specified by POSIX sh
but is present in bash 3.2+ (macOS system bash), which is already the
shebang target (`#!/usr/bin/env bash`).
