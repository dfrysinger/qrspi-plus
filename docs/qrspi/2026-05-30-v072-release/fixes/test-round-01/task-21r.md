---
status: approved
task: 21
phase: 1
pipeline: quick
fix_type: test
---

# Test Fix 21r: Re-land Task 21 (G16 path-filter exfil guard) onto main

- **Files:**
  - `scripts/dispatch-agent.sh` (extend with `assert_path_under_repo_root` guard + use sites)
  - `scripts/lib/path-guard.sh` (NEW — shared helper)
  - `agents/qrspi-implementer.md` (add `## Orchestrator-Only Scripts (Bash Allowlist)` section)
  - `tests/unit/test-dispatch-agent.bats` (extend with G16 boundary-guard tests)
- **Dependencies:** none
- **LOC estimate:** ~360 (cherry-pick of the 3-file delta from `qrspi/v0.7.2-release/task-21` since merge-base `85a18f9`)
- **Description:**

  Acceptance test `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats` is failing (3 of 4) because Task 21's G16 work never landed on `qrspi/v0.7.2-release/main`. The commit `b4e3074 stage-after-W16: merge(task-21, task-26)` is mislabeled — its parents are `064bede` (stage-after-W4) and `5823302` (task-26 tip), so it merged `task-26` only. The full G16 implementation lives on the existing approved branch `qrspi/v0.7.2-release/task-21` (tip `843c951`).

  The clean delta to land on main (computed from `git diff 85a18f9..qrspi/v0.7.2-release/task-21` filtered to T21 target files) is:

  ```
  agents/qrspi-implementer.md |  38 ++++++++
  scripts/dispatch-agent.sh   | 216 +++++++++++++++++++++++++++++++++++---------
  scripts/lib/path-guard.sh   | 150 ++++++++++++++++++++++++++++++
  3 files changed, 360 insertions(+), 44 deletions(-)
  ```

  PLUS the corresponding extensions to `tests/unit/test-dispatch-agent.bats`.

  Re-land this delta on top of current `qrspi/v0.7.2-release/main` (`14700df`). Avoid merging task-21 wholesale — its branch is forked from a much earlier base and would reverse-merge older versions of files that newer tasks (T16-20, T24, T26-44) have evolved.

  **Recommended approach** (in this order, fail-loud on any conflict):

  1. `git checkout qrspi/v0.7.2-release/main` in a fresh worktree under `.worktrees/v0.7.2-release/task-21r/`.
  2. Generate a 3-file patch limited to T21 targets:
     `git diff 85a18f9..qrspi/v0.7.2-release/task-21 -- scripts/dispatch-agent.sh scripts/lib/path-guard.sh agents/qrspi-implementer.md > /tmp/t21.patch`
  3. `git apply --3way /tmp/t21.patch` (if it cleanly applies, great; if conflicts on dispatch-agent.sh because main has post-T21 changes from later tasks, hand-merge — preserve later-task changes AND add the G16 guard).
  4. Generate the test patch:
     `git diff 85a18f9..qrspi/v0.7.2-release/task-21 -- tests/unit/test-dispatch-agent.bats > /tmp/t21-test.patch` and apply the same way.
  5. Run the full bats suite. Must pass cleanly (target: 2188/2188 — the 2184 baseline + the 4 new acceptance tests).
  6. Run the 4 G16 acceptance tests specifically (`bats tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats`) — all 4 must pass.
  7. Commit as `[v072-test-r1] re-land T21 G16 path-filter exfil guard (lost at stage-after-W16 mis-merge)`.

- **Failing test(s):**
  - `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats::[G16 acceptance] --subject-code resolving outside REPO_ROOT exits non-zero with a stderr diagnostic (no silent fallback)`
  - `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats::[G16 acceptance] scripts/lib/path-guard.sh shared helper is present (design.md ## G16 lock)`
  - `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats::[G16 acceptance] agents/qrspi-implementer.md carries the Orchestrator-Only Scripts (Bash Allowlist) section`
- **Test expectations:**
  - All 4 tests in `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats` must pass.
  - All existing tests must still pass (baseline: 2184 tests, 0 failures before this fix's acceptance file was added).
  - `grep -n assert_path_under_repo_root scripts/dispatch-agent.sh scripts/lib/path-guard.sh` must show the function defined in path-guard.sh and called from dispatch-agent.sh at the four documented use-sites (agent file, `--subject-code`, `--companion`, `--diff-file`).
