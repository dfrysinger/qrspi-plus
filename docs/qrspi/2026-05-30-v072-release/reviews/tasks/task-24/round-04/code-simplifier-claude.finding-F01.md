# F01: Inconsistent `echo` vs `printf` for stderr error messages

**Reviewer:** code-simplifier-claude  
**Round:** 4  
**File:** `scripts/detect-interaction-mode.sh`  
**Lines:** 87–90 (usage guard) vs. 119–121 (invalid QRSPI_INTERACTION_MODE error)  
**Category:** Inconsistency (§5)  
**Severity:** Advisory / non-blocking

---

## What's happening

The script uses `echo` for stderr output in the usage guard (lines 87–90) but switches to `printf` for the invalid-override-value error path (lines 119–121). Every other output statement in the script uses `printf`. The usage guard is the sole inconsistency.

**Current — usage guard (lines 87–90), uses `echo`:**
```bash
echo "Usage: detect-interaction-mode.sh  (no arguments)" >&2
echo "  This helper emits one KEY=VALUE pair per line describing the" >&2
echo "  interaction-mode detection result for the active host." >&2
echo "  It accepts no positional arguments." >&2
```

**Current — invalid override error (lines 119–121), uses `printf`:**
```bash
printf 'Error: QRSPI_INTERACTION_MODE=%s is not a valid value.\n' \
  "${QRSPI_INTERACTION_MODE}" >&2
printf 'Allowed values: auto, interactive\n' >&2
```

---

## Proposed simplification

Replace the `echo` calls with `printf` to match the dominant pattern throughout the rest of the script. Since these lines carry no format substitutions, the change is mechanical:

```bash
printf 'Usage: detect-interaction-mode.sh  (no arguments)\n' >&2
printf '  This helper emits one KEY=VALUE pair per line describing the\n' >&2
printf '  interaction-mode detection result for the active host.\n' >&2
printf '  It accepts no positional arguments.\n' >&2
```

Alternatively, change the two `printf` calls at lines 119–121 to `echo`, since `echo` is also acceptable for unstructured error prose. Either direction eliminates the inconsistency. The `printf` direction matches the larger pattern of the file.

---

## Why this matters

A reader scanning the script quickly learns "this file uses `printf` for all output" — then hits the usage guard and must decide whether `echo` is deliberate (a semantic distinction) or accidental (a style drift). There is no semantic distinction here: both are unstructured stderr text, no format substitutions needed, and the output-shape contract applies only to stdout. Removing the inconsistency eliminates that false-question cost for future readers.

No behavior change. No test changes required (the usage diagnostic tests check for keywords with `grep -qiE`, not for specific quoting characters).
