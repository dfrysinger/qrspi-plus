---
finding: F02
reviewer: sec-claude
round: 5
task: 1
severity: low
category: data-exposure / terminal-injection
file: scripts/run-third-party-llm.sh
lines: 45-47, 222-223
---

# F02 — Raw control bytes emitted verbatim in die-path diagnostic — terminal manipulation via crafted header name

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 45-47
die() {
  printf 'run-third-party-llm: %s\n' "$1" >&2
  exit 1
}

# lines 222-223 — _control_char_check die call
[ "$_cc_count" -eq 0 ] || \
  die "header-validation: default_headers for provider '${PROVIDER:-}' \
contains a control character in header '$_cc_hname'"
```

When `_control_char_check` detects a control character in a header name,
the die message includes `$_cc_hname` verbatim — the exact string that
triggered the detection, including the offending control byte.  `die()`
passes this through `printf '%s'` unchanged to stderr.

## What goes wrong

`printf '%s'` propagates raw bytes to stderr; the terminal (or any
process consuming stderr) receives the control bytes.

### Concrete attack scenario

1. An attacker writes a `config.md` whose `default_headers` block contains
   a header name embedding an ANSI escape sequence, e.g.:

   ```yaml
   default_headers:
     "X-Safe\x1b[2K\x1b[1A": some-value
   ```

2. The script detects the ESC byte (0x1B), calls `die`, and emits to stderr:

   ```
   run-third-party-llm: header-validation: default_headers for provider 'my-prov'
   contains a control character in header 'X-Safe<ESC>[2K<ESC>[1A'
   ```

3. If an operator's terminal receives this stderr (e.g., CI log, local run),
   the ANSI sequence `ESC[2K` erases the current terminal line and `ESC[1A`
   moves the cursor up — the error diagnostic disappears from view.

4. The operator sees no error output, may conclude the run succeeded, and
   does not investigate the header-validation failure.

More powerful sequences (OSC, DCS, window-title injection) could interfere
with terminal state or exfiltrate clipboard content on susceptible terminals.

### Scope: header VALUE path

`_control_char_check` concatenates `$_cc_hname` and `$_cc_hval` for
detection.  The die message only echoes `$_cc_hname`, so the header *value*
containing the control byte is not directly in the diagnostic.  However,
for the name-side injection path, the control byte IS in `$_cc_hname`
and IS echoed.

## Why this is not already mitigated

The `die()` function is a thin wrapper around `printf '%s'`.  It performs
no sanitization of its argument.  The `_control_char_check` caller
intentionally places the raw header name in the message for diagnostic
value, but that same header name is the source of the control bytes.

## Recommended fix

Sanitize the header name in the die-path message before emission.  The
simplest approach is to replace non-printable bytes with a `?` placeholder
or a hex-escape representation:

```bash
# In _control_char_check, sanitize the name for the diagnostic:
_safe_hname=$(printf '%s' "$_cc_hname" \
  | LC_ALL=C tr '\000-\037\177' '?')
[ "$_cc_count" -eq 0 ] || \
  die "header-validation: default_headers for provider '${PROVIDER:-}' \
contains a control character in header '${_safe_hname}'"
```

This ensures the die message itself cannot contain terminal-control bytes
while preserving readable diagnostic information about which header name
was rejected.
