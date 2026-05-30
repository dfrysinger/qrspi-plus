---
reviewer: tc-claude
round: 10
task: task-01
status: clean
---

## R10 Verification Summary — tc.F01 closure confirmed

### Checklist

**1. `012|015)` case-arm present in VALUE parametric loop**
✅ Confirmed. Line 569 of HEAD `df1dbc9`:
```
      012|015)
```
The previous `012)` arm (R8 base) now covers both LF (0x0A) and CR (0x0D).

**2. Literal CR byte embedded in the generated function-extraction test script**
✅ Confirmed. Line 586:
```bash
          printf "\\$_byte_octal"
```
For `_byte_octal=015`: bash expands `"\\$_byte_octal"` → `"\015"`, and
`printf "\015"` outputs a raw CR byte (0x0D) directly into the `_ts_val`
shell script file. The resulting script contains `'safe<CR>injected'` with a
literal 0x0D byte inside the single-quoted argument, which bash passes verbatim
to `_control_char_check`. This is the correct approach for injecting the byte
without awk-parse interference.

The LF case is also preserved: for `_byte_octal=012`, `printf "\012"` still
outputs LF — identical behaviour to the old hardcoded `printf '\012'`.

**3. CR no longer routes through `_write_ctrl_config`**
✅ Confirmed. 0x0D matches the `012|015)` branch before the `*)` wildcard,
so it never reaches the `_write_ctrl_config + _run_ctrl_check` integration
path that depends on awk preserving CR across its record-based config parse.

### New-issue scan (delta-only)

| Area | Result |
|---|---|
| Off-by-one byte handling | Clean — `010`, `013`, `014`, `016`, `017` and all other C0 bytes still fall through to `*)` correctly; no adjacent byte is misrouted. |
| Function-extraction script malformation for CR | Clean — single-quoted strings spanning 0x0D are valid POSIX bash; no shell special treatment of CR inside single quotes. |
| Loop-invariant breakage for other bytes | Clean — the `*)` path (`_write_ctrl_config` + `_run_ctrl_check`) is unchanged by the diff. |
| NAME loop symmetry | Clean — NAME parametric loop already had `012|015)` with `printf "\\$_byte_octal"` (lines 658, 673); the VALUE loop now matches it exactly. |

### Verdict

R9 fix for tc.F01 is complete and correct. No new issues introduced.
