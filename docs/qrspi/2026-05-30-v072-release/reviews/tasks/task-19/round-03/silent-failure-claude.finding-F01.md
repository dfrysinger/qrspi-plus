---
finding_id: F01
reviewer_tag: silent-failure-claude
round: 3
severity: high
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:L36-L37
  - scripts/second-reviewer-available.sh:L41
  - scripts/second-reviewer-available.sh:L54
---

## Silent exit-0 when `_resolve-lib.sh` fails to source

**Category:** Swallowed Errors (Category 1) + Missing Error Path (Category 3)

### What can go wrong

`second-reviewer-available.sh` sources two library files at lines 36–37 with no exit-status check and no `set -e`:

```bash
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh"   # line 36
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh"   # line 37
```

If `_resolve-lib.sh` fails to load (file missing, unreadable, or contains a syntax error), bash continues executing because there is no `set -e` and no `|| { ... ; exit 1 }` guard. The consequence is that **both** library functions the guard depends on are left undefined:

1. `lookup_default_second_reviewer` (line 41) — undefined → command-substitution `$(...)` produces an empty string → `_default_vendor=""`
2. `second_reviewer_vendor_known` (line 54) — undefined → returns exit code 127 → `! 127` evaluates to **0 (false)**

### The silent exit-0 path (no vendor override required)

With `_resolve-lib.sh` absent/broken and no `$1` override on a real host (e.g., `COPILOT_CLI=1`):

```
_host        = "copilot-cli"   # detect_host from _host-detect.sh still works
_default_vendor = ""           # lookup_default_second_reviewer undefined
_vendor         = ""           # falls back to _default_vendor
```

Guard condition at L54 evaluates all three branches as **false**:

| Branch | Value | Result |
|---|---|---|
| `[ "" = "none" ]` | `_default_vendor` is empty, not "none" | FALSE |
| `[ "" = "none" ]` | `_vendor` is empty, not "none" | FALSE |
| `! second_reviewer_vendor_known ""` | function undefined → exit 127 → `!127` = 0 | FALSE |

All false → guard does **not** fire → probe reaches `exit 0` at line 62.

The same path fires with a recognized override vendor (e.g., `openai-codex`): `[ "openai-codex" = "none" ]` is still false, and `second_reviewer_vendor_known` is still undefined → same silent exit-0.

### Why `_host-detect.sh` failure does NOT produce this bug

If only `_host-detect.sh` fails (and `_resolve-lib.sh` loads correctly), `detect_host` is undefined → `_host=""` → `lookup_default_second_reviewer ""` matches the `*` catch-all → returns `"none"` → `[ "none" = "none" ]` is TRUE → guard fires → exits 1 correctly. The asymmetry is because `_resolve-lib.sh` contains **both** functions required for the guard to fire; losing it loses both.

### Spec requirement violated

Task-19 spec (Definition of done): *"Unknown host, missing default vendor, unknown vendor, and unavailable vendor all exit non-zero with exactly one stderr line beginning `[second-reviewer-unavailable]`."*

A broken/missing `_resolve-lib.sh` is not one of the four named failure modes, but the result is worse than any of them: the probe reports **available** when the entire availability machinery is broken.

### Recommended fix

Add an explicit source-error guard for `_resolve-lib.sh` (and optionally `_host-detect.sh`) immediately after each source line:

```bash
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh" || {
  printf '[second-reviewer-unavailable] host=<unknown> vendor=<unknown> — failed to source _host-detect.sh\n' >&2
  exit 1
}
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh" || {
  printf '[second-reviewer-unavailable] host=<unknown> vendor=<unknown> — failed to source _resolve-lib.sh\n' >&2
  exit 1
}
```

Alternatively, add a post-source emptiness check for `_default_vendor` that treats an empty default as a hard failure (not equivalent to `"none"`):

```bash
if [ -z "$_default_vendor" ]; then
  printf '[second-reviewer-unavailable] host=%s vendor=<unresolved> — lookup_default_second_reviewer returned empty (source failure?)\n' "$_host" >&2
  exit 1
fi
```

Both fixes together are the most robust: the source guard catches the failure at the origin point with an accurate diagnostic, while the emptiness check provides a backstop if the function returns empty for any other reason.
