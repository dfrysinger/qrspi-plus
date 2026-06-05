---
reviewer: silent-failure-claude
round: 3
finding: F04
severity: low
category: weak-assertion / incorrect fixture value
file: tests/unit/test-plan-post-approval-split.bats
lines: 1192–1195
---

# F04 — Approval-state test uses a short 12-char hash but asserts with `[0-9a-f]+` (1+ chars), inconsistent with the contract's required 40-char SHA

## Test under examination

`[split] Complete re-run with zero dispatches proceeds to approval-state completion` (line 1140).

## The contract requirement

`tests/unit/test-plan-post-approval-split.bats` line 354–360 (in the "Successful approval" fixture at line 349) correctly uses a **40-character** SHA for `phase_start_commit` and asserts with `[0-9a-f]{40}`:

```bash
phase_start_commit: 0123456789abcdef0123456789abcdef01234567  # 40 chars
grep -E "^phase_start_commit: [0-9a-f]{40}$" "$FIXTURE_DIR/plan.md"   # strict assertion
```

The task spec (Definition of done) and `skills/plan/post-approval-split-contract.md` § Atomicity Contract both describe `phase_start_commit:` as a git SHA, which is 40 hex characters (SHA-1) or 64 (SHA-256), never an arbitrary short hex string.

## The weak fixture in the R2 test

At line 1192–1195 the "complete re-run" test writes and asserts:

```bash
sed -i.bak 's/phase_start_commit: null/phase_start_commit: abc123def456/' \
  "$FIXTURE_DIR/plan.md"                    # ← only 12 hex chars
grep -qF "status: approved"       "$FIXTURE_DIR/plan.md"   # strict string match ✓
grep -qE "phase_start_commit: [0-9a-f]+" "$FIXTURE_DIR/plan.md"  # ← matches 1+ chars
```

`[0-9a-f]+` matches ANY non-empty lowercase hex string, including single-character values like `a`. It would also pass if the substitution accidentally produced `phase_start_commit: x` (if the sed left a partial match). More importantly, `abc123def456` (12 chars) is visually SHA-like but does not represent a real git SHA, and the assertion would not catch a regression that wrote a truncated or malformed commit reference.

## Risk

This is a low-severity, consistency issue. The test is about the *presence* of the approval-state write (zero dispatches proceed to commit); the exact SHA length is secondary. However:

1. It creates an inconsistency with the existing "Successful approval" fixture (line 349) that correctly enforces `[0-9a-f]{40}`.
2. If an orchestrator implementation wrote a non-40-char value, this test would silently pass while the "Successful approval" fixture would fail — creating asymmetric coverage that could mislead a reviewer into thinking the complete-re-run path is tested as rigorously as the first-approval path.

## Remediation sketch

Use a 40-char fixture SHA and the strict assertion, consistent with the existing approved-state fixture:

```bash
sed -i.bak 's/phase_start_commit: null/phase_start_commit: 0123456789abcdef0123456789abcdef01234567/' \
  "$FIXTURE_DIR/plan.md"
grep -qE "phase_start_commit: [0-9a-f]{40}$" "$FIXTURE_DIR/plan.md"
```
