---
finding_id: F02
reviewer_tag: silent-failure-claude
severity: medium
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:36-37
---

## Failed `source` operations silently continue — "exactly one stderr line" contract violated

### What the code does

`second-reviewer-available.sh` uses `set -u` but **not** `set -e`, then sources two
library files without checking their exit status:

```bash
set -u          # line 30 — nounset only, no errexit

QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh"    # line 36 — no error guard
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh"    # line 37 — no error guard
```

### The silent failure

If either source operation fails (file missing, wrong permissions, or a syntax error
in the library), bash emits its own error line to stderr:

```
bash: /path/to/_host-detect.sh: No such file or directory
```

Execution then continues (no `set -e`, no `|| { … }` guard). The required functions
are never defined, so the downstream command substitutions:

```bash
_host="$(detect_host)"
_vendor="$(lookup_default_second_reviewer "$_host")"
```

each spin up a subshell that fails with `detect_host: command not found` — another
error line to stderr — and returns an empty string.

Eventually the script does emit `[second-reviewer-unavailable]`, but by that point
stderr already contains two or more extra lines produced by the shell itself. The
`host=` and `vendor=` fields in the tagged diagnostic carry wrong values (empty
strings rather than the real host/vendor).

### Concrete contract violations

1. **"Exactly one line beginning `[second-reviewer-unavailable]`"** (probe header,
   task DoD): the bash error messages and `command not found` messages appear first,
   so the actual line count is ≥ 3, not 1.

2. **Named host and vendor**: the diagnostic reads `host= vendor=none` instead of
   `host=<detected-host> vendor=<vendor>`, making triage impossible.

3. **The actual root cause** (library load failure) is swallowed with no tagged
   diagnostic of its own.

### Fix direction

Add explicit error guards immediately after each source:

```bash
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh" || {
  printf '[second-reviewer-unavailable] host=unknown vendor=unknown — internal error: failed to load _host-detect.sh\n' >&2
  exit 1
}
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh" || {
  printf '[second-reviewer-unavailable] host=unknown vendor=unknown — internal error: failed to load _resolve-lib.sh\n' >&2
  exit 1
}
```
