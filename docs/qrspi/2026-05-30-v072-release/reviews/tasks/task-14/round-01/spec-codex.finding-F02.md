---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [skills/plan/SKILL.md, skills/using-qrspi/SKILL.md]
---
title: Cross-task consumer-surface content was added despite Task 14 explicitly excluding it
evidence:
  - Task 14 "Out" excludes cross-task consumer-surface authoring/enforcement (owned by Task 15)
  - skills/plan/SKILL.md:654 introduces cross_task_consumers: composition guidance
  - skills/using-qrspi/SKILL.md:721 also adds consumer-surface behavior text
impact: Scope bleed into Task 15 surface; increases coupling and review churn risk.
recommended_fix: Remove consumer-surface additions from Task 14 changes.
