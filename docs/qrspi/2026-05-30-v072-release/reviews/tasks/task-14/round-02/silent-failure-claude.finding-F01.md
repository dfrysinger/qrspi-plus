---
finding_id: R2-sf-F01
severity: medium
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
---
title: Keyword-list grep uses whole-file scan, can pass on out-of-list backtick mentions
evidence:
  - lines 289-296: for-loop uses plain grep on whole file
  - token `all` appears in word-boundary counter-example ("does NOT match `all`")
  - removing `all` from detection list would still pass the test via the counter-example mention
recommended_fix: Replace plain grep with extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" "\`$kw\`" — section-scoped
