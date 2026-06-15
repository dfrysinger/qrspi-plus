---
reviewer: code-quality-claude
phase: test
round: 01
severity: major
change_type: defect
finding_id: F02
title: Four e2e .bats files create scratch tmpdirs INSIDE `$REPO_ROOT` instead of `$BATS_TEST_TMPDIR` — leaks pollute the live working tree on any abnormal exit
files:
  - tests/acceptance/v07-phase1-test-phase/test-g5-orchestration-boundary.bats
  - tests/acceptance/v07-phase1-test-phase/test-g6-stage-commit-parents.bats
  - tests/acceptance/v07-phase1-test-phase/test-integration-dispatch-chain.bats
  - tests/acceptance/v07-phase1-test-phase/test-regressions-integration-round01.bats
note: written to reviews/test/ root because reviews/test/round-01/ did not exist when dispatched; orchestrator should move into round-01/ subdir.
---

## What

All four files use the identical `setup()` pattern:

```bash
TMP_DIR="$(mktemp -d "$REPO_ROOT/.bats-tmp-XXXXX.XXXXXX")"
cd "$TMP_DIR"
git init -q .
...
```

with cleanup via `teardown() { cd "$REPO_ROOT"; rm -rf "$TMP_DIR"; }`. Concretely:

- `test-g5-orchestration-boundary.bats` line 30: `mktemp -d "$REPO_ROOT/.bats-tmp-g5e2e.XXXXXX"`
- `test-g6-stage-commit-parents.bats` line 25: `mktemp -d "$REPO_ROOT/.bats-tmp-g6e2e.XXXXXX"`
- `test-integration-dispatch-chain.bats` line 31: `mktemp -d "$REPO_ROOT/.bats-tmp-integ.XXXXXX"`
- `test-regressions-integration-round01.bats` line 37: `mktemp -d "$REPO_ROOT/.bats-tmp-regr.XXXXXX"`

## Why it matters

1. **Leak survives abnormal exit.** `teardown()` runs only when the test function returns normally (including via failed assertion). If the bats process is SIGKILLed, the OS reboots, or the runner times out mid-`git merge` (test-g6 does real merges), the `.bats-tmp-*` directory persists inside `$REPO_ROOT` — a real git working tree containing a nested `git init` repo. Subsequent local runs see dirty `git status`, and any reviewer / agent that greps or walks `$REPO_ROOT` (e.g. `find`, `grep -r`, the existing tests' own corpus sweeps) walks into a foreign repository. `$BATS_TEST_TMPDIR` (per-test) or `$BATS_FILE_TMPDIR` (per-file) is bats-managed, lives under the OS temp tree, and is removed by bats regardless of how the test exited.

2. **Cross-test contamination is reachable.** `test-g7-anchor-file-lookup.bats` and `test-g9-footprint.bats` run `grep -rnE ... "$REPO_ROOT/skills"` — bounded, fine. But `test-g2-bats-id-hygiene.bats` runs `grep -rE ... tests/**/*.bats` against `$REPO_ROOT` (see F01). Today's `.bats-tmp-*` names don't land under `tests/`, so the immediate corpus sweep is safe — but the broader invariant "test scratch must not live inside the artifact under test" is the right one to hold. A future test that walks `$REPO_ROOT/.bats-tmp-*` (or a `find $REPO_ROOT -name '*.bats'`) silently fails to be hermetic.

3. **Parallel-file execution amplifies the risk.** bats's default file-parallelism (`--jobs`) is increasingly common in CI. Two files concurrently creating sibling `.bats-tmp-*` dirs in the same parent (`$REPO_ROOT`) is fine for collision (mktemp suffix), but each is racing the other's `cd "$REPO_ROOT"; rm -rf "$TMP_DIR"` teardown against grep/find sweeps from the third file's tests.

The §12 frame applies: the teardown is a defense against tmpdir leakage. The defense fails to function exactly in the failure modes that produce the leak (crash, SIGKILL, timeout) — i.e. the precondition for needing the defense is the precondition for the defense not running.

## Recommended fix

Switch all four files to `$BATS_TEST_TMPDIR` (bats 1.5+ guarantees this exists per `bats_require_minimum_version 1.5.0`, which all four already declare or transitively satisfy):

```bash
setup() {
  TMP_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  git init -q .
  ...
}
```

Drop the `teardown()` rm-rf entirely — bats removes `$BATS_TEST_TMPDIR` itself, even on crash. The `cd "$REPO_ROOT"` in teardown is also unnecessary once $PWD points into a tmpdir bats will clean.

## Verification

- After the fix, `bats <file> --kill-after 1ms` style abort (or `kill -9` mid-run) leaves no `.bats-tmp-*` residue under `$REPO_ROOT`.
- `find "$REPO_ROOT" -maxdepth 1 -name '.bats-tmp-*'` returns empty after a full suite run.
