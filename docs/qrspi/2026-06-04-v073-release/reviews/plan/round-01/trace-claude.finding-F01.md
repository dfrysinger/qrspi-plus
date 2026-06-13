---
finding_id: trace-claude-F01
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
---

# F01 — Duplicate `## Task Specs` sections create ambiguous per-task acceptance criteria; goal-trace from acceptance criterion to canonical spec is non-deterministic

## Summary

`plan.md` carries **two** `## Task Specs` H2 sections (line 152 and line 711). The first
section (lines 152–710) lists T01–T38 in a compact `### TNN: title` style with
condensed `Description` / `Test expectations` blocks. The second section (lines 711–2954)
re-lists the same task IDs T01–T38 in a longer YAML-frontmatter-tagged style with a
*different* (mostly longer, sometimes diverging) set of `Test expectations`. The
second-section bodies were appended by this round's diff in a single 2,806-line
addition (per `round-01.diff`); the compact bodies were not deleted in favor of the
detailed bodies.

This is a goal-traceability defect because every per-task acceptance criterion in
`plan.md` is the contract a test-writer subagent and the per-task reviewers read to
verify the task. With two non-byte-identical `Test expectations` blocks per task ID,
the forward trace from a goals.md problem statement → plan-authored acceptance
criterion → covering task becomes ambiguous: downstream consumers cannot determine
which set of Test Expectations is the canonical contract.

## Evidence

Tasks present in *both* sections with non-identical `Test expectations` blocks
(spot-checked sample, not exhaustive):

- **T05 (CD-2, G9)** — compact (lines 226–236) names R1–R3+R7+R8 rule application and
  asserts "zero `git diff > round-NN.diff` Bash redirect blocks remain"; detailed
  (lines 938–973) names R1, R2, R7 with a quantitative R1 sub-claim
  ("skill-body line count for § Review Round shrinks by ≥6 lines per file (total ≥48
  lines removed across the 8 files vs. v0.7.2)") plus a `dependent_tests:` block
  pinning `tests/unit/test-diff-file-emission.bats`. The compact version does not
  carry the ≥48-line claim or the dependent-tests block; the detailed version does
  not carry the explicit "zero redirect blocks" finding-shape.
- **T08 (CD-3)** — compact (lines 265–282) is a `### T08: …` H3 block; detailed
  (lines 1086–1136) is a `# Task 08: …` H1 block with a different YAML frontmatter
  shape (`status: approved`, `task: 8`, `phase: 1`, `pipeline: full`) that no other
  task uses, and reorganizes the `Test expectations` under an H2 `## Test
  expectations` heading rather than a `**Test expectations:**` bullet.
- **T11 (G2)** — compact (lines 312–328) and detailed (lines 1210–1227) carry
  different fixture sets (the detailed version names `tests/unit/test-hygiene-self-
  check.bats` as the carve-out site; the compact version names "T14 fixture, T10
  fixture"); the detailed version adds a `dependent_tests: none` sub-block that the
  compact version lacks.
- **T12 (G2)** — compact (lines 330–344) follows the standard `### TNN:` + bullet
  shape; detailed (lines 1235–1253) uses `# Task 12:` + `## Test expectations` H2,
  reorders the Test Expectations, and adds a "Dispatch ordering note (TDD)" inline
  paragraph that the compact version places as a single bullet line.
- **T13 (G2, G5)** — compact (lines 346–356) is a single Test-Expectations bullet
  citing R1/R3/R7/R8; detailed (lines 1263–1342) breaks Edit 1 / Edit 2 apart and
  enumerates four verification sub-findings (G2 anchor-phrase, G2 advisory-
  preservation, G5 mode-entry-presence, R1/R4/R7 sub-claims) that the compact
  version does not enumerate.
- **T17, T18, T19, T26, T27** — similar shape; compact and detailed bodies both
  present, non-byte-identical.

Task spec authorship-format inconsistencies in the detailed section (a corollary of
the same defect):

- Some tasks carry frontmatter with `task_id: T0N`; T08/T10/T17/T18 use `task: N`
  (no `T` prefix) or omit `task_id` entirely.
- T08 frontmatter carries `status: approved`; T10 carries `status: pending`; all
  other tasks omit `status:`. Inconsistent.
- Body heading levels diverge: `### TNN: title` (most tasks) vs `# Task NN: title`
  (T08, T10, T12, T14, T17, T18, T19, T26, T27). The H1 heading style on tasks
  inside a `## Task Specs` parent breaks the document's H2/H3 outline contract.

## Why this matters for traceability

Per the strip-from-goals contract, `plan.md` is the home for acceptance criteria —
per-task `## Test Expectations` blocks plus the per-phase Acceptance block. The
forward-trace step (goal → plan-authored acceptance criterion → covering task)
assumes each task ID owns **one** canonical `Test Expectations` block. With two
blocks per task, the matrix has two candidate criteria per goal → covering-task
edge, and downstream subagents (test-writers in particular) cannot deterministically
pick which block governs their TDD authoring. The per-task reviewer fan-out cannot
score against an ambiguous spec.

Specifically:
- **T05's compact body** is missing the quantitative "≥48 lines removed across the 8
  files" criterion that the detailed body carries — which itself is also weaker than
  design.md CD-2 Acceptance bullet 4's "≥ 80 lines shrunk vs. v0.7.2" (see F02).
  Without a single canonical T05 spec, even noticing the design-fidelity gap requires
  reading both bodies.
- **T13's detailed body** decomposes a G2-anchor + G2-advisory-preservation +
  G5-mode-entry finding shape that the compact body collapses into one rules-
  application bullet; the detailed shape is materially more verifiable, but the
  compact shape is what a reader scanning the partition table at line 23 will
  encounter first.

## Recommended remediation

Delete one of the two `## Task Specs` sections. The compact form (lines 152–710)
reads as the original Plan-step authored partition + condensed spec bodies; the
detailed form (lines 711–2954) reads as per-task fan-out subagent output that was
appended rather than substituted. Either choose one as canonical and delete the
other, or extract per-task spec bodies to `tasks/task-NN.md` files (as the plan's
own overview at line 17 contemplates: "Per-task spec bodies … are authored in
`tasks/task-NN.md` by per-task fan-out subagents in the next pass; this overview
commits the partition, ordering, and dependency shape").

Normalize frontmatter to one shape across all tasks (`task_id: TNN`, no `status:`
field at the per-task level — the plan-level `status:` frontmatter at line 2 owns
that). Normalize heading level to `### TNN: title` (H3 under the `## Task Specs`
H2). Normalize `## Test expectations` H2 inside task bodies back to the
`**Test expectations:**` bullet shape so it does not collide with the outline.
