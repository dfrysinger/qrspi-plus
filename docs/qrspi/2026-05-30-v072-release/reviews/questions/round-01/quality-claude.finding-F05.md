---
finding_id: F05
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
---

# Missing Area — G18 (Plan-Phase Cross-Task Consumer Surface) Has No Corresponding Question

## Goal Not Covered

**G18** — Plan-phase under-scopes cross-task consumer surface: when a task changes a field, H4 anchor, or contract, the Plan skill does not require the author to enumerate downstream consumers of that contract. The v0.7.1 hardening run produced 9 documented instances (plus instance #10 from G27), all resulting in Integrate-phase catch costs.

G18 is explicitly `exploratory` and the goals direct Research to traverse `docs/qrspi/2026-05-27-v071-hardening/tasks/`, `fixes/integration-round-0{1..5}/`, and `reviews/integration/round-{01..06}/` to characterize the pattern.

## Why This Is a Gap

Q10 asks about `skills/plan/SKILL.md`'s test-expectations block for per-task specs (G2/G15). Q14 asks about `implement/SKILL.md`'s per-task review section (G9). Neither asks the complementary question: **what does `plan/SKILL.md` currently say (if anything) about enumerating downstream consumers when a task changes a shared contract?**

Without this research, Design for G18 cannot establish the baseline (is there zero language about consumer enumeration today, or is there partial language that needs to be extended?). The goals also ask Research to characterize the 9 concrete instances — finding files that document each missed surface — which requires directed investigation of the v0.7.1 hardening artifact directory that no current question points at.

## Suggested Addition

`[codebase]`:
> "Does `skills/plan/SKILL.md` currently include any requirement for a task author to enumerate downstream consumers of a contract, field, or H4 anchor being changed? Inspect the task-spec template and the plan reviewer agent for any 'consumer enumeration' or 'cross-task surface' language. Then traverse `docs/qrspi/2026-05-27-v071-hardening/tasks/task-{08,09,10}.md` and the corresponding `fixes/integration-round-0{1..5}/fix-task-*.md` files to characterize the under-scoped surfaces: which consumers were missed at Plan time and caught only at Integrate?"
