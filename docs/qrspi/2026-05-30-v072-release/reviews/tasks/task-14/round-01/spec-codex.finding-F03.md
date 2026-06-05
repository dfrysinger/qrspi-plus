---
finding_id: R1-F03
severity: low
change_type: advisory
referenced_files: [skills/plan/SKILL.anchors.json, skills/using-qrspi/SKILL.anchors.json]
---
title: Non-target anchor files were modified
evidence:
  - Target files list does not include anchors JSON files
  - skills/plan/SKILL.anchors.json modified
  - skills/using-qrspi/SKILL.anchors.json modified
impact: Advisory only; may be legitimate maintenance for heading offsets.
recommended_fix: Either document as auxiliary updates or avoid.
