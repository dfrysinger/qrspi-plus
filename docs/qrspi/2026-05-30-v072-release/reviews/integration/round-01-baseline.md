# Integration Round 01 — Baseline Test Results

**Merge state:** All 8 leaves merged into `qrspi/v0.7.2-release/main`
**HEAD after merges + anchor regen:** `8f2c0c0`

**Pre-integration baseline (`b17538e`):** 1440 ok / 0 fail
**Post-integration baseline (`8f2c0c0`):** 2136 ok / 47 fail

The 47 failures are net-new tests added by tasks that pin behavior
which drifts when merged with sibling tasks. They are real cross-task
integration regressions, not pre-existing failures.

## Failure Categorization

### Group A — script-rename drift (17 tests)
`scripts/run-codex-review.sh` and `scripts/run-third-party-llm.sh`
were renamed to `scripts/dispatch-agent.sh` and
`scripts/dispatch-companion.sh` (commit `5110abe`). Tests on later
task tips still reference the old names.

Affected tests: dispatch-manifest AC1–AC14, AC5, AC6; first-party
prompt write; manifest tmp; DISPATCHER check; failure-path emit;
EXIT/INT/TERM traps; mktemp failure path; manifest lock traps;
first-party prompt tmpfile; manifest lock-held block; _fp_tmp trap.

Files: `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`,
`tests/unit/test-dispatch-agent.bats`, `tests/unit/test-dispatch-sites.bats`.

### Group B — T7 dispatch surface drift (12 tests)
Tests pin specific using-qrspi SKILL.md prose about Codex detection.
Prose drifted across task waves.

Affected: T7 / TE1, TE3, TE4, TE5, TE6, TE8a, TE9a, TE10, TE11,
TE12, TE13, plus dispatch-surface mismatch warning.

### Group C — content drift (~18 tests)
- `[T24]` Grep regression: `<autopilot_mode>` literal absent from skills/
- `[T24]` Grep regression: 'Autopilot mode is currently active' missing
- `[T17]` repo-wide evergreen-markdown scan
- `[G21]` corpus: bats body assertion preceded by `[ -n "$body" ]`
- reviewer-protocol clean.md sentinel format
- `[T13]` scripts/ Task-tool subagent dispatch absent
- `[M51]` structure SKILL OWNS subsection
- design/structure SKILL.md OWNS / DEFERS H3 family-shape sub-blocks (×2)
- threshold rule: scope and intent kept regardless of score
- await: polls fast then backs off

## Recommendation

These failures map to ~4–6 integration-fix tasks (one per cluster).
Per QRSPI Integrate skill: dispatch integration + security-integration
reviewers, then route findings into fix-tasks. However, the failures
are deterministic test pins — direct fix dispatch may be more
efficient than reviewer fan-out for this round.

## Anchor Index Regen

`skills/plan/SKILL.anchors.json` was regenerated after merge (commit
`8f2c0c0`) to reflect the post-merge plan SKILL.md heading layout
(task-33 added new sections).
