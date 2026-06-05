---
finding_id: F01
reviewer: silent-failure-claude
task: 33
round: 1
severity: medium
change_type: correctness
file: agents/qrspi-plan-reviewer.md
lines: 109
category: silent-fallback
---

# Step 3 lint-output interpretation is undefined → silent exemption grant

## What

Reviewer Step 3 says: *"If the command exits non-zero **or produces output indicating non-structural diff content is present**, emit a finding…"* The phrase "output indicating non-structural diff content" is undefined. Meanwhile the SKILL contract (`skills/plan/SKILL.md` line 101) explicitly permits two output styles for the lint:

> "must exit 0 (or output `0`) when the diff is mechanical-only, and exit non-zero (or output a non-zero count) when non-structural lines are present."

So a count-style lint such as `git diff --stat | grep -cv '^$'` may exit 0 while outputting a non-zero integer (e.g., `5`) on failure. The reviewer rubric does not tell the reviewer how to know which output convention the author used, nor does it require the spec to declare it.

## Why this is a silent failure

A reviewer that defaults to "exit-code only" interpretation will see exit 0 on a count-style failing lint, take the success branch in Step 4, and silently grant the LOC/file-count exemption. The mechanical-only claim was actually falsified, but no finding is emitted — exactly the load-bearing failure mode this contract is meant to prevent.

## Where

- `agents/qrspi-plan-reviewer.md` § Schema-migration exception review, Step 3 (line 109).
- Underlying contract permitting both output styles: `skills/plan/SKILL.md` line 101.

## Suggested fix

Pick one:

1. **Tighten the lint contract to exit-code only.** Drop "or output `0`" / "or output a non-zero count" from `skills/plan/SKILL.md` line 101. The lint MUST exit 0 iff mechanical-only. Reviewer Step 3 then reduces to checking `$?`.
2. **Or require an output-convention declaration.** Add a fourth mandatory field (or sub-field on `structural_lint:`) such as `structural_lint_pass: exit-zero | output-zero` so the reviewer has a defined interpretation rule, and emit a defect when it is absent.

Option 1 is simpler and matches the unix convention reviewers will default to anyway.
