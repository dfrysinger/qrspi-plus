---
finding_id: R6-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L670-L683
artifact: plan
round: 6
reviewer: silent-failure-codex
---

T03 silently treats "not a git working tree" as success with no output: description + tests require "emit no files and exit 0" when artifact-dir is not in git / no diff. "No diff today" and "diff generation could not run because repo context is broken" are collapsed into the same success shape.

Note: design.md § CD-2 edge cases contract this silent-on-no-input direction; deferred to Design-phase amendment per existing Author Note (silent-claude R2-F01).
