---
finding_id: R4-F01
reviewer_tag: quality-codex
round: 4
artifact: plan.md
severity: high
change_type: correctness
referenced_files: plan.md (lines 26-27)
---

Phase-acceptance criterion #6 requires that "each of the 35 goal-backing parent issues closes when its backing commits land," but that is no longer true for this release after the locked design dispositions for absorbed/moot goals. In design.md, G25 (#242), G26 (#243), and G29 (#262) are explicitly closed at design lock with no standalone shipping task, so this plan gate encodes an impossible/incorrect closure condition for those goals. At PLAN altitude, acceptance gates must be executable and aligned with upstream locked dispositions; otherwise Test-phase release gating can fail or report false non-compliance even when implementation matches the approved design.
