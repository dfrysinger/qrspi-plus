---
finding: F01
reviewer: sf-claude
round: 5
task: 1
severity: high
category: silent-fallback / fail-open
file: scripts/run-third-party-llm.sh
lines: 218-222
---

# F01 — `_control_char_check` lacks the fail-closed numeric guard present in the NUL pre-flight

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 218-222
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
  | LC_ALL=C tr -d '\040-\176\200-\377' \
  | wc -c \
  | tr -d ' \t')
[ "$_cc_count" -eq 0 ] || \
  die "header-validation: ..."
```

## What goes wrong

The NUL pre-flight (lines 596–605) explicitly validates its computed byte
counts before comparing them:

```bash
case "$_raw_file_bytes" in
  ''|*[!0-9]*) die "header-validation: failed to compute byte counts …" ;;
esac
```

The inline comment even names the failure mode:

> Fail closed: if either count is non-numeric (pipeline/tool failure), die
> immediately rather than silently bypassing NUL detection (fail-open).

`_control_char_check` applies identical pipeline arithmetic but has **no
equivalent numeric guard**.

### Concrete fail-open path

1. `LC_ALL=C tr -d '\040-\176\200-\377'` is killed by SIGPIPE (or the
   process is forcibly terminated on a resource-exhausted host) *after* it
   has emitted zero bytes to the pipe but *before* it exits non-zero.
2. `wc -c` receives zero bytes from stdin and writes `"0\n"` to its stdout.
3. The final `tr -d ' \t'` strips whitespace; command substitution strips the
   trailing newline.  `_cc_count` is assigned the string `"0"`.
4. `[ "0" -eq 0 ]` evaluates to *true* (exit 0).
5. The `||` branch is **not taken** — `die` is **not called**.
6. The function returns 0 (success), and execution continues to the network
   dispatch even though the header or API-key value contained control
   characters.

This is exactly the fail-open scenario the NUL pre-flight was hardened
against.  The same SIGPIPE / truncated-output scenario is possible here
whenever an HTTP proxy, container stdin limit, or system resource pressure
kills `tr` mid-pipe.

### The empty-`_cc_count` case is NOT fail-open (but is a wrong error)

If `_cc_count` is completely empty (e.g., the whole pipeline produces no
output), then `[ "" -eq 0 ]` returns exit 2 in bash ("integer expression
expected"), the `||` fires, and `die` is called — but with the message
"contains a control character in header '…'", which is wrong; the actual
failure was a tool/pipeline error.  The NUL pre-flight catches this and
emits the correct "failed to compute byte counts" diagnostic.

## Why this is high-severity

The guard was explicitly designed and documented in the NUL pre-flight.  Its
absence from `_control_char_check` is the same latent silent-failure pattern
that the task set out to eliminate from the old `grep -qP 2>/dev/null`
implementation: a tool-layer failure makes the security check a silent no-op.

## Recommended fix

Add the same numeric guard immediately after the `_cc_count` assignment:

```bash
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
  | LC_ALL=C tr -d '\040-\176\200-\377' \
  | wc -c \
  | tr -d ' \t')
# Fail closed: if the pipeline did not return a numeric count, die rather
# than treating tool failure as "no control chars found" (fail-open).
case "$_cc_count" in
  ''|*[!0-9]*) die "header-validation: failed to compute control-char byte count for header '$_cc_hname' (provider '${PROVIDER:-}')" ;;
esac
[ "$_cc_count" -eq 0 ] || \
  die "header-validation: default_headers for provider '${PROVIDER:-}' contains a control character in header '$_cc_hname'"
```
