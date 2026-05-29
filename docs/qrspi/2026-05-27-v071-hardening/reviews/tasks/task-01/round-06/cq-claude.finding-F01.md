---
finding: F01
reviewer: cq-claude
round: 6
task: 1
severity: low
change_type: naming-inconsistency
file: scripts/run-third-party-llm.sh
lines: 226-227
---

# F01 — `_safe_hname` breaks the `_cc_` local-variable prefix convention in `_control_char_check`

## What the code does

The fix introduces a new local variable `_safe_hname` in `_control_char_check`:

```bash
# run-third-party-llm.sh  lines 213-227
_control_char_check() {
  local _cc_hname="$1" _cc_hval="$2"
  local _cc_count
  ...
  local _safe_hname
  _safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?')
```

## Naming analysis

All four locals in this function follow a `_cc_` prefix:

| Variable | Prefix |
|---|---|
| `_cc_hname` | `_cc_` ✓ |
| `_cc_hval` | `_cc_` ✓ |
| `_cc_count` | `_cc_` ✓ |
| `_safe_hname` | `_safe_` ✗ |

The `_cc_` prefix appears to stand for "control-char [check]" and serves as a
function-local namespace guard to avoid colliding with caller-scope variables in
sourced scripts.  `_safe_hname` uses a different prefix schema (`_safe_`) and
breaks this convention.

## Why this matters

A reader scanning the function's `local` declarations sees three `_cc_`-prefixed
names and then a `_safe_`-prefixed name.  This creates a momentary ambiguity
about whether `_safe_hname` might be a global or whether it belongs to a
different scoping convention.  In a sourced-script context (where `local` is
load-bearing for collision avoidance) the inconsistency is mildly misleading.

## Recommended fix

Rename to `_cc_safe_hname` to stay inside the function's existing prefix
namespace:

```bash
  local _cc_safe_hname
  _cc_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?')
  case "$_cc_count" in
    ''|*[!0-9]*) die "header-validation: failed to compute byte count for header '$_cc_safe_hname' on provider '${PROVIDER:-}' (pipeline/tool failure)" ;;
  esac
  if [ "$_cc_count" -ne 0 ]; then
    die "header-validation: provider '${PROVIDER:-}' — control character in header/key field '$_cc_safe_hname'"
  fi
```

The same rename applies to the two occurrences in the `die` message arguments
at lines 232 and 235.
