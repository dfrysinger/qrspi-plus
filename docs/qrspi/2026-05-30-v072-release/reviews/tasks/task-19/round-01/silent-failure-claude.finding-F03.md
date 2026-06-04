---
finding_id: F03
reviewer_tag: silent-failure-claude
severity: medium
change_type: correctness
referenced_files:
  - scripts/_resolve-lib.sh:238
---

## `resolve_second_reviewer_vendor` — empty `$primary_vendor` silently bypasses same-vendor halt

### What the code does

`_resolve-lib.sh`'s `resolve_second_reviewer_vendor` is the single enforcement point
for the "primary ≠ second reviewer" invariant:

```bash
resolve_second_reviewer_vendor() {
  local host="$1" primary_vendor="$2"          # line 238 — $2 not validated
  local second_vendor
  second_vendor="$(lookup_default_second_reviewer "$host")"

  if [ "$second_vendor" = "none" ]; then
    # [second-reviewer-unavailable] halt — correct
    return 1
  fi

  if [ "$second_vendor" = "$primary_vendor" ]; then
    # [second-reviewer-same-vendor] halt — correct ONLY when $primary_vendor is non-empty
    return 1
  fi

  printf '%s\n' "$second_vendor"               # emits a dispatch line
  return 0
}
```

### The silent failure

When `$primary_vendor` is **empty** or **unset** (caller passed one argument instead
of two, or assigned an empty string after a failed prior resolution), the same-vendor
guard becomes:

```bash
[ "openai-codex" = "" ]  →  false
```

The guard silently passes and the function emits a dispatch line (`openai-codex`) with
exit 0. The "primary ≠ second reviewer" invariant is bypassed without any diagnostic.

### Concreteness

The most likely trigger is a future caller (dispatch-agent.sh, Task 20) that:

1. Resolves the primary vendor through a call chain where one step returns empty on
   failure instead of halting.
2. Passes that empty string as `$2` to `resolve_second_reviewer_vendor`.
3. Receives a second-reviewer vendor back (exit 0) and proceeds to dispatch — with
   no second-reviewer distinctness guarantee and no error signal.

If the same caller also runs with `set -u`, the `local primary_vendor="$2"` line
itself will abort with an **unstructured** bash nounset error rather than a tagged
`[second-reviewer-same-vendor]` or `[second-reviewer-unavailable]` diagnostic —
exactly the failure mode the loud-halt contract is designed to prevent.

### Fix direction

Validate that both arguments are non-empty before proceeding:

```bash
resolve_second_reviewer_vendor() {
  local host="$1" primary_vendor="${2:-}"
  if [ -z "$host" ] || [ -z "$primary_vendor" ]; then
    printf '[second-reviewer-unavailable] host=%s vendor=unknown — resolve_second_reviewer_vendor called with missing arguments\n' \
      "${host:-unknown}" >&2
    return 1
  fi
  …
}
```

Using `${2:-}` instead of `$2` also eliminates the `set -u` nounset hazard for callers
that run with `set -u` and pass fewer than two arguments.
