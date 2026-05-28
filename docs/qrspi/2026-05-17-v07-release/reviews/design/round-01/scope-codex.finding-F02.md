---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L567-L574]
artifact: design
round: 1
reviewer: scope-codex
---

The G13 recommendation includes concrete shell implementation text and an exact replacement instruction for the lint fix. Design owns the chosen approach and rationale, but line-by-line logic and concrete code snippets are deferred to Plan and Implement. Fix by keeping the semantic algorithm at the design level, for example "derive the skill slug from the path segment after `skills/` and compare that slug to the exclusion list," and leave the exact `sed` expression and replacement operation for the downstream task spec or implementation.
