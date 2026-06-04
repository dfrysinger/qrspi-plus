---
finding_id: R2-cq-F01
severity: low
change_type: clarity
referenced_files: [skills/using-qrspi/SKILL.md, skills/using-qrspi/SKILL.anchors.json]
---
title: Stale section heading after R2 cleanup — promises consumer-surface coverage that was removed
evidence:
  - skills/using-qrspi/SKILL.md line 717: "### Sweep-task and consumer-surface findings — backstop"
  - skills/using-qrspi/SKILL.anchors.json line 110: matching key "Sweep-task and consumer-surface findings — backstop"
  - body only covers sweep-task findings now
recommended_fix: Rename heading + anchor key to "Sweep-task findings — backstop"
