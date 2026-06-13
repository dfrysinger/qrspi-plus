---
status: approved
task: 20
phase: 1
pipeline: full
goal_ids: [G6]
task_type: lightweight
tier: medium
---

# Task 20a: Wrap Wave Dispatch git merge --no-ff with stage-commit parent validation in skills/implement/SKILL.md

- **Target files:** `skills/implement/SKILL.md` (Modify)
- **Dependencies:** T19c
- **LOC estimate:** ~40
- **Description:** `skills/implement/SKILL.md` § Wave Dispatch step 6 (the `git merge --no-ff` step) gains pre-merge `--capture` and post-merge `--validate` calls to `scripts/validate-stage-commit-parents.sh` wrapping the existing merge invocation. The wrap is the load-bearing seam: the `--capture` call records the expected parent SHA before the merge, the `--validate` call confirms the resulting merge commit's parent matches, and any mismatch halts the wave with a named diagnostic. R1 (anchor-phrase preservation for § Wave Dispatch), R2 (the validation-wrapper lines are self-contained — name the script and the diagnostic inline), R3 (the wrapper calls land immediately around the `git merge --no-ff` step, the load-bearing position), R7 (verbatim phrasing the design.md G6 § Solution validation seam expects), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Wave Dispatch; R2 — the validation-wrapper lines are self-contained, name the script and the named diagnostic inline; R3 — the `--capture` and `--validate` calls land immediately around the `git merge --no-ff` step; R7 — verbatim phrasing of the design.md G6 § Solution validation seam; R8 — prose-density tightening.
