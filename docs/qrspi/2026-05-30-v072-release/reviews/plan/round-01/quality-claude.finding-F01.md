---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T25 "Blocks" field mislabels downstream consumers — disagrees with the actual Slice 1.5 task list

## What's wrong

T25 (the hand-authored G31 prompt-prose primitives pilot, around plan.md line 1548) declares:

> **Dependencies:** none. **Blocks:** T26 (Plan/Design `!cat` include sites), T27 (reviewer-protocol consumer), T28-T31 (remaining G31 consumers).

But the canonical Slice 1.5 task list earlier in the same plan (the "Task List by Slice" block) assigns those task numbers to entirely different goals:

- T26 — G31 prompt-prose include sites across Design, Plan, and reviewer agents ← the *only* downstream G31 consumer
- T27 — CD-2 evergreen-output-rule shared snippet (goals: G3/G4/G22/G27) — **not** a reviewer-protocol consumer, **not** a G31 consumer
- T28 — CD-3 multi-actor-flow-check (goals: G1/G30/G33) — **not** a G31 consumer
- T29 — G34 Design scope-reviewer alignment — **not** a G31 consumer
- T30 — G1 Design phase decision-completeness template — **not** a G31 consumer
- T31 — G33 Design skill interactive dialog clarity — **not** a G31 consumer

Cross-check from the other direction: of T27–T31, only T29 lacks a `Dependencies:` line citing T25, and none cite T25 as a dep — T27, T28, T33, T34, T36 all declare `Dependencies: none`; T29 declares `Dependencies: none`; T30 depends on T29; T31 depends on T30; T32 depends on T30 + T31. The "Blocks" assertion in T25 is unsupported in both directions.

This looks like stale numbering from an earlier draft where the G31 consumer cluster was packed densely after the primitives task. After Slice 1.5 absorbed CD-2 / CD-3 / G34 / G1 / G33 tasks in between, the pilot's hand-authored Blocks field was not updated.

## Why it matters

The Blocks declaration is the human-readable dependency-graph artifact reviewers and Implement orchestration scan to plan task-merge order. A wrong Blocks list:

- misroutes attention if a reviewer audits "every consumer of T25's prompt-prose primitives" against T27–T31, when only T26 is a real consumer;
- contradicts the canonical task list above it, which is the kind of internal inconsistency the plan-spec contract is supposed to prevent;
- specifically mislabels T27 as a "reviewer-protocol consumer" — there is no reviewer-protocol consumer task for G31 primitives in this plan at all (T26's reviewer-agent consumer set is Design / Plan / lightweight-implementer / Design scope-reviewer / Plan test-coverage reviewer, none of which are the reviewer-protocol skill).

The dispatch prompt flagged T25 as the hand-authored pilot and asked me to be alert for anomalies without assuming the new shape is itself the problem. This is one such anomaly — the bullet-layer schema, not the new prose layer, carries the defect.

## Suggested fix

Replace the T25 Blocks line with the actually-supported set:

```
Dependencies: none. Blocks: T26 (G31 `!cat` include sites + skill-frontmatter preloads), T39 (G32 build pipeline's defensive copy of `skills/_shared/prompt-prose-detection.md`).
```

(T39 already declares `Dependencies: Task 25` and explains its dependence on the prompt-prose-detection.md defensive-copy site in the dependency-graph commentary at the top of the plan — that's the only other real downstream consumer.)
