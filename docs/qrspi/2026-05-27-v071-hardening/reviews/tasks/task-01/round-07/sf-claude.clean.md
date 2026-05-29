---
reviewer: sf-claude
round: 7
task: 1
commit: 9204cd2
finding_count: 0
prior_finding_closed: F04
---

# Round 7 — Silent Failure Review: CLEAN

## Prior finding: sf.F04 — CLOSED ✅

### Fix verification

**Fallback clause** (script line 227–228):
```bash
_cc_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?') \
  || _cc_safe_hname="(field name unavailable — sanitisation pipeline failed)"
```
- ✅ Fallback clause exists and is correctly positioned after the `\` line-continuation.
- ✅ When `tr` exits non-zero the `||` triggers unconditionally (both with and without `set -o
  pipefail` active, because `tr` is the last command in the pipeline and its exit code is the
  pipeline exit code regardless of `pipefail`).

**Die-message embedding** (script lines 233, 236):
- ✅ Both `die` calls reference `'$_cc_safe_hname'`.
- Happy path: `_cc_safe_hname` = sanitised field name from `tr`.
- Failure path: `_cc_safe_hname` = literal `(field name unavailable — sanitisation pipeline
  failed)` — operator retains an actionable message in all cases.

**Rename** (`_safe_hname` → `_cc_safe_hname`):
- ✅ Consistent with the `_cc_` prefix convention used by `_cc_hname`, `_cc_hval`, `_cc_count`.

---

### Test 1 — structural / script-hygiene (bats line 890)

Greps for `_cc_safe_hname=$(printf` and `|| _cc_safe_hname=` in the real script file.

- ✅ Both grep patterns match the production code as written.
- ✅ Would fail immediately if either the rename or the fallback clause were removed.

---

### Test 2 — behavioral (bats line 902)

Mechanism:
1. Extracts `_control_char_check` from the dispatcher via `_extract_ctrl_check_fn` (awk-based).
2. Creates `$stub_dir/tr` — a shim that `exit 1`s unconditionally, placed at the front of PATH.
3. Invokes the extracted function with a SOH (0x01) byte in the header value.
4. Asserts exit status 1 AND that the die output contains `(field name unavailable` or
   `sanitisation pipeline failed`.

**Does it fail when the fallback is removed?** Yes:
- Stubbed `tr` fails all three `tr` calls in the function body.
- `_cc_count` pipeline produces no output (stub tr prints nothing) → `_cc_count=""`.
- The `case ''|*[!0-9]*)` guard fires → `die` is called with `'$_cc_safe_hname'`.
- Without the fallback: `_cc_safe_hname=""` → die message has an empty field name → neither
  grep pattern is found → `_found` stays 0 → `[ "$_found" -eq 1 ]` fails the test. ✅
- With the fallback: die message contains the literal fallback string → `_found=1` → test
  passes. ✅

The `_found` detection logic (OR of two fragment greps) is correct and sound; a false negative
from a grep failure would cause the test to fail rather than to pass incorrectly.

---

## New silent-failure scan — R7 diff (~50 lines)

No new silent-failure patterns introduced:

| Surface | Assessment |
|---|---|
| `_cc_safe_hname` fallback assignment | No new unguarded path; the `\|\|` clause is the fix itself |
| Both `die` references updated to `_cc_safe_hname` | Mechanical rename; no logic change |
| Structural grep test | Non-zero status always checked; no silent pass on failure |
| Behavioral test `_found` logic | False negatives cause test failure, not silent pass |

No findings. This review is clean.
