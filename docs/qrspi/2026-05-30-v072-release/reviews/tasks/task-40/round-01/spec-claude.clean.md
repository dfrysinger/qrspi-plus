# Spec Reviewer — Task 40, Round 1 — CLEAN

All Definition-of-Done items verified against the diff and worktree:

1. **Body-guard retrofit (vocab.bats)** — Each of the four previously
   unguarded `[[ "$body" != *...* ]]` negation assertions now has an
   earlier `[ -n "$body" ]` guard in the same `@test` block:
   - test-using-qrspi-vocab.bats:127 (model_routing fail-loud pin)
   - test-using-qrspi-vocab.bats:140 (model_routing anti-pattern absence)
   - test-using-qrspi-vocab.bats:155 (trusted_path fail-loud pin)
   - test-using-qrspi-vocab.bats:169 (trusted_path anti-pattern absence)
   Already-guarded R5-era pins (validators / missing-block, lines 185,
   195, 215, 225) remain intact as live positive controls.

2. **Lint file shape** — tests/lint/test-bats-body-assertion-guard.bats
   exists with two parallel `@test` rules in one corpus walk:
   - Discovery: `find $REPO_ROOT/tests -name "*.bats" ! -name
     "test-bats-body-assertion-guard.bats"` (self-exclusion ✓).
   - Block parsing: opener `/^@test /`, column-0 closer `/^\}/` while
     `in_block`, with `FNR == 1` per-file reset.
   - Diagnostics: `FILENAME:FNR: unguarded $body assertion: <line>` for
     every unguarded occurrence; `return 1` on any violation.

3. **G26/BW02 rule surface** — Separate `@test` in the same lint file,
   initial trigger `run --separate-stderr`, requires
   `bats_require_minimum_version` declaration earlier in the same file,
   diagnostic includes both the triggering feature name and `file:line`.
   File-level dedup (one violation reported per file via `flagged=1`) is
   interpretively defensible — one declaration fixes all occurrences —
   and is called out only as a minor wording note, not flagged.

4. **CI / blocking-path wiring** — `.github/workflows/ci.yml` was not
   modified. The pre-existing `bats --tap -r tests` step at ci.yml:117
   already discovers `tests/lint/`, satisfying the "only if current
   CI/test entrypoints do not already execute tests/lint/" target-files
   condition.

5. **Workflow-shape coverage** — test-ci-workflow-shape.bats gains three
   T40/G21 pins (lines 149–177): lint-file existence, recursive `bats -r
   tests` invocation grep, and a no-pre-commit-hook anti-assertion. Does
   not encroach on G32 build-sync.

6. **No pre-commit hook, no shellcheck rule** — verified by both the
   diff (no new hook scripts, no shellcheck rule edits) and the
   workflow-shape pin at line 167.

## Advisory: target-files deviation (non-blocking)

The diff touches `tests/unit/test-dispatch-sites.bats` (one-line addition
of `bats_require_minimum_version 1.5.0` at line 2), which is not in the
task's Target files list. Rationale is sound: that file uses `run
--separate-stderr` extensively (lines 307, 323, 337, 353, 369, 497, …),
so the newly added BW02 rule would fail against the existing corpus
without the declaration. This is a necessary auxiliary edit driven by
the new lint, not scope creep.

Recommendation: accept as-is. Optionally amend task-40.md retroactively
to mention BW02-driven backfill of pre-existing
`run --separate-stderr` users, but not required.

## TDD evidence

Not separately verified beyond the report's claim — task spec did not
mandate verify-fail evidence as a DoD item, and the lint design (RED
against unguarded vocab assertions, then guard, then GREEN) is the
natural shape of the change set.

No blocking findings. Other reviewers cleared to run.
