---
finding_id: R2-F05
severity: medium
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
  - skills/reviewer-protocol/SKILL.md
---

## G27 acceptance vs deliverables internal inconsistency — `reviewer-protocol/SKILL.md` Expected-Reviewer Matrix is an unenumerated `codex_reviews:` consumer site

**Location:** `design.md` L2222 (G27 § Acceptance criteria) and the G27 deliverables block

**Problem.** G27 acceptance criterion at L2222 states:

> "the legacy `codex_reviews:` name is **fully deleted from all skill prose and templates**; Config Validation Procedure treats a stray `codex_reviews:` as an unknown-field hard error per D1 (with the rename-naming error message)."

This is a strong, all-or-nothing acceptance condition. However, G27's deliverables enumerate only **two** consumer sites for deletion/update:
1. `skills/goals/SKILL.md` L120 (Claude-only inline glob — drift site 1)
2. `skills/using-qrspi/SKILL.md` L405 (Claude-only inline glob — drift site 2)

`skills/reviewer-protocol/SKILL.md` contains a **third consumer site**: the Expected-Reviewer Matrix (L23 in the current SKILL.md), whose column headers are `codex_reviews: true` and `codex_reviews: false`:

```
| Step | `codex_reviews: true` | `codex_reviews: false` |
```

This matrix is used by the apply-fix step to determine which reviewer tags to expect per round, keyed on the run's `config.md` field. After G27 ships and `codex_reviews:` → `second_reviewer:`, these column headers will be stale, silently disagreeing with the config field the orchestrator actually reads.

**Impact.** If Plan follows G27's deliverables literally, it writes tasks to update goals/SKILL.md and using-qrspi/SKILL.md, but not reviewer-protocol/SKILL.md. Post-implementation, the reviewer-protocol SKILL.md's matrix still says `codex_reviews:`, violating G27's own acceptance criterion ("fully deleted from all skill prose"). Operators referencing the Expected-Reviewer Matrix to understand dispatch behavior would see the wrong field name.

**Internal inconsistency.** G27's acceptance criterion makes a broader claim ("all skill prose") than its deliverables enumerate. The gap between the broad acceptance condition and the narrow deliverables list is the defect — Plan cannot satisfy the acceptance criterion by completing only the enumerated deliverables.

**Suggested fix.** Add `skills/reviewer-protocol/SKILL.md` — specifically, the Expected-Reviewer Matrix column headers — to G27's deliverables list. Update the headers from `codex_reviews: true/false` to `second_reviewer: true/false`. Alternatively, narrow the acceptance criterion wording to "fully deleted from the enumerated skill prose sites" if a complete sweep is out of G27's scope (with a follow-up issue opened for the remaining consumers).
