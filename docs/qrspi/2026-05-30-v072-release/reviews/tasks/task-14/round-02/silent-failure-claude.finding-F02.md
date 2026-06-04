---
finding_id: R2-sf-F02
severity: high
change_type: correctness
referenced_files: [agents/qrspi-plan-reviewer.md]
---
title: Word-boundary example factually wrong — "removal matches remove" implies stem matching
evidence:
  - line 50: "Word-boundary means `removal` matches `remove` (the keyword is a prefix at a word boundary)"
  - remove[r,e,m,o,v,e] vs removal[r,e,m,o,v,a,l] — diverge at position 5, NOT a prefix
  - standard \bremove or \bremove\b will NOT match `removal`
  - example forces ambiguity: implementer chooses stem matching (\bremov*) and over-matches "removal", "removable", "remover"
recommended_fix: Replace example with words that ARE valid \bremove(\b|\w) matches — e.g., "Removed matches remove (start-of-word, case-insensitive)" or "removes matches remove (keyword is a prefix at a word boundary)". The key word "removes" IS a prefix-extension of "remove".
