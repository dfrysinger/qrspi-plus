---
finding: F03
reviewer: sec-claude
round: 2
task: 6
severity: low
change_type: correctness
file: scripts/run-codex-review.sh
lines: [526, 542]
---

# Mismatch diagnostic echoes unsanitized config.md value to stderr (log injection)

## Summary

The `_codex_reviews` value is extracted from `ARTIFACT_DIR/config.md`
with `awk` (lines 526–534) and then interpolated verbatim into an `echo`
statement (line 542).  The awk strips leading/trailing whitespace but
does not strip terminal escape sequences or other control characters.  A
crafted `config.md` can inject arbitrary content into the stderr stream,
including ANSI terminal control sequences that manipulate an operator's
terminal session.

## Vulnerable code

```bash
# lines 526-534  scripts/run-codex-review.sh
_codex_reviews="$(awk '
  /^---$/ { n++; if (n == 2) exit; next }
  n == 1 && /^codex_reviews:/ {
    sub(/^codex_reviews:[[:space:]]*/, "")
    sub(/[[:space:]]*$/, "")
    print
    exit
  }
' "$ARTIFACT_DIR/config.md")"

# line 542
echo "[mismatch] detected host=${_detected_host}, codex_reviews config=${_codex_reviews}" >&2
```

## Concrete attack scenario — terminal escape injection

An attacker with write access to `ARTIFACT_DIR/config.md` (a realistic
condition in multi-tenant CI or shared artifact directories) sets:

```yaml
---
codex_reviews: true
---
```

replaced by:

```
---
codex_reviews: true
---
```

Where the value on the `codex_reviews:` line is followed by embedded
ANSI sequences, for example (shown as hex):

```
codex_reviews: true\x1b[H\x1b[2J\x1b[1;31m[CRITICAL] Auth bypass active\x1b[0m
```

When an operator's terminal processes the raw stderr output, it sees
the cleared screen and a fake red `[CRITICAL]` banner.  Combined with
social engineering this can trick an operator into believing a different
security event is in progress.

## Concrete attack scenario — fake log-line injection

Using a newline-containing value is harder through awk (awk processes
one record at a time), but any control character that the operator's log
viewer interprets specially — carriage return (`\r`), backspace (`\x08`),
OSC sequences — can be smuggled through the single `awk` record.

Example with a carriage return to overwrite the beginning of the line:

```
codex_reviews: true\r[transport: task-tool]
```

In a terminal or simple log viewer the line prints as:
```
[transport: task-tool]
```
making it indistinguishable from a legitimate transport marker.

## Why it matters

`ARTIFACT_DIR` is specified by the script caller via `--artifact-dir`.
In automated pipelines the directory's `config.md` is often written by
an earlier job step.  If that step is compromised (supply-chain attack,
misconfigured write permissions), injecting terminal control into the
review script's stderr is trivially achievable without touching the
reviewed code itself.

## Recommended fix

Strip non-printable characters from `_codex_reviews` before echoing:

```bash
# After the awk extraction:
_codex_reviews="$(printf '%s' "$_codex_reviews" | tr -cd '[:print:]')"
```

`tr -cd '[:print:]'` removes all non-printable characters (including
ANSI ESC, carriage return, and other control bytes), leaving only the
legitimate Boolean value (`true` / `false`) that the field is expected
to contain.

Alternatively, validate that `_codex_reviews` matches `^(true|false)$`
and treat any other value as `false`:

```bash
case "$_codex_reviews" in
  true|false) ;;
  *) _codex_reviews="false" ;;
esac
```

This is both the safer and the more correct approach given that only
`true` is tested against downstream (line 541).
