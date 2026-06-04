---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-verified-file-shape.bats, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# Open-ended awk slice extraction — end-boundary drift produces false-pass

**Locations:**
- `tests/unit/test-verified-file-shape.bats` L157–161 (unit pin for defect-class rubric step)
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` L1993–1997 (AC2)

Pattern:
```awk
/^5\. \*\*Score\*\*/ { flag=1 }
flag && /^6\. \*\*Write `<sidecar_path>`\*\*/ { exit }
flag { print }
```

There is no guard that the END boundary was reached. If step 6's heading text drifts (renumbering, title rephrasing, backtick-quoting change), the `exit` rule never fires; `$slice` silently expands to the entire remainder of the file. Subsequent greps still match → test passes despite "BETWEEN steps 5 and 6" assertion being lost.

Field-ordering tests at L245/L255 use `[ -n "$block" ]` guards; this slice extraction has no analogous end-boundary guard.

**Recommended fix:** assert `$slice` is non-empty AND does NOT contain step 6's write heading (end boundary was reached before slice terminated naturally).
