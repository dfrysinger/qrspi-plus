---
finding_id: R1-F01
reviewer_tag: code-quality-claude
round: 1
task: 02
severity: low
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F01 — ID hygiene: G12 in script header comment

Line 2 contains `G12` (QRSPI goal ID) matching the grep-lint pattern outside `docs/qrspi/`. Fix: drop the parenthetical; orientation can reference CD-4 (not in pattern charset) only.
