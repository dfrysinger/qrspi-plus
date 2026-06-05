---
finding_id: F02
reviewer: silent-failure-claude
task: 33
round: 1
severity: medium
change_type: correctness
file: agents/qrspi-plan-reviewer.md
lines: 109
category: missing-error-path
---

# No empty-diff / no-op guard → trivial pass grants the exemption

## What

The structural-lint is described as running "against the proposed diff" (reviewer Step 3, line 109) and "on the proposed diff" (`skills/plan/SKILL.md` line 105). But:

- Plan-spec review happens **before code is written** for the task — the worktree at review time may not contain the migration diff at all.
- Even at code-review time, a reviewer running the lint from "the repository root" with no clear referent for "the proposed diff" may execute it against the current tree (clean, post-merge, or empty branch).
- A typical lint such as `! git diff <ref> | grep -E '^[+-]' | grep -vE '<allowed-pattern>' | grep -q .` returns success (exit 0) on an **empty diff** because nothing matches — vacuously true.

The contract has no requirement that the lint assert at least N files were modified or that the migration pattern actually appears in the diff. A vacuous pass therefore grants the LOC/file-count exemption.

## Why this is a silent failure

The exemption is granted on a lint that *did not actually verify a migration occurred*. The mandatory-trio shield collapses to "any author who writes a lint that passes vacuously gets ungated file count and no LOC ceiling." Adversarial authors aside, this also misfires under benign conditions: if a reviewer re-runs the lint after the migration branch is rebased/merged onto the ref it diffs against, the diff is empty, lint passes, exemption is silently re-granted on a now-non-existent migration.

## Where

- `agents/qrspi-plan-reviewer.md` § Schema-migration exception review, Step 3 (line 109): "Run the validated command from the repository root against the proposed diff." The referent of "the proposed diff" is not specified (working tree? `git diff <base-branch>`? a patch file?), and there is no requirement that the lint be falsifiable on the empty case.
- `skills/plan/SKILL.md` lines 100–101: `sizing_rationale:` example mentions "from all 41 agent frontmatter files" but no contract requires the lint itself to assert the file count or pattern presence.

## Suggested fix

Add a positive-evidence requirement to the lint contract in `skills/plan/SKILL.md`:

> The lint MUST be **non-vacuous**: it MUST assert both (a) the migration pattern is present in at least the number of files declared in `Target files:` (or sizing_rationale), AND (b) no other diff content exists. A lint that exits 0 on an empty diff is malformed.

Mirror in the reviewer rubric a Step 2.5 / Step 3 sub-check: "Run the lint against an empty diff (e.g., `HEAD..HEAD`); if it exits 0, the lint is vacuous — emit a malformed-lint finding." Also pin "the proposed diff" to a concrete referent such as `git diff <base-branch>...HEAD -- <Target files>`.
