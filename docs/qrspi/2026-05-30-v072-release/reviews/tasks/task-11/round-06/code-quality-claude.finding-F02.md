---
finding_id: F02
reviewer: code-quality-claude
model: claude-opus-4-5
round: 6
task: 11
severity: low
change_type: hygiene
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2635-2636
---

# code-quality-claude — task-11 round-06 — F02 (LOW)

## Redundant double separator line in test section header

**File:** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, lines 2635–2636

The transition from the old `R5 security and correctness fixes` section to the new
`Signal-safety and security hardening` section left a double horizontal-rule:

```bash
# ---------------------------------------------------------------------------  ← closing rule from old section (vestigial)
# ---------------------------------------------------------------------------  ← opening rule for new section
# Signal-safety and security hardening for manifest atomic-append
# ---------------------------------------------------------------------------
```

The standard three-line section header pattern used throughout the file is:

```bash
# ---------------------------------------------------------------------------
# Section Title
# ---------------------------------------------------------------------------
```

When the old section heading text was replaced in the diff (`-# R5 security and correctness
fixes (FIX-A through FIX-E)` → `+# ---------------------------------------------------------------------------\n+# Signal-safety…`),
the closing `---` of the old block was retained, giving two consecutive separator lines.

### Suggested fix

Remove the first (vestigial) separator so the block reads:

```bash
# ---------------------------------------------------------------------------
# Signal-safety and security hardening for manifest atomic-append
# ---------------------------------------------------------------------------
```
