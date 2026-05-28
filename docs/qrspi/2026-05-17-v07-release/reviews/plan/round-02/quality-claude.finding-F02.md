---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L661-L674
  - docs/qrspi/2026-05-17-v07-release/design.md:L444
artifact: plan
round: 2
reviewer: quality-claude
---

T20's description and target files omit the cross-skill audit directive that design.md G8 explicitly mandates as part of the G8 Implement task.

Design G8 states (design.md:L444): "Cross-skill audit (time-boxed). As part of G8's Implement task, grep every skill's SKILL.md for instruction patterns ('write … to <artifact>', 'verify …', 'surface …') and cross-check against its owns-defers.md. Mismatches that share Parallelize's pattern (skill mandates the work, owns-defers omits it) get fixed in the same task. Mismatches that need genuine scope debate get logged to future-goals.md."

T20's description (plan.md:L661-L674) only enumerates one target file (`skills/parallelize/owns-defers.md`) and describes only the Parallelize-specific OWNS addition and DEFERS clarification. There is no mention of the cross-skill audit. An implementer following T20 as written would complete the task by adding the OWNS line to `skills/parallelize/owns-defers.md` and never run the broader audit. If the audit finds actual mismatches in other skills, those fixes would have no owning task.

This is a correctness gap introduced by the plan: the design mandates a time-boxed audit with possible edits to other skill files as part of T20, but T20 does not instruct the implementer to perform that audit. The fix is to add a description bullet in T20 stating that after adding the Parallelize OWNS/DEFERS entries, the implementer grepping all `skills/*/SKILL.md` files for "write … to", "verify …", and "surface …" instruction patterns and cross-checks each against its `owns-defers.md`, logging genuine-scope-debate mismatches to `future-goals.md` and fixing same-pattern drift in the same task. No additional target files need to be pre-declared; the audit's findings determine which other files (if any) require edits. A note should state that target files beyond `skills/parallelize/owns-defers.md` are discoverable at Implement time via the audit.
