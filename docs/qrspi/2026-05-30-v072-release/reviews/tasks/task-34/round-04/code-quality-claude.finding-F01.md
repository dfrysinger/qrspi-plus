---
finding: F01
reviewer: code-quality-claude
round: 4
severity: moderate
area: dead-code / self-consistent-defense
---

# F01 — Dead else-branches in R4 behavioral decision-simulation tests

## Location

`tests/unit/test-plan-post-approval-split.bats`

| Test | if-condition | else-branch variable |
|------|-------------|---------------------|
| `[split] Mismatch HALT: changed plan.md block…` | line 725 | `decision=rewrite` (lines 729-738) |
| `[split] Missing block-hash header triggers pre-G5 migration HALT…` | line 772 | `decision=proceed` (lines 773-776) |
| `[split] Malformed block-hash header triggers named malformed…` | line 815 | `decision=proceed` (lines 816-818) |

## What the code does

R4 replaced the earlier mtime-based and `grep -c`-based checks with an if/else decision-simulation pattern. Each test:

1. Constructs a fixture that **guarantees** the if-condition is always true (e.g., `stored_hash` is `hash_v1`, `hash_v2` is a different block's hash → `stored_hash != hash_v2` is always true; missing-header file has no `# block-hash:` line by construction).
2. Assigns `decision=halt` (or `halt-missing-header` / `halt-malformed-header`) in the if-branch.
3. Assigns `decision=rewrite` / `decision=proceed` in the else-branch — **code that can never execute**.
4. Asserts `[ "$decision" = halt ]` — **always passes because the else-branch is unreachable**.

Example from the mismatch HALT test (lines 725–738):

```bash
if [ "$stored_hash" != "$hash_v2" ]; then
    decision=halt
    # Halt branch: no filesystem op. File must remain untouched.
    :
else
    decision=rewrite            # ← dead: never reached
    cat > "$FIXTURE_DIR/tasks/task-01.md" <<EOF
...
EOF
fi
[ "$decision" = halt ]          # ← always passes
```

The comment at lines 722–724 claims: *"A buggy implementation that took the rewrite branch on mismatch would clobber the existing file; the assertion below would then catch the regression."* This claim is incorrect: no external system is called, so no regression in an orchestrator can be detected. The test simulates both branches inline, but hard-wires which branch runs.

## Why it matters

- **Dead code** — the else-branches (`decision=rewrite`, `decision=proceed`) can never execute. Readers must trace the fixture setup to understand this, adding cognitive overhead with no compensating benefit.
- **Misleading comment** — the stated regression-detection rationale is false for a test that does not invoke any external implementation.
- **Unfalsifiable key assertion** — `[ "$decision" = halt ]` is a guaranteed pass. The non-vacuous work is done by the supporting assertions (`content_before = content_after`, `stored_hash != hash_v2`), not by the decision-simulation construct.

The `content_before = content_after` check *does* add value (it would catch an accidental external write to the fixture file), but that value is independent of the if/else simulation and does not require the else-branch.

## Remediation

Remove the else-branches and the `decision` variable entirely. Retain the fixture-state assertions that carry real value:

```bash
# Mismatch HALT — before refactored pattern:
[ "$stored_hash" != "$hash_v2" ]          # hashes genuinely differ
local content_after
content_after="$(cat "$FIXTURE_DIR/tasks/task-01.md")"
[ "$content_before" = "$content_after" ]  # file was not touched
```

Apply the same reduction to the missing-header and malformed-header tests. All three tests become shorter, clearer, and their assertions remain just as strong.
