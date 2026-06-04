---
reviewer: spec-claude
task: 13
round: 3
verdict: clean
---

# Spec Review — Task 13 (G9), Round 3 — CLEAN

Re-review of round-2 fixes. All four confirmation items pass; no findings.

## 1. Malformed prior-anchor + empty prior-scope-set tests (R2-F01)

Both new bats tests correctly pin their target branches with diagnostic-substring assertions:

- **Malformed anchor** (test file diff L330–353): writes `not-a-sha\n` to `task/round-01-commit.txt`, runs round-2 task-branch invocation, asserts `status -ne 0` and greps the output for BOTH `'malformed'` and `'round-01-commit.txt'`. Exercises `round-prepare.sh` L194–203 (python3 regex `^[0-9a-f]{40}\n$` reject → `exit 1`, diagnostic `"round-prepare: malformed prior-round commit anchor at $PRIOR_ANCHOR_PATH ..."`). Substrings present in the emitted diagnostic. ✓
- **Empty scope-set** (test file diff L413–442): creates an empty `task/round-02-scope-set.txt` (`: >`), runs round-3 invocation with `QRSPI_SCOPE_TAGGER_ENABLED=true`, asserts `status -ne 0` and greps for BOTH `'empty'` and `'round-02-scope-set.txt'`. Exercises `round-prepare.sh` L215–218 (`[ ! -s "$PRIOR_SCOPE_PATH" ]` → `exit 1`, diagnostic `"round-prepare: empty prior-round scope-set at $PRIOR_SCOPE_PATH ..."`). Substrings present. ✓

Together with the pre-existing missing-anchor (L308) and missing-scope-set (L385) tests, all four loud-failure branches of task-13.md L49 are now covered.

## 2. SKILL.md ordering prose (R2-F02)

- L1189 (between-rounds checklist step 4) now reads checks → **assert prior-round artifacts exist/well-formed** → **on exit 0 write** `round-NN+1-commit.txt` (assert-then-write).
- L1205 states both SHA checks and the Step 10 prior-artifact presence assertions "fire before the anchor write," so exit 11/12/1 leave no `round-NN-commit.txt` on disk.
- These no longer contradict each other, and both match the post-Fix-A code: Step 1 SHA checks (script L157–171), Step 10 assertions (L186–219), deferred anchor write (L228–237). ✓

## 3. Original G9 DoD / Test-Expectation coverage retained

Cumulative diff (test file L181–461) retains every prior item: happy-path anchor write with single trailing LF, `round-NN.diff` G4 inheritance, exit 10 (missing `--implementer-commit`), exit 11 (HEAD mismatch), exit 12 round-1 (`task base commit` diagnostic, NOT `prior round anchor`), exit 12 later-round (prior-anchor equality), missing prior anchor, fail-closed no-stray-anchor invariant, missing/empty scope-set, scripts/ Task-tool dispatch guard, and the five SKILL.md checklist grep audits (heading, scope-tagger dispatch, `commit_sha:` extraction, `dispatch-agent.sh --implementer-commit`, exit-code branches 0/10/11/12, and the zero-`rev-parse HEAD` lint on the Per-Task Convergence Narrowing section). ✓

## 4. No scope creep

Round-3 cumulative diff touches only the three Target files: `scripts/round-prepare.sh`, `skills/implement/SKILL.md`, `tests/unit/test-scope-tagger-dispatch.bats`. No out-of-scope files, no extra features. ✓

Gate: PASS.
