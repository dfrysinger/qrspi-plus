---
finding_id: F01
reviewer_tag: code-quality-claude
round: 2
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:464
artifact: tests/unit/test-change-type-partition.bats
---

# `|| true` survives in test-6 inner `grep -v`, contradicting the fix's own stated rationale

The comment immediately above (lines 459–462) says:
> "Treat exit 0 (matches) and 1 (no matches) as successful scans; exit 2+ means grep itself errored (e.g. unreadable file) — surface, don't mask."

Yet line 464 still uses `|| true`, masking exit 2+ exactly as the comment forbids. Practical risk is near-zero (pipeline input + constant regex) but the fix's own reasoning demands consistency, and a reader will be confused.

CONVERGENT with silent-failure-codex.finding-F01.

Suggested fix:
```bash
if [[ -n "$hits" ]]; then
  rc=0
  hits=$(printf '%s\n' "$hits" | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):') || rc=$?
  [[ $rc -le 1 ]] || { echo "grep -v failed (exit $rc) filtering canonical sources"; return 1; }
fi
```
