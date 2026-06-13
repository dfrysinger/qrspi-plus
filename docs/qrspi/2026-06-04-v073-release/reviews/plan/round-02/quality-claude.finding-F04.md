---
severity: medium
change_type: correctness
location: plan.md § Task Specs — T02 (lines 183–198), T03 (lines 200–217), T07 (lines 289–299), T09 (lines 320–330), T15 (lines 428–438), T16 (lines 440–451)
---

# F04 — Cross-task consumer surface contract applied inconsistently across consumer-surface-touching tasks

## What

`skills/plan/SKILL.md` § Cross-Task Consumer Surface lists triggers including "a named-declaration add" (a new function or named extension point) and "a file add" within `files_in_scope`. When triggered, the task spec MUST carry a `cross_task_consumers:` field naming the downstream consumers and their dispositions (or `none` plus a reproducible search command).

The plan applies this contract on some consumer-surface-touching tasks but omits it on others, with no visible rationale for the asymmetry:

| Task | Consumer-surface trigger | `cross_task_consumers:` field present? |
|---|---|---|
| T01 (create `scripts/upstream-paths.sh`) | File add + extension point | ✓ |
| T04a (add high-level entry mode to `dispatch-agent.sh`) | New CLI flag set + named-declaration add | ✓ |
| T19 (create `orchestration-boundary-check.sh`) | File add + CLI extension point | ✓ |
| T25 (create `validate-stage-commit-parents.sh`) | File add | ✓ |
| T28 (create `VERSION`, modify build script) | File add + schema change | ✓ |
| T31 (create six `_shared/*.md` snippets) | File add × 6, anchor extension points | ✓ |
| T05 (sweep + create structural-lint script) | File add (`scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh`) | ✓ |
| T02 (create `scripts/design-absorption-markers.sh`) | File add — consumed by T03, T15, T16, T17, T18 | ✗ |
| T03 (create `scripts/review-prep.sh`) | File add — consumed by T04a | ✗ |
| T07 (insert R8 rule in `prompt-design-rules.md`) | Named-anchor add (`### R8 — …`) + finding-type gate citation change — consumed by T08, T32, T33, T34, T35, T36 | ✗ |
| T09 (append rubric clause to `qrspi-finding-verifier.md`) | Named-clause add consumed by T10 | ✗ |
| T15 (add pre-fanout anchor sentence to `plan/SKILL.md`) | Named-anchor add — consumed by T16, T17, T34 | ✗ |
| T16 (append G3 rubric clauses to two reviewer agents) | Named-clause add — consumed by T17 | ✗ |

The clearest gaps are T02 and T03: both create brand-new script files whose downstream consumers are enumerated explicitly in the dependency graph (T03 → T04a, T02 → T03/T15/T16/T17/T18). The contract trigger is mechanical here, and the field is present on every other script-add task in the plan. The omission cannot plausibly be claimed as "no consumer surface."

T07 is similarly load-bearing: the R8 anchor heading is the named extension point that every prose-trim task (T32–T36) and the T08 lint depend on for verbatim grep matches; the absence of `cross_task_consumers:` leaves that consumer surface undocumented in T07's own spec.

## Why it matters

The Cross-Task Consumer Surface contract exists so that each task body carries, in one place, the list of paired-edit obligations any consumer task picks up. When the contract is applied on some tasks and silently omitted on others, downstream reviewers cannot tell whether absence-of-field means "no consumers" or "field was forgotten." The plan's dependency graph proves the consumers exist; the spec body just doesn't declare them.

The practical risk: the Implement-phase author for T02 / T03 / T07 lacks a single-spec source of truth for the consumer-surface fanout (today the consumers are discoverable only by reading T03 / T15 / T16 / T17 / T18 / T08 / T32–T36 individually and back-mapping). That re-discovery cost is exactly what the contract is designed to eliminate.

## Suggested change

Add a `cross_task_consumers:` block to T02, T03, T07, T09, T15, and T16 (at minimum), each listing the consuming task(s) with the documented disposition vocabulary (`no change`, `pass-through`, `co-edit`, `break-and-fix-task`). If the author claims a task has no cross-task consumers despite a trigger firing, the field must be `none` with the contract-shaped search command — silent omission is not a documented escape hatch.

Also worth removing in the Apply-fix: the self-referential entries currently present in T01, T04a, and T05 (each lists its own `Create`/`Modify` target under `cross_task_consumers:`). A task's own deliverable is not a cross-task consumer by definition; those entries dilute the field and confuse the reader about which paths are downstream-paired vs in-scope-of-the-task.
