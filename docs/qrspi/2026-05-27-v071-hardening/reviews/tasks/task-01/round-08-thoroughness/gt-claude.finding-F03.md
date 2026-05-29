---
finding: F03
reviewer: gt-claude
round: 8
task: 1
severity: low
change_type: correctness
file: tests/unit/test-run-third-party-llm.bats
lines: 560-588
persistence_note: orchestrator-persisted (reviewer chat-only fallback; see issue #216)
---

# F03 — NUL test missing negative assertion for "header name absent" carve-out

Spec bullet 12 has two sub-clauses:
1. Non-NUL: die message identifies provider AND header name (tested at line 684 with both `ctrl-test-prov` and `X-Named-Header`)
2. NUL carve-out: die message identifies provider AND failure class **but NOT the header name** (line 560)

NUL test asserts provider and "NUL" tokens present but does NOT assert absence of any specific header name. The spec's "but not the header name" clause is untested.

Implementation is correct (sh:621 NUL message contains no header name) but future refactor injecting a header-name token would pass silently.

**Required fix**: add negative assertion after positive checks:
```bash
run grep -F 'X-Nul-Test' <<< "$output"
[ "$status" -ne 0 ]
```
