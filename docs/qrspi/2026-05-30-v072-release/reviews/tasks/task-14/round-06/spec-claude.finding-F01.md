---
finding_id: R6-F01
reviewer_tag: spec-claude
round: 6
severity: high
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---

# F01: R6 dropped coverage of `none`-without-grep malformed variant

In tightening the malformed-variants test from broad alternation to section-scoped pin, R6 replaced `grep -E "[Mm]alformed|no paths|no .none."` with a single `extract_and_grep ... "no paths"`. This eliminates the only assertion covering the `none` without grep variant required by:

- T14 DoD line 44 ("malformed field variants: no paths, `none` without the grep command, ...")
- The Sweep-task detection rubric explicitly enumerates "Malformed — `none` without grep: dependent_tests: none is present but no grep command follows on the next line."

Test comment at lines 316-317 still claims the variant is covered but no assertion exists.

## Fix

Add one section-scoped pin matching the rubric prose, e.g.:
```bash
extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
  "none.*without.*grep|without.*grep|none.*no grep"
```
