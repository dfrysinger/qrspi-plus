---
finding_id: R3-F01
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-task-25-round02-fixes.bats
reviewer_tag: code-quality-claude
---

`test-task-25-round02-fixes.bats` lines 50 and 55 use a case-insensitive grep with a redundant case variant in the alternation:

```bash
run grep -iE '(do not|do NOT|NOT).*(apply|proceed|use)'
```

With `-i` (case-insensitive), `do not` and `do NOT` match the same set of strings.  The uppercase `do NOT` alternation adds no additional coverage and suggests the author was uncertain whether `-i` was active — which is mildly misleading to future editors and slightly harder to parse.

**Fix:** Remove the redundant `do NOT` alternation so each alternative is distinct:

```bash
run grep -iE '(do not|NOT).*(apply|proceed|use)'
```

This is non-blocking; the tests currently pass and verify the correct behaviour.
