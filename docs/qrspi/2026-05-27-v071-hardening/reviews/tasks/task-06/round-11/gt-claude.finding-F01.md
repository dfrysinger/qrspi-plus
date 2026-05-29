---
finding: F01
severity: high
title: TE1 tests in test-host-detection.bats are fragile in CI — detect_host requires trusted gh binary but tests don't ensure one is present
round: 11
reviewer: gt-claude
---

## Finding

Two TE1 tests in `tests/unit/test-host-detection.bats` assert that `detect_host` emits `copilot-cli` when `COPILOT_CLI=1`, but neither test ensures a `gh` binary is present in a trusted prefix (`/usr/*`, `/opt/*`, `/Applications/*`). As hardened through R3/R5/R7/R9, `detect_host` requires **both** conditions (`COPILOT_CLI=1` AND `gh` resolved to a trusted prefix) to emit `copilot-cli`. Without trusted `gh`, it emits `claude-code` — causing these tests to FAIL in any CI environment where `gh` is absent or not under a trusted prefix.

## Affected tests

| Test name | Location (diff line) |
|-----------|---------------------|
| `[host-detect] detect_host emits copilot-cli to stdout when COPILOT_CLI=1` | `test-host-detection.bats`, diff ~712–723 |
| `[host-detect] detect_host exits 0 when COPILOT_CLI=1` | `test-host-detection.bats`, diff ~725–734 |

Both tests run:
```bash
run bash -c "
  export QRSPI_SOURCE_ONLY=1
  export COPILOT_CLI=1
  . \"$WRAPPER\"
  detect_host
"
[ "$status" -eq 0 ]
[ "$output" = "copilot-cli" ]   # ← FAILS when gh absent or not in trusted prefix
```

## Root cause

The spec's TE1 bullet (`detect_host emits 'copilot-cli' to stdout and exits 0 when COPILOT_CLI=1 is present in the environment`) was written before the R3/R5/R7/R9 security hardening added the binary-reachability and trusted-prefix checks. The test implements the original, pre-hardening TE1 semantics. The implementation now requires:

```bash
[[ "${COPILOT_CLI:-}" == "1" ]] && \
[[ -n "$_gh_path" ]] && \                         # R3: gh must be reachable
[[ "$_gh_path" == /usr/* || ... ]]                # R5/R7: gh must be in trusted prefix
```

The CI `BATS-under-bash:3.2` alpine job is the high-risk environment: the container image does not pre-install `gh`, so `command -v gh` returns empty, `_gh_path` is empty, and `detect_host` emits `claude-code` — the `[ "$output" = "copilot-cli" ]` assertion **fails**.

## Evidence of correct pattern

`tests/unit/test-codex-review-source-guard.bats` (diff ~512–557) handles exactly this precondition with a `skip` guard:
```bash
if [[ -z "$_trusted_gh" ]]; then
  skip "no gh binary found under /usr/*, /opt/*, or /Applications/* on this host — positive-path test skipped"
fi
```
The TE1 tests should apply the same guard or set up a symlink fixture that resolves to a trusted path.

## Traceability chain gap

- Spec criterion: task-06.md TE1 (plan.md Task 6, line 176)
- Goal: G6 (task-06.md `goal_ids: [G6]`; goals.md §G6)
- Test: `test-host-detection.bats` tests named above
- Implementation: `detect_host()` in `scripts/run-codex-review.sh`, diff lines 38–55

The chain is broken at the **test-to-implementation** link: the test asserts the pre-hardening behavior but the implementation enforces the post-hardening behavior. Any CI host without trusted `gh` will see failing tests, violating the CI-stays-green constraint in goals.md (line 14).

## Suggested fix

Add a skip guard matching the `test-codex-review-source-guard.bats` pattern to both TE1 tests — locate a trusted-prefix `gh` before asserting, skip with a diagnostic if absent. The `[r3-sec.F01]` test (which deliberately removes `gh` from PATH) already validates the negative path; the positive-path tests should be conditional on the host having a real trusted-prefix `gh`.
