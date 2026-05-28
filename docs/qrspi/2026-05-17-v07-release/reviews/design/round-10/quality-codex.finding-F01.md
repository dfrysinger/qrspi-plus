---
finding_id: R10-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L340-L368, docs/qrspi/2026-05-17-v07-release/design.md:L1097-L1101]
artifact: design
round: 10
reviewer: quality-codex
---

The G7 design says the implementer self-check is advisory: hits are reported, the implementer either removes the token or explicitly acknowledges it, and the commit still proceeds so the next reviewer can flag unacknowledged leaks. The cross-cutting test strategy later says the self-check "rejects added lines" containing internal IDs, which changes the mechanism from advisory/reporting to blocking/rejection. That contradiction will mislead Plan or Implement about whether to build a hard gate. Fix the cross-cutting test wording to match the accepted advisory behavior, for example: the self-check reports added-line hits in non-exempt files, requires removal or explicit DONE-report acknowledgment, and reviewer visibility covers unacknowledged hits.
