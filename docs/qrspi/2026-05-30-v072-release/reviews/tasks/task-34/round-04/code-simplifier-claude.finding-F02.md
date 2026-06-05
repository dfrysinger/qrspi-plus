---
finding: F02
reviewer: code-simplifier-claude
round: 4
severity: advisory
category: Verbose Patterns (vacuous decision-variable scaffolding)
---

# F02 — Decision-variable pattern in missing-header and malformed-header tests adds unreachable branches

## File and lines

`tests/unit/test-plan-post-approval-split.bats`

- `[split] Missing block-hash header triggers pre-G5 migration HALT diagnostic` (~lines 754–791)
- `[split] Malformed block-hash header triggers named malformed diagnostic` (~lines 797–828)

## Current pattern (missing-header test, representative)

```bash
local content_before decision content_after
content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
if grep -qE "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md"; then
  decision=proceed
  # Proceed branch: would normally re-audit the existing hash. Not
  # exercised here because the fixture deliberately lacks the header.
  :
else
  decision=halt-missing-header
  # Halt branch: emit diagnostic, do NOT touch the file.
  :
fi
[ "$decision" = halt-missing-header ]
content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
[ "$content_before" = "$content_after" ]
```

Both branches of the `if` contain only `:` (no-op). The fixture is constructed
**by design** without a `# block-hash:` line, so `grep -qE` always fails and
`decision` is always set to `halt-missing-header`. The assertion
`[ "$decision" = halt-missing-header ]` is therefore vacuously true and cannot
catch any regression. The `content_before = content_after` check is the
load-bearing assertion, but it too is vacuously true — no code path inside the
test writes to the file in either branch.

The same structure applies to the malformed-header test, where `hashline` is
checked with the strict 64-char hex regex, the fixture deliberately uses
`not-valid-hex`, the `else` branch always fires, and `decision=halt-malformed-header`
is always set.

## Proposed simplification

Replace the 10-line if/decision/assertion block in each test with the single
direct assertion it was actually checking, and keep the content-unchanged check
which is more expressive:

```bash
# Missing-header test: header is absent → verify no rewrite occurred.
local content_before
content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

# Assert header absence (the condition the orchestrator would halt on).
! grep -qE "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md"

# Assert file is byte-for-byte unchanged (no backfill).
[ "$(cat "$FIXTURE_DIR/tasks/task-01.md")" = "$content_before" ]
```

```bash
# Malformed-header test: header present but invalid → verify no rewrite occurred.
local content_before
content_before="$(cat "$FIXTURE_DIR/tasks/task-01.md")"

# Assert header is present but fails the strict pattern (the malformed case).
local hashline
hashline="$(grep "^# block-hash:" "$FIXTURE_DIR/tasks/task-01.md" | head -1)"
! echo "$hashline" | grep -qE "^# block-hash: [0-9a-f]{64}$"

# Assert file is byte-for-byte unchanged (no auto-correction).
[ "$(cat "$FIXTURE_DIR/tasks/task-01.md")" = "$content_before" ]
```

## Why this is safe

No assertion is weakened. The `! grep -qE` form is exactly what the R2 version
of the malformed-header test used and what the R1 version of the missing-header
test used (`has_hash -eq 0`). The `content_before = content_after` check is
preserved — and is actually more directly informative than the vacuously-true
`[ "$decision" = ... ]` it replaces.

The `proceed` branches (which only contained `:`) are dead code by construction
and can be removed without affecting any observable test outcome.

## Note on advisory status

Budget is exhausted; this finding is advisory. The decision-variable pattern
has documentary value as a comment showing what the orchestrator *would* do, and
the comments are reasonably informative. The simplification above retains the
same coverage at lower complexity, but the existing code is not wrong — just
noisier than necessary.
