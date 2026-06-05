---
reviewer: spec-claude
task: 33
round: 3
status: clean
---

# Spec review — clean

Round 3 changes are confined to the schema-migration structural-lint
validation surface in `skills/plan/SKILL.md` and
`agents/qrspi-plan-reviewer.md` (matches `scope_hint`):

- Replaced prose path-shape validation with the ERE
  `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$`.
- Added explicit "script exists as a regular readable file" check between
  regex validation and execution, with its own diagnostic.
- Hardened execution invocation: `bash -- <validated-path>` with the path
  passed as a single argv element; prose forbids `bash -c` interpolation.
- Defect list extended from five to six conditions; SKILL summary updated
  in lockstep ("verifies all six conditions"); reviewer Step 4 grant
  criteria updated to require the new existence check.

All task-33 DoD items remain satisfied:

- Mandatory trio (`sizing_exception: schema-migration`,
  `sizing_rationale:`, `structural_lint:`) still required together
  (SKILL §"Mandatory trio"; reviewer Step 1).
- `structural_lint:` still defined as a bash check on the proposed diff,
  exit 0 = mechanical-only and non-empty (SKILL line 101).
- Reviewer still ties LOC/file-count exemption to successful lint
  (reviewer Step 4).
- Clear diagnostic for missing/incomplete `structural_lint` retained,
  augmented by the new missing-file diagnostic.
- Closed exception set unchanged (`schema-migration`, `CI scaffolding`,
  `reusable primitives`); no relaxation of ordinary task-size discipline.
- Field-name grep audits and prose audits from Test expectations all
  still pass.

No scope creep, no extra features, no out-of-scope edits.
