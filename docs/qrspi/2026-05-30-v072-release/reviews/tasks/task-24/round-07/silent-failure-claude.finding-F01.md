---
finding_id: F01
reviewer: silent-failure-claude
round: 7
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
`dt="$(echo "$output" | grep '^DETECTION_TYPE=' | cut -d= -f2)"` — simple var=$(pipeline)
assignment does not propagate the pipeline's non-zero exit under set -e (bash exception).
If DETECTION_TYPE key were absent, dt becomes "" and the failure is surfaced at the enum
`[[ ... ]]` comparison ("value not in enum") rather than "key absent" — diagnostic-precision
gap. Test still fails on regression. Lines 291-293, 529-531. Fix: `|| { echo "DETECTION_TYPE
key absent"; return 1; }` after the assignment, or a `grep -q '^DETECTION_TYPE='` pre-assert.
