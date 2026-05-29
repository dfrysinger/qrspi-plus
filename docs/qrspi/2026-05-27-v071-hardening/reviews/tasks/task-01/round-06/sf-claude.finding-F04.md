---
finding: F04
reviewer: sf-claude
round: 6
task: 1
severity: low
change_type: correctness
file: scripts/run-third-party-llm.sh
lines: 227
persistence_note: orchestrator-persisted (reviewer reported chat-only fallback; see issue #216)
---

# F04 — `_safe_hname` silently degrades diagnostic field name on `tr` pipeline failure

## What the code does

```bash
local _safe_hname
_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?')
```

## Failure mode

If `LC_ALL=C tr ...` fails (SIGPIPE, resource exhaustion, locale fault), `set -o pipefail` makes the command substitution exit non-zero. Because `set -e` is NOT active, the assignment `_safe_hname=$(...)` still completes — bash assigns whatever partial output `tr` produced before failing (typically empty).

The downstream die messages at lines 232 and 235 use `$_safe_hname`, which would now be empty:

```
run-third-party-llm: header-validation: provider 'my-prov' — control character in header/key field ''
```

## Impact

- Security outcome: UNAFFECTED. The security abort still fires; the control-char injection is still blocked.
- Diagnostic quality: DEGRADED silently. The operator loses the field name, making it harder to identify the offending header — exactly the precision the task spec required the API-key label (`api_key_env/${API_KEY_ENV}`) to preserve.

## Test coverage

No test stubs `tr` to fail. The ESC-sanitisation test (line 825) verifies the happy path only.

## Recommended fix

```bash
_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?') || _safe_hname="(field name unavailable — sanitisation pipeline failed)"
```

Or add a numeric/empty guard analogous to the `_cc_count` guard.
