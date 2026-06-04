# Finding F01 — Broken `grep -v` comment-filter in ordering test

**Severity:** LOW  
**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`  
**Line:** ~2845 (new `manifest lock-held block resets _manifest_tmp before trap install` test)

## Observation

The pipeline that locates the `_manifest_tmp=""` reset line attempts to exclude
comment-only occurrences of the string before the ordering check:

```bash
reset_line="$(grep -n '_manifest_tmp=""' "$script" \
  | grep -v '^\s*#' \
  | awk -F: -v lo="${mkdir_line:-0}" '$1 > lo {print $1; exit}')"
```

The `grep -v '^\s*#'` filter is **non-functional** here.  `grep -n` output
lines have the format `<linenum>:<content>` (e.g. `282:      _manifest_tmp=""`).
Because every line starts with a digit, the pattern `^\s*#` never matches and
no lines are filtered.  A comment line like:

```
# _manifest_tmp=""
```

would produce `grep -n` output `100:# _manifest_tmp=""`, which passes the
filter unchanged.  If such a comment appeared between `mkdir_line` and the
real reset, the awk step would select the comment's line number as
`reset_line`, making the ordering assertion vacuously or incorrectly true.

## Why it matters

The `grep -v` expresses an intent that is not fulfilled — code that looks like
a guard but provides none.  The awk numeric filter (`$1 > lo`) provides the
real logic today, and the current script happens to have no matching comment
lines, so tests still pass.  But the test is less robust than it appears: any
future refactor that places a comment containing `_manifest_tmp=""` after the
lock-acquire `mkdir` call (e.g. an inline explainer) would corrupt the
ordering proof without the test detecting it.

## Recommendation

Fix the filter so it operates on `grep -n` formatted output:

```bash
reset_line="$(grep -n '_manifest_tmp=""' "$script" \
  | grep -vE '^[0-9]+:[[:space:]]*#' \
  | awk -F: -v lo="${mkdir_line:-0}" '$1 > lo {print $1; exit}')"
```

Alternatively, drop the filter entirely and rely solely on the awk numeric
guard — that is the actual robustness mechanism.

## ID-hygiene grep note

No QRSPI-internal IDs (`[GRDFTQ]-?[0-9]+`) or bare external tracker refs
found in the diff.  The "T11" token removed from the bats comment in this
round was the right call; the new text is clean.
