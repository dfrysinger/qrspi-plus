---
finding_id: R2-sf-F03
severity: medium
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---
title: "none + grep shape" pin not independent — example B satisfies regex regardless of prose shape
evidence:
  - lines 260-265: pin uses regex "grep -rn '.+' tests/"
  - example B's "grep -rn '^model:' tests/" (SKILL.md line 651) satisfies the regex independently
  - changing prose to "tests/unit/" would not fail the test
recommended_fix: Add a dedicated pin for the literal "<pattern>" placeholder shape used only in prose, e.g. extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" "grep -rn '<pattern>' tests/"
