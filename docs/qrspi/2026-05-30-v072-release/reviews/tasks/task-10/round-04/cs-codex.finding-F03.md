---
finding_id: R4-F03
reviewer_tag: cs-codex
severity: low
change_type: clarity
referenced_files:
  - skills/using-qrspi/SKILL.md:995
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1973
---

# cs-codex R4 F03: Naming consistency — use `representative_score` everywhere

SKILL.md and AC5 comment use "representative `score`" generic wording while spec/template/tests pin `representative_score`. Use exact field name consistently.

CONVERGENT with cq-codex F03 (stale-comment finding). Disposition: folded into PI-V072-T10-005 disambiguation work.
