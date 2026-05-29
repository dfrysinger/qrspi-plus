---
finding: F03
round: 2
reviewer: sf-claude
file: scripts/run-codex-review.sh
line: 540
change_type: correctness
severity: low
title: check_codex_available stderr suppressed at dispatch call site — unrecognized-host diagnostic permanently swallowed
---

## Summary

At the dispatch surface, `check_codex_available` is called with `2>/dev/null`:

```bash
if ! check_codex_available "$_detected_host" 2>/dev/null; then
```

`check_codex_available` is specified (and tested in TE11) to emit a single-line
diagnostic to stderr when it receives an unrecognized host argument.  The
`2>/dev/null` at this call site unconditionally redirects that stderr output to
/dev/null, making the unrecognized-host diagnostic permanently invisible at
the dispatch level.

## Why this matters now

Currently `detect_host` always returns either `copilot-cli` or `claude-code`,
both of which are recognized by `check_codex_available`, so the unrecognized
branch is never reached in practice.  However:

1. The `2>/dev/null` makes this an **architectural** silent-failure point.  Any
   future change that introduces a third host value (or a code-path bug that
   produces an unexpected string) will silently swallow the diagnostic that was
   explicitly designed to surface the problem to an operator.

2. The TE11 test validates the function's diagnostic *in isolation* (via
   `QRSPI_SOURCE_ONLY` sourcing), but there is no test verifying that the
   dispatch call site surfaces the diagnostic.  The `2>/dev/null` means such a
   test could never pass even if written, because the message is eaten before it
   reaches the test's stderr capture.

3. There is no documented reason for the suppression.  The `2>/dev/null` appears
   defensive (possibly to avoid noise when `check_codex_available` is called
   with `claude-code` and no companion exists), but `check_codex_available`
   writes nothing to stderr on normal non-error paths — only on the unknown-host
   `*)` branch.  The suppression is therefore unnecessary for normal operation
   and actively harmful for the error case.

## Relevant code

```bash
# check_codex_available — stderr output contract (lines 137-140):
    *)
      echo "check_codex_available: unsupported host argument: $host" >&2
      return 1
      ;;

# Dispatch call site (line 540):
if ! check_codex_available "$_detected_host" 2>/dev/null; then
```

## Fix

Remove the `2>/dev/null` redirection.  The function already scopes its
stderr output to the error case only; suppression at the call site is
not needed and undermines the diagnostic contract:

```bash
# Before:
if ! check_codex_available "$_detected_host" 2>/dev/null; then

# After:
if ! check_codex_available "$_detected_host"; then
```

If suppression of the unrecognized-host path is intentional (e.g., by design
the dispatch surface never surfaces function-level diagnostics and relies solely
on mismatch-warning logic), that should be documented explicitly and the TE11
function-isolation test should note that the dispatch surface does not re-surface
this diagnostic.
