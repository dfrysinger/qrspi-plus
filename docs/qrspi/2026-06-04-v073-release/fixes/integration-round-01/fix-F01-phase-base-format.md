---
status: approved
task: fix-F01
pipeline: full
task_type: tdd
references_finding: docs/qrspi/2026-06-04-v073-release/reviews/integration/round-01/integration-claude.finding-F01.md
references_tasks: [T19, T21, T22]
---

# Fix F01 — `phase-base.txt` bare-SHA contract alignment

## Context

Integration review round-01 found that `skills/integrate/SKILL.md` and `skills/test/SKILL.md` write `reviews/<phase>/phase-base.txt` as `integration_base_sha=<SHA>\n` (key=value form), but `scripts/orchestration-boundary-check.sh` (T19) reads it as a bare SHA (`tr -d '[:space:]'` then `^[0-9a-f]{7,64}$`). The OBC unit tests already pin the bare-SHA contract. Result: OBC always fires `sha-format-invalid:` under `## Dispatch defects` → autopilot halts unconditionally in both Integrate and Test phases.

The OBC contract is already pinned by `tests/unit/test-orchestration-boundary-check.bats:63-65, 230`. Move the SKILL prose to match.

## Target files

- `skills/integrate/SKILL.md` (M) — Phase Start section, change one `printf` line
- `skills/test/SKILL.md` (M) — Process Step 1, change one `printf` line
- `tests/lint/test-skill-phase-base-write-shape.bats` (C) — NEW lint that scrapes the `printf` line from each SKILL and asserts it emits bare SHA (no `=` or `:` separator, no `integration_base_sha` prefix)

## Test Expectations

The new lint test must:
1. Extract the `phase-base.txt` write incantation from `skills/integrate/SKILL.md` (Phase Start section)
2. Extract the same from `skills/test/SKILL.md` (Process Step 1)
3. For each: assert the literal `printf` template matches `printf '%s\n'` (bare-SHA emission), NOT `printf 'integration_base_sha=%s\n'`
4. Assert the file path ends in `/phase-base.txt`

Acceptance: after the fix lands, `bats --tap tests/lint/test-skill-phase-base-write-shape.bats` is GREEN, and `bats --tap tests/unit/test-orchestration-boundary-check.bats` remains GREEN (no regression to the OBC contract).

## Out of scope

- Broadening OBC to accept key=value form (suggested-resolution alternative — rejected because the SKILL prose change is smaller)
- Touching F02's wave-state sidecar (separate fix task)
