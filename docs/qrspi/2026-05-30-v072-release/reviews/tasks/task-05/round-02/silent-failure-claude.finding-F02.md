---
title: "Test 6: `|| true` on inner grep-vE filter step — same anti-pattern as R1 cluster-4 fixes, left unresolved"
finding_id: R2-F02
severity: medium
change_type: correctness
file: tests/unit/test-change-type-partition.bats
line: 464
category: swallowed-error
round: 2
reviewer: silent-failure-claude
---

## Description

R2 correctly converted the outer `grep -rEn` in Test 6 to the new
`rc=0; cmd || rc=$?; [[ $rc -le 1 ]]` pattern (lines 458–462), which
distinguishes a genuine grep error (exit 2+) from a no-match result (exit 1).
However, the inner filter step that removes canonical-source lines from the
results was left with `|| true`:

```bash
# line 463-465
if [[ -n "$hits" ]]; then
  hits=$(printf '%s\n' "$hits" | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):' || true)
fi
```

`|| true` collapses **all** non-zero exit codes into silent success. For
`grep -v`, exit code 1 means "no lines survived the filter" (the normal case
when every hit is in a canonical source), but exit code 2+ means a real error:
broken regex, read error on stdin, unexpected signal. Both outcomes are
indistinguishable here.

### Silent-failure mode

If `grep -vE` exits 2 (e.g., due to an ERE syntax error or signal), `hits`
receives whatever partial output was produced before the failure — possibly an
empty string. The test then evaluates `[[ -z "$hits" ]]`, which passes. The
dup-check silently produces a **false-clean**: a real duplication in `skills/`
or `scripts/` would go undetected.

This is the identical error class as the `grep ... || true` sites addressed in
the R1 fix cycle (described in the dispatch as the "cluster-4 cohort" and "line
263" fixes). Those sites were converted to `rc=0; cmd || rc=$?; [[ $rc -le 1 ]]`
exactly because `|| true` masks errors that should surface. The same logic
applies here.

### Why `|| true` appears necessary but is not

The intuition for keeping `|| true` here is that `grep -v` normally exits 1
when all lines are filtered out (the expected "all hits in canonical sources"
case), and without `|| true` that exit-1 would propagate. However, with the
correct pattern, exit 1 is explicitly permitted:

```bash
local filter_rc=0
hits=$(printf '%s\n' "$hits" \
  | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):') \
  || filter_rc=$?
[[ $filter_rc -le 1 ]] \
  || { echo "grep -vE filter failed (exit $filter_rc) on dup-alt hits"; return 1; }
```

This correctly treats exit 0 (some hits survived — duplicates found) and exit 1
(no lines survived — all hits were in canonical sources, no duplicates) as
successful scan outcomes, while surfacing exit 2+ as a real error.

### Scope connection

Test 6's purpose is to pin the no-duplication constraint across the production
surface. A false-clean here means an engineer could introduce a second copy of
the 5-value enum alternation in `skills/` or `scripts/` without the test
catching it. The R2 comment at line 459 explicitly says:

> Treat exit 0 (matches) and 1 (no matches) as successful scans; exit 2+ means
> grep itself errored (e.g. unreadable file) — surface, don't mask.

That reasoning was applied to the outer scan but not to the inner filter,
leaving the filter with the same masking behaviour the comment argues against.

## Evidence

Line 464 of the current worktree HEAD (05049d0):

```
    hits=$(printf '%s\n' "$hits" | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):' || true)
```

Compare to the outer scan at lines 458–462, which correctly uses `|| rc=$?` and
`[[ $rc -le 1 ]]`:

```bash
hits=$(grep -rEn '...' skills/ scripts/ 2>/dev/null) || rc=$?
[[ $rc -le 1 ]] \
  || { echo "recursive grep failed (exit $rc) scanning skills/ scripts/"; return 1; }
```
