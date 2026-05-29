# sf-claude Finding F01 — mktemp failure not checked; misleading diagnostic swallows the real cause

| Field           | Value |
|-----------------|-------|
| file            | `tests/helpers/skill-markdown.bash` |
| line            | 240 |
| change_type     | correctness |
| severity        | medium |
| confidence      | high |
| pattern         | Silent Fallback + Inappropriate Error Transformation |

## Code under review

```bash
# line 239-240 (sec.F01 fix, bb0541b)
local signal_tmp
signal_tmp="$(mktemp "${TMPDIR:-/tmp}/skill-md-fence-signal-XXXXXXXX")"
```

## What goes wrong

`mktemp` can fail (disk full, `TMPDIR` set to a non-existent or non-writable
directory, `/tmp` permissions, etc.).  When it does the command substitution
returns an empty string and the assignment line exits non-zero — but **neither
is checked**.  `signal_tmp` silently becomes `""`.

The function then continues into awk with `-v signal_tmp=""`.  Two divergent
failure paths follow, both with wrong diagnostics:

| awk behaviour with `signal_tmp=""` | Resulting message | Truth |
|------------------------------------|-------------------|-------|
| awk's END-block `print > ""` silently no-ops; awk exits **0** | `"not found in <file>"` | mktemp failed |
| awk's END-block `print > ""` triggers an I/O error; awk exits **2** | `"awk failed (exit 2) processing <file>"` | mktemp failed |

In both branches the function returns 1 (so a *non-silent* failure at the
exit-code level), but:

1. **The caller receives a false root-cause** — it is told the anchor is
   missing or that awk crashed, when the real problem is an exhausted
   filesystem / bad `TMPDIR`.
2. **Automated retry or fallback logic keyed on the error message will
   misroute** (e.g. a caller that retries on "not found" will loop forever).
3. **The old code had no failure path here** (`local signal_tmp="/tmp/…-$$"`
   is infallible), so this is a **new** silent-failure surface introduced by
   the sec.F01 fix.

### Tracing the empty-string path in detail

```
signal_tmp=""                                 # mktemp failed, no check
awk -v signal_tmp="" … "$file"                # awk launches
  END { print "FOUND_WITH_CONTENT" > "" }     # silent I/O error OR no-op
# awk exits 0 or 2

# If awk exits 0:
#   [ -r "" ] → false  →  signal=""  →  * case  →  "not found in"

# If awk exits 2:
#   awk_status != 0  →  "awk failed (exit 2)"
#   rm -f ""  →  silently ignores empty argument (POSIX)
```

Neither path names mktemp as the cause.

## Recommended fix

Check mktemp's exit status immediately and emit an unambiguous diagnostic:

```bash
local signal_tmp
signal_tmp="$(mktemp "${TMPDIR:-/tmp}/skill-md-fence-signal-XXXXXXXX")" || {
  printf 'extract_section_fence_aware: mktemp failed (TMPDIR=%s)\n' \
    "${TMPDIR:-/tmp}" >&2
  return 1
}
```

This makes the mktemp failure fast-fail with a correct message before awk
is ever invoked, and prevents the misleading "not found in" / "awk failed"
masking.

## Why the existing tests do not catch this

- **[sf-F01]** fakes `awk` via `PATH` shadowing inside a `bash -c` subprocess.
  `mktemp` is not faked and succeeds, so `signal_tmp` is always valid — the
  test never exercises the `signal_tmp=""` branch.

- **[sec-F01]** calls `extract_section_fence_aware` directly with the real
  `mktemp`; same situation — mktemp succeeds.

- **[sf-F03]** likewise uses the real `mktemp`.

A test that sets `TMPDIR` to a non-writable directory and asserts the
function exits 1 with a message containing `"mktemp"` would cover this path.
