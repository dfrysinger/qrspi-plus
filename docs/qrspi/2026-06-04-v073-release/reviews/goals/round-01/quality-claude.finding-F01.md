---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/goals.md:L54]
artifact: goals
round: 1
reviewer: quality-claude
---

G2's "What we know so far" opens with commitment language rather than candidate framing:

> "Decision locked during this Goals dialogue: **sweep all `[Tnn]` prefixes** from test names; do NOT bless them."

The quality check requires that solution mentions in "What we know so far" be framed as candidates Design will weigh, not commitments. "Decision locked" is the opposite: it forecloses Design's authority to evaluate the sweep direction and treats it as already resolved. Goals should characterize the problem and offer context for Design, not pre-commit the solution.

The underlying rationale is sound (T numbers are reused across phases, making them noise rather than traceability), but that rationale belongs in the framing of the candidate, not in a lock statement.

**Fix:** Replace the locked-decision framing with candidate language that carries the same rationale, e.g.:

> "Current best understanding (from v0.7.2 self-host analysis) is that sweeping all `[Tnn]` prefixes is the right direction and that blessing them is not viable — T numbers are reused each phase, so a `[T24]` from v0.7.2 collides with a future `[T24]`, making them noise, not traceability. Design should confirm this direction and weigh the prevention candidates below."

This keeps the rationale on record for Design without pre-empting the Design step's authority.
