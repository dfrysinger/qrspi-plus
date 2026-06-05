---
finding_id: R5-CQ-CLAUDE-F03
reviewer: code-quality-claude
severity: low
change_type: test-quality
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
at_cap: false
escalate: false
---

# F03 — FIX-E test: EXIT-trap assertion passes vacuously when no EXIT-trap line is found

**Introduced by R5 FIX-E test.**

## Location

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — the
`[dispatch-manifest FIX-E]` test, specifically the final three lines of
the EXIT-trap check:

```bash
local exit_trap_line
exit_trap_line="$(grep -E "trap.*EXIT" "$script" | grep -v "trap -" | head -1)"
echo "$exit_trap_line" | grep -qvE "exit [0-9]" \
  || { echo "EXIT trap appears to include an exit call (EXIT trap must be pure rmdir): $exit_trap_line"; return 1; }
```

## Defect

`grep -qvE "exit [0-9]"` returns 0 when its input contains **no line
that matches** the pattern.  If `exit_trap_line` is empty (because no
line matched `trap.*EXIT` after filtering `trap -`), `echo ""` emits
one empty line, which does not match `exit [0-9]`, so `grep -qv`
returns 0 and the test passes silently.

Concretely: if the EXIT trap were accidentally deleted from the script
(leaving only the INT and TERM traps), this assertion would still pass.
The INT (`exit 130`) and TERM (`exit 143`) assertions above it would
correctly fail in that regression scenario, so the test suite as a
whole would catch the removal.  But the EXIT-trap assertion itself
provides no independent signal — it cannot distinguish "EXIT trap is
pure rmdir" from "EXIT trap does not exist".

## Self-consistent defense check

This is a defense assertion (it claims to verify the EXIT trap is
"pure rmdir").  If the EXIT trap is absent, the defense runs against an
empty string and routes to "no exit call found → OK", which is the
wrong answer.  The defense is not self-consistent against the condition
it purports to detect.

## Recommended fix

Add a non-empty guard before the `grep -qvE` assertion so that a
missing EXIT trap fails the test rather than silently passing:

```diff
 local exit_trap_line
 exit_trap_line="$(grep -E "trap.*EXIT" "$script" | grep -v "trap -" | head -1)"
+[ -n "$exit_trap_line" ] \
+  || { echo "EXIT trap not found in script (expected pure-rmdir EXIT trap)"; return 1; }
 echo "$exit_trap_line" | grep -qvE "exit [0-9]" \
   || { echo "EXIT trap appears to include an exit call (EXIT trap must be pure rmdir): $exit_trap_line"; return 1; }
```
