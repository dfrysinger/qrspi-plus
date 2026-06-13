---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L36
  - docs/qrspi/2026-06-04-v073-release/plan.md:L68
  - docs/qrspi/2026-06-04-v073-release/plan.md:L385-L386
  - docs/qrspi/2026-06-04-v073-release/plan.md:L901-L911
artifact: plan
round: 6
reviewer: spec-claude
---

T39's table row (plan.md:L68) says T39 **creates** the structural-lint script, but T39's spec body (plan.md:L901-L911) says the script is pre-committed and T39 only creates the bats test. T11's table Deps column (plan.md:L36) shows `T09, T39` while T11's spec body Dependencies field (plan.md:L386) lists only `T09`. T11's spec body Target files (plan.md:L385) confirms the script is pre-committed, meaning T11 never needed T39 as a runtime dependency.

Root cause: T39 was introduced in round-05; the table row was written to say T39 creates the script (original intent), but the spec body was written to say the script is pre-committed and T39 only adds bats coverage. The table row was never updated to match.

Fix (Option A — matches spec body intent):
1. Update T39's table row (L68): retitle to "Add tests/unit/test-check-bats-id-hygiene-sweep.bats — bats coverage for the pre-committed structural-lint script" and update the one-sentence behavior accordingly.
2. Update T11's table Deps column (L36): change `T09, T39` to `T09`.
