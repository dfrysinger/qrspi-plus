---
reviewer: codex
role: plan-goal-traceability-reviewer
round: 8
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md, docs/qrspi/2026-05-30-v072-release/goals.md, docs/qrspi/2026-05-30-v072-release/phasing.md]
---

# Finding F01 — G25/G29 have no forward task-to-test trace in plan

## Location

- `plan.md` L11 (overview describes them as absorbed/no standalone task)
- `plan.md` L50 (task list)
- `plan.md` L102 (dep graph narrative)

## What's wrong

The artifact claims 35 approved goals are decomposed into tasks, but
G25 and G29 are present as active goals upstream and in phasing while
no task in `plan.md` carries `Goal IDs: [G25]` or `Goal IDs: [G29]`.
That breaks the required forward trace from goal → task → task test
expectations.

## Evidence

- `goals.md` defines both goals (`goals.md:724` for G25, `goals.md:835`
  for G29).
- `phasing.md` still lists them in slice goal sets (`phasing.md:60`
  includes G29; `phasing.md:80` includes G25).
- `plan.md` has zero task `Goal IDs` lines containing G25/G29 (grep
  returns no matches), while explicitly stating they were
  "absorbed"/"no standalone task" (`plan.md:11`, `plan.md:50`,
  `plan.md:102`).

## Suggested fix

Either (a) formally remove/defer G25 and G29 from active goals/phasing
for this release, or (b) attach them to concrete task `Goal IDs` and
add explicit per-task Test Expectations proving those goal outcomes.

## Counter-context (round-02 adjudication)

This issue was investigated and resolved during round-02 of the plan
review. The plan currently documents the absorbed-by-CD-1 disposition
explicitly at L11 ("G25, absorbed by CD-1"), L50 (task-list gap),
and L102 (dep graph narrative). Design.md ## G25 / ## G29 sections
establish the consolidation rationale (both goals' surfaces folded
into CD-1's dispatch routing rewrite — no standalone task needed
because CD-1's tasks own the surface). The gtx-codex re-raise here
does not surface new evidence beyond the round-02 investigation;
the absorbed-disposition framing is the deliberate adjudicated outcome.
