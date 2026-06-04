---
finding: F03
reviewer: spec-claude
severity: fail
category: test-correctness
task: 12
round: 1
---

# F03 — `QRSPI_SCOPE_TAGGER_ENABLED=true` not exported before `run`; scope-set blocking tests silently pass for the wrong reason

## What the spec requires

**Test expectation** bullet 4:
> Exercise prior-round validation fixtures for missing / malformed `round-(NN-1)-commit.txt` and missing / empty required `round-(NN-1)-scope-set.txt`; verify reviewer dispatch is blocked on each failure.

The two scope-set tests must demonstrate that `round-prepare.sh` **exits non-zero** when the prior scope-set is missing or empty and the scope-tagger is enabled.

## What the tests do

`tests/unit/test-round-prepare.bats` lines 235–265 have two tests for scope-set blocking. Both use the pattern:

```bash
QRSPI_SCOPE_TAGGER_ENABLED=true \
run "$PREP" 3 "$TASK_DIR/round-03" \
    --task-branch main \
    --implementer-commit "$HEAD_SHA" \
    --worktree "$TEST_ROOT/repo" \
    --base-ref "$BASE_SHA"
[ "$status" -ne 0 ]
```

## Why the tests are broken

In bash, `VAR=val shell_function_call` does **not** export `VAR` to the environment of child processes invoked within the function. `run` is a bats shell function, not an external command. When `run` invokes `"$@"` (the external script `$PREP`), only **exported** variables are visible to the subprocess. `QRSPI_SCOPE_TAGGER_ENABLED` was set as a temporary shell variable scoped to the `run` function call — it was never `export`-ed — so the script sees `${QRSPI_SCOPE_TAGGER_ENABLED:-false}` = `"false"`.

### Actual execution path when env var is missing

With `SCOPE_TAGGER_ENABLED=false`, `round-prepare.sh` skips the scope-set presence check entirely (lines 182–192):

```bash
SCOPE_TAGGER_ENABLED="${QRSPI_SCOPE_TAGGER_ENABLED:-false}"
if [ "$ROUND_NUM" -ge 3 ] && [ "$SCOPE_TAGGER_ENABLED" = "true" ]; then
  …  # never entered
fi
```

The script then falls through to the convergence `decide_narrow()` function. There, `prev1` (round-02-scope-set.txt) is absent, so `[ ! -s "$prev1" ]` is true, `REASON="prior-round scope-set missing or empty — broaden"`, and the function returns 1 (broaden). The diff is emitted and the script exits **0**.

Both tests assert `[ "$status" -ne 0 ]` — this assertion **fails** (status is 0). Therefore the tests fail at runtime, or, if run in a bats version that propagates variables differently, may pass for the wrong reason (scope-set check never fired, blocking behavior not actually tested).

## Confirmed affected tests

| Line | Test name |
|---|---|
| 235 | `prior-round: missing scope-set on round 3 blocks dispatch (when narrowing-eligible)` |
| 251 | `prior-round: empty scope-set on round 3 blocks dispatch (when narrowing-eligible)` |

## Required fix

Export the variable before calling `run`, or use `env` to pass it inline to the external process:

```bash
# Option A — export-then-run
export QRSPI_SCOPE_TAGGER_ENABLED=true
run "$PREP" 3 "$TASK_DIR/round-03" …
unset QRSPI_SCOPE_TAGGER_ENABLED

# Option B — env wrapper
run env QRSPI_SCOPE_TAGGER_ENABLED=true "$PREP" 3 "$TASK_DIR/round-03" …
```

Either approach ensures the script sees the intended value, and the tests will actually exercise the blocking path they claim to test.
