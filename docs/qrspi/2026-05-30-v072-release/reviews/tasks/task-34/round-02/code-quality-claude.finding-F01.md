---
finding: F01
reviewer: code-quality-claude
round: 2
severity: major
area: test-quality
---

# F01 — Six diagnostic-assertion tests are structurally vacuous (cannot fail)

## Location

`tests/unit/test-plan-post-approval-split.bats`, Theme D and Quick-fix N=1 audit-case tests:

| Test name | Lines (bats file) |
|-----------|-------------------|
| `Mismatch HALT: diagnostic contains required halt-cause text` | ~911–942 |
| `Missing-header HALT: diagnostic contains required migration-guide text` | ~944–965 |
| `Malformed-header HALT: diagnostic names malformed block-hash header` | ~967–991 |
| `Quick-fix N=1 path: mismatch halt emits named diagnostic and leaves file untouched` | ~1145–1180 |
| `Quick-fix N=1 path: missing block-hash header halts with pre-G5 migration diagnostic` | ~1183–1215 |
| `Quick-fix N=1 path: malformed block-hash header halts with named malformed diagnostic` | ~1218–1250 |

## Problem

All six tests share a fatal structural pattern: they assign the required diagnostic
text to a local `diagnostic` variable as a **hardcoded literal string** and then
grep *that same variable* for required phrases. The grep always succeeds because
the test author controls the string being searched. The tests prove only that the
test author correctly remembered the contract text — they do **not** verify that
any orchestrator implementation would actually produce the right diagnostic at
runtime.

Concrete example from the mismatch HALT test:

```bash
# Produce the required diagnostic (as the orchestrator would before halting).
diagnostic="task-01.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-01.md and re-run. To preserve the existing file, revert your plan.md edit."

# Assert all three required phrases from the contract are present.
echo "$diagnostic" | grep -qF "exists but its source block in plan.md has changed"
echo "$diagnostic" | grep -qF "delete tasks/task-01.md and re-run"
echo "$diagnostic" | grep -qF "revert your plan.md edit"
```

The three `grep -qF` calls on line 939–941 interrogate the `diagnostic` string the
test itself just created. They cannot fail. Deleting the whole test body and leaving
only the assertions would still pass because grep is operating on a constant. A
regression where the orchestrator emits the wrong diagnostic — or no diagnostic at
all — would go completely undetected.

This pattern repeats identically in all six tests across Theme D and the Quick-fix
N=1 diagnostic audit cases.

## What the tests should do instead

The contract under test is a **documentation contract** (the orchestrator is an
LLM that reads a skill doc). The correct approach for this test surface is:

1. **Doc-audit path (preferred):** grep the contract document directly for the
   required diagnostic text, the same way the existing `extract_and_grep` tests
   already verify other mandatory phrases. The mismatch diagnostic is already
   verified by the `HALT Diagnostic contains exact mismatch diagnostic text (anchor phrase)`
   test above — so the Theme D mismatch test is also redundant with it.

2. **If an executable path exists:** capture actual output from the orchestrator
   helper under test and assert against it.

The current Theme D tests serve no purpose that isn't already covered by the
earlier `extract_and_grep "$CONTRACT_DOC" H2 "HALT Diagnostic" ...` tests (which
correctly grep the real document). Theme D should either be replaced with
non-redundant doc-audit assertions, or removed.

## Impact

Six of the 12 new behavioral tests added in commit 4fa9e40 have zero detection
power. Any regression in the produced diagnostic text is silently invisible.
