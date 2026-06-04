---
finding_id: R4-F01
reviewer: code-quality-claude
round: 4
severity: low
change_type: test-quality
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: open
---

# New e2e test leaks `round_dir` when it fails before the inline cleanup

**Where:** `tests/unit/test-dispatch-agent.bats` — new test body added in this diff, specifically lines starting at `round_dir="$(mktemp -d)"` through `rm -rf "$round_dir"`.

**Issue:**

The new test creates a scratch directory with `mktemp -d` and assigns it to `round_dir`:

```bash
round_dir="$(mktemp -d)"
```

Cleanup is performed inline immediately before the assertions:

```bash
rm -rf "$round_dir"
[ "$await_rc" -eq 0 ]
...
```

If the test fails at any point between those two lines — at the manifest presence check (`[ -f "$manifest" ]`), the absolute-path assertions (`[[ "$await_cmd_emitted" == /* ]]` / `[[ "$split_cmd_emitted" == /* ]]`), or the `await-round.sh` invocation — bats exits the test body immediately and the global `teardown()` runs. But `teardown()` only removes `$TMP_DIR`; `round_dir` is a separate `mktemp -d` and is not registered with it, so the directory (and any files written by dispatch-agent or await-round) leaks.

This e2e test has more failure points between `mktemp` and the cleanup than the shorter manifest-presence tests earlier in the file, so the leak probability is materially higher in CI under real environment variance.

**Why this is a quality problem:**

Per the test-quality criterion (cleanup discipline), tests must not leave artefacts on disk when they fail. In CI, repeated partial failures accumulate directories under `/tmp`. It also makes failure diagnosis harder because the leftover state from a failing run can interfere with manual re-runs.

**Context:**

The immediately preceding test (`task-20 end-to-end: --agents batched dispatch of third-party tag records non-empty job_id in manifest`) uses the same inline-cleanup pattern. Both tests share the same design; addressing one should address both.

**Suggested fix:**

Create `round_dir` inside `$TMP_DIR` so it inherits the global `teardown()` cleanup automatically:

```bash
round_dir="$(mktemp -d "$TMP_DIR/round-XXXXXX")"
```

Then the inline `rm -rf "$round_dir"` can be kept (or removed) — either way `teardown()` ensures the directory is gone if the test aborts mid-execution.
