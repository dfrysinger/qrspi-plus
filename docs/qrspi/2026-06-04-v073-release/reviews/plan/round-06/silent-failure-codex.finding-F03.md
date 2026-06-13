---
finding_id: R6-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L650-L657
  - docs/qrspi/2026-06-04-v073-release/plan.md:L658-L659
artifact: plan
round: 6
reviewer: silent-failure-codex
---

T02 silently ignores non-enumerated absorption markers: description/tests require non-enumerated marker-shaped text be ignored; fail-loud request was deferred. Author/reviewer marker typos or drift are dropped from the absorption map without error.

Note: prior-round defer-to-upstream Author Note (silent-failure-codex R4-F04) exists for this; re-flagged for completeness.
