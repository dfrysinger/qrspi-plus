---
finding_id: R8-F03
severity: medium
change_type: silent-failure
referenced_files: ["plan.md (T02 test expectations)"]
artifact: plan
round: 8
reviewer: silent-failure-codex
---
T02 ignores non-enumerated absorption marker shapes; marker typos/drift silently drop absorption mappings. Note: G3 lint test-design-absorption-marker-set.bats (T18) is designed exactly to catch this at the design.md level. The silent-ignore behavior on the T02 marker-extraction side is the correct contract because the lint is the loud channel.

