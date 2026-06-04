---
finding_id: R1-F02
reviewer: silent-failure-claude
task: 27
round: 1
severity: medium
change_type: clarity
referenced_files:
  - skills/replan/SKILL.md
  - skills/_shared/evergreen-output-rule.md
---

# F02 — MEDIUM — Replan include is contradictory guidance for `feedback/*.md`

`skills/replan/SKILL.md` places the `!cat skills/_shared/evergreen-output-rule.md` include above an artifact list whose every entry (`reviews/replan/round-NN/...`, `feedback/replan-phase-*-round-*.md`) sits inside a path the snippet's exclusions parenthetical explicitly carves OUT of the rule. A future contributor reading the rendered SKILL.md may apply the rule to `feedback/*.md` content, stripping the dialogue-exhaust history those files are designed to hold — inverting the rule's intent.

**Recommended fix:** either (a) remove the `!cat` include from `skills/replan/SKILL.md` (replan's only artifact-class outputs sit inside the snippet's exclusion paths), OR (b) keep the include but add a one-line carve-out note immediately after it ("Note: replan's `feedback/` and `reviews/` outputs are explicitly excluded by the rule's own exclusions parenthetical above.").
