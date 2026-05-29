---
finding: F03
reviewer: sec-claude
round: 5
task: 1
severity: low
category: race-condition / TOCTOU
file: scripts/run-third-party-llm.sh
lines: 596-597
---

# F03 — NUL pre-flight TOCTOU — config.md read twice; concurrent write creates a false-negative window

## What the code does

```bash
# scripts/run-third-party-llm.sh  lines 596-597
_raw_file_bytes=$(wc -c < "$CONFIG_MD" | tr -d ' \t')
_raw_no_nul_bytes=$(LC_ALL=C tr -d '\000' < "$CONFIG_MD" | wc -c | tr -d ' \t')
```

The NUL pre-flight opens `$CONFIG_MD` **twice** via two separate shell
redirections.  The byte counts are compared to detect NUL bytes.

## What goes wrong

Between the two opens, a concurrent process can modify `config.md`.  If
the file contains NUL bytes before the first read and is rewritten without
NUL bytes before the second read, both counts are identical and the NUL
check silently passes.

### Concrete attack scenario

This attack requires an adversary who already has write access to
`config.md` (e.g., a malicious CI step, a compromised companion process,
or a concurrent writer that also controls the file).

1. Adversary writes `config.md` with a NUL byte embedded in a header value:

   ```yaml
   X-Header: safe\x00injected
   ```

2. The awk parse runs (before line 596); bash strips NUL at variable
   assignment, so `HEADER_VALUES[0]` = `"safeinjected"` (NUL silently gone).

3. The first read (`wc -c < "$CONFIG_MD"`) captures the byte count
   *including* the NUL — e.g., `_raw_file_bytes = 187`.

4. **Race window**: Adversary atomically replaces `config.md` with the
   same file but with the NUL byte removed (byte count 186).

5. The second read (`LC_ALL=C tr -d '\000' < "$CONFIG_MD"`) reads the
   *new* file which has no NUL bytes; `_raw_no_nul_bytes = 186`.

6. `[ 187 -ne 186 ]` is **true** — the pre-flight fires and dies.

   …OR in the reverse-race direction:

4'. Adversary atomically replaces `config.md` *without* NUL, then
    mid-flight of the second read, replaces it back to the NUL version.
    The second read counts the no-NUL file → `_raw_no_nul_bytes = 186`.
    Compare: `_raw_file_bytes = 186` (already captured without NUL).
    `[ 186 -ne 186 ]` is **false** — pre-flight passes silently.

## Practical impact

The impact is bounded.  Even if a NUL byte slips past the pre-flight:

- Bash already stripped the NUL at variable assignment (step 2 above), so
  `HEADER_VALUES` never contains a NUL byte.
- The downstream `_control_char_check` on `HEADER_NAMES[i]` / `HEADER_VALUES[i]`
  operates on the already-NUL-stripped in-memory values.  No NUL can appear
  in the final `Authorization: Bearer` header via this path.

The attacker's "win" is defeating a defensive diagnostic check, not actually
injecting NUL bytes into the curl call.  Severity is LOW accordingly.

## Why it is still worth noting

The NUL pre-flight was added specifically because bash strips NUL silently,
making it impossible to detect NUL after the fact from bash variables.
A TOCTOU that lets NUL-containing files pass the pre-flight undermines the
defense-in-depth intent, even if the NUL injection itself cannot succeed via
the bash-variable path.

## Recommended fix

Read the file once into a variable and compare from memory, avoiding the
second file-system access:

```bash
# Read the file once; count total bytes and NUL-stripped bytes from the
# same in-memory snapshot to close the TOCTOU window.
_raw_config=$(cat "$CONFIG_MD"; printf x)        # trailing x prevents subst. stripping
_raw_file_bytes=$(printf '%s' "$_raw_config" | wc -c | tr -d ' \t')
_raw_no_nul_bytes=$(printf '%s' "$_raw_config" \
  | LC_ALL=C tr -d '\000' | wc -c | tr -d ' \t')
# Subtract 1 for the appended sentinel 'x' from both counts.
_raw_file_bytes=$(( _raw_file_bytes - 1 ))
_raw_no_nul_bytes=$(( _raw_no_nul_bytes - 1 ))
```

Alternatively, use a single `cat` to a temp file and run both counts from
that captured copy, then `rm` the temp file.
