---
finding: F02
severity: high
title: TE14 dispatch-surface tests set COPILOT_CLI=1 without ensuring trusted gh — will fail in CI when gh absent
round: 11
reviewer: gt-claude
---

## Finding

Two TE14 tests in `tests/unit/test-host-detection.bats` assert the copilot-cli dispatch path by setting `COPILOT_CLI=1`, but they do not ensure that a `gh` binary is present under a trusted prefix (`/usr/*`, `/opt/*`, `/Applications/*`). As hardened through R3/R5/R7/R9, `detect_host` returns `claude-code` whenever trusted `gh` is absent — the copilot-cli dispatch path is never taken, `[transport: task-tool]` is never emitted, and the count assertion fails.

## Affected tests

| Test name | Diff lines |
|-----------|-----------|
| `[dispatch-surface] copilot-cli path emits [transport: task-tool] exactly once in stderr` | diff ~1024–1050 |
| `[dispatch-surface] copilot-cli path does not emit [transport: shell-pipeline] in stderr` | diff ~1052–1072 |

Both tests:
1. Write `codex_reviews: true` to config.md
2. Invoke the wrapper with `COPILOT_CLI=1`
3. Assert on the transport marker emitted to stderr

```bash
marker_count="$(grep -c '\[transport: task-tool\]' "$TMP_STDERR" 2>/dev/null || printf '0')"
[ "$marker_count" -eq 1 ]    # ← FAILS when detect_host returns claude-code instead
```

## Failure mode detail

Without trusted `gh` on the test host (e.g., the CI alpine bash-3.2 container):
- `detect_host` → `"claude-code"` (gh absent, R3 security check short-circuits)
- Dispatch takes the `else` branch → emits `[transport: shell-pipeline]`
- `[transport: task-tool]` count = 0 → **first test FAILS**
- `[transport: shell-pipeline]` IS present → **second test PASSES for the wrong reason** (the shell-pipeline path ran, not the copilot-cli path)

The test comment at diff line 1028–1030 acknowledges that the actual task-tool invocation may fail in a non-copilot environment, but it does not address the upstream `detect_host` returning the wrong value entirely.

## Contrast with F01 fix strategy

The same precondition problem exists as F01. `test-codex-review-source-guard.bats` (diff ~512–557) demonstrates the correct pattern for tests that require trusted `gh`:
```bash
if [[ -z "$_trusted_gh" ]]; then
  skip "no gh binary found under /usr/*, /opt/*, or /Applications/* on this host"
fi
```

For the dispatch-surface tests, the fixture setup in `setup()` would need to find a trusted `gh`, set PATH to include its directory, and skip the test if no trusted `gh` is available.

## Traceability chain gap

- Spec criterion: task-06.md TE14 (plan.md Task 6, line 189)
- Goal: G6 (task-06.md `goal_ids: [G6]`; goals.md §G6)
- Test: `test-host-detection.bats` dispatch-surface section, diff lines 1024–1072
- Implementation: `_detected_host="$(detect_host)"` then `if [[ "$_detected_host" == "copilot-cli" ]]` dispatch branch in `scripts/run-codex-review.sh`, diff lines 139 and 182–185

The chain is broken at the test-to-implementation link: the tests assume COPILOT_CLI=1 is sufficient to select the copilot-cli path, but the hardened implementation also requires trusted `gh`. CI alpine environments without `gh` will see these tests fail, violating the CI-stays-green constraint.

## Note on the second test (shell-pipeline absent)

The test `[dispatch-surface] copilot-cli path does not emit [transport: shell-pipeline] in stderr` uses a negation (`! grep`), so it accidentally passes in the failure scenario (because the shell-pipeline path **is** taken). This means the two TE14 tests are asymmetric in their CI failure profile: the count test fails loudly; the absence test passes silently for the wrong reason. Both are broken relative to their stated TE14 intent.
