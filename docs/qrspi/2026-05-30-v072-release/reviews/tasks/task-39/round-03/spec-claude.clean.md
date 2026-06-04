# Spec Reviewer (claude) — Task 39, Round 3 — CLEAN

R3 fix-cycle 2 verified against `tasks/task-39.md`:

1. **cq-F01 (dead `outRelFromRoot` block):** removed. Current
   `tools/build-plugin.mjs` references `relForward` (line 362) and contains
   no `outRelFromRoot` symbol. Clean.

2. **sec-F01 — `MAX_EXPAND_BYTES = 4 MiB`:** added at line 135 with rationale
   (intra-file fan-out N^D × |leaf| bound, primary materialized-size DoS
   defense). Enforced post-child-expand at lines 233–240 with file:line +
   chain in the fail-loud diagnostic. Within spec's "fail-loud" posture.

3. **sec-F01 — `MAX_INCLUDE_DEPTH` 16 → 8:** line 127, justification comment
   "deepest legitimate chain is well under 8; structural backstop alongside
   per-entry byte cap." Operator-confirmed: 25 build-gate tests green,
   build/ tree byte-identical, so legitimate skill chains unaffected.

Spec checks:

- Fail-loud non-zero with file:line + reason on both new caps (matches
  task-39 DoD).
- No new grammar, no `${CLAUDE_SKILL_DIR}` resolver, no tarball/auto-commit/
  pre-commit additions (Out-of-scope list respected).
- Header comment (lines 17–22) updated to mention `include depth-cap
  exceeded` consistently with the other D3 conditions — minimal and aligned.
- Target files: `tools/build-plugin.mjs` + `tests/unit/test-build-gate.bats`
  are both in task-39 Target files. No deviation flag.
- No scope creep, no extra features, no misinterpretation visible in R3
  surface.

Completeness, scope, interpretation, test coverage, TDD evidence, extras,
target-files: all clean.

Pass — gate open for downstream reviewers.
