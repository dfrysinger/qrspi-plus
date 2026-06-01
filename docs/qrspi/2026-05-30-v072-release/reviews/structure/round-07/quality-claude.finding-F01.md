---
finding_id: R7-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:L100-L134
  - docs/qrspi/2026-05-30-v072-release/design.md:L2582-L2592
  - docs/qrspi/2026-05-30-v072-release/design.md:L2625
artifact: structure
---

# G31 Consumer #9 (`qrspi-plan-test-coverage-reviewer.md`) is missing from the File Map

The R6 fix delta correctly added Slice 1.5 rows for two previously-missing G31 consumers — `agents/qrspi-implementer-lightweight.md` (Consumer #4) at L132 and `agents/qrspi-plan-spec-reviewer.md` (Consumer #8) at L133. But G31's distribution table in design.md (L2625) names **nine** consumers, and Consumer #9 — `agents/qrspi-plan-test-coverage-reviewer.md` — still has no row anywhere in `structure.md`'s File Map.

Consumer #9 is distinctive: per design.md L2582-L2592 (Addition C) and L2625, it receives **Addition C ONLY (no wrapper SKILL preload)** — a verbatim inline rubric clause inserted at the TOP of the agent's review-procedure section telling it to "Silently skip lightweight task sections." This is a substantive behavioral edit, not a frontmatter-only preload. The design block explicitly justifies the standalone treatment (Q1 resolution: full reviewer block would teach it "sometimes passing means no RED tests" which compromises judgment on `task_type: code` tasks).

Because Addition C is a behavioral rubric addition, it is NOT covered by the Slice 1.4 sweep row at L93 (`agents/*.md` (sweep — all 41 files)), which is explicitly scoped to `tier:` frontmatter plus DISPATCH_FILE first-action with the note "Batch change; no behavioral logic." It is also not covered by any other File Map row (no row mentions `qrspi-plan-test-coverage-reviewer.md` anywhere in Slices 1.1–1.7).

This is the same omission class the R6 fix delta closed for Consumers #4 and #8 — the fix simply did not extend to Consumer #9. Without a row, Plan/Implement has no instruction to author Addition C, and the G31 design block's Q1 resolution silently goes unimplemented.

**Suggested fix.** Add one row to the Slice 1.5 table alongside the two R6-added rows at L132-L133:

```
| `agents/qrspi-plan-test-coverage-reviewer.md` | Modify | Add G31 Addition C rubric clause at the top of the review-procedure section: skip evaluation of `task_type: lightweight` tasks (no `prompt-prose-reviewer` preload per design Q1 resolution). | G31 |
```
