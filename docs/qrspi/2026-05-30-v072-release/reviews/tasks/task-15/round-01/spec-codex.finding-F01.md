---
finding_id: R1-F01
reviewer_tag: spec-codex
round: 1
severity: medium
change_type: scope
referenced_files: [skills/plan/SKILL.anchors.json]
adjudication: dismissed
---
**Claim:** anchors.json modified, outside the 3 declared target files (task-15.md:13,50).

**Adjudication: DISMISSED.** skills/plan/SKILL.anchors.json is a GENERATED derivative of skills/plan/SKILL.md (a declared modify target). The G4 narrow-read invariant REQUIRES regenerating the anchor manifest whenever a SKILL.md gains/loses an H3 section (via scripts/g4-section-anchor-refresh.sh), else test-section-anchor-narrow-read.bats and test-section-anchor-index-shape.bats break. spec-claude confirmed the change is purely line-offset shifts from the 40 inserted lines; G15 Sweep Task Contract content is byte-for-byte unchanged. This is a mandated co-change, not unauthorized scope creep. task-15.md:50 ("not require files outside those three") refers to authored content, not generated manifests downstream of an authored target.
