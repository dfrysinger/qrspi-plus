---
finding: F01
reviewer: cs-claude
round: 8
task: 1
severity: suggestion
change_type: clarity
file: scripts/run-third-party-llm.sh
lines: 226-237
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
advisory: true
---

# F01 — `_cc_safe_hname` computed unconditionally on every clean call (refactor opportunity)

`_cc_safe_hname` is always computed via `printf | tr` subshell even when `_cc_count == "0"` (clean input). The sanitized name is only consumed on error paths.

## Suggested restructure
```bash
_cc_count=$(printf '%s' "$_cc_hname$_cc_hval" | LC_ALL=C tr -d '\040-\176\200-\377' | wc -c | tr -d ' \t')
[ "$_cc_count" = "0" ] && return 0
local _cc_safe_hname
_cc_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?') \
  || _cc_safe_hname="(field name unavailable — sanitisation pipeline failed)"
case "$_cc_count" in
  ''|*[!0-9]*) die "header-validation: failed to compute byte count for header '$_cc_safe_hname' on provider '${PROVIDER:-}' (pipeline/tool failure)" ;;
esac
die "header-validation: provider '${PROVIDER:-}' — control character in header/key field '$_cc_safe_hname'"
```

## Benefits
1. Removes subshell on clean common-case path
2. Linear control flow: compute → fast-exit → sanitize → die
3. Final `die` becomes unconditional, eliminates `if/then/fi` wrapper

**Disposition:** ADVISORY (cs findings are non-blocking per SKILL).
