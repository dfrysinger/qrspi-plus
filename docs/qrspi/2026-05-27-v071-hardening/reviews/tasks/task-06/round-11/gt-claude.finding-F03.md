---
finding: F03
severity: minor
title: TE15 gap — check_codex_available claude-code success path not covered by stderr-clean assertion
round: 11
reviewer: gt-claude
---

## Finding

Task-06.md TE15 states: "Neither function writes to stderr under normal (non-error) operation." The test suite covers three of the four relevant paths but omits the `check_codex_available claude-code` **success** path:

| Path | Covered? | Test name |
|------|----------|-----------|
| `detect_host` copilot-cli | ✓ | `[host-detect] detect_host writes nothing to stderr on copilot-cli path` |
| `detect_host` claude-code | ✓ | `[host-detect] detect_host writes nothing to stderr on claude-code path` |
| `check_codex_available copilot-cli` | ✓ | `[codex-availability] check_codex_available copilot-cli writes nothing to stderr under normal operation` |
| `check_codex_available claude-code` (success, companion exists) | **✗ MISSING** | — |

The success path for `check_codex_available claude-code` (where the companion glob resolves to at least one file and the function returns exit 0) has no stderr-clean assertion.

## Implementation context

The implementation (diff lines 87–100) shows the claude-code success path emits no stderr:
```bash
for f in "${HOME}/.claude/plugins/..."; do
  if [[ -f "$f" ]]; then
    found=1
    break
  fi
done
if [[ "$found" -eq 1 ]]; then
  return 0      # ← no stderr output
else
  return 1
fi
```

There is no observable defect — the implementation is clearly correct. However, the TE15 criterion's "neither function" language covers both functions on all success paths, and the test suite incompletely covers it.

## Traceability chain gap

- Spec criterion: task-06.md TE15 (plan.md Task 6, line 190)
- Goal: G6 (task-06.md `goal_ids: [G6]`; goals.md §G6)
- Missing test: `check_codex_available claude-code` success-path stderr-clean assertion (analogous to the copilot-cli success-path test at diff line ~955–967)
- Implementation path: `check_codex_available` claude-code branch, `return 0` at diff line ~95

## Suggested fix

Add a test analogous to the copilot-cli stderr-clean test, exercising the TE9 scenario (companion glob resolves) and asserting `[ ! -s "$TMP_STDERR" ]`:

```bash
@test "[codex-availability] check_codex_available claude-code writes nothing to stderr when companion exists" {
  mkdir -p "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.55/scripts"
  printf '// stub\n' > "$MOCK_HOME/..."
  TMP_STDERR="$TMP_DIR/check-claude-stderr.txt"
  bash -c "
    export QRSPI_SOURCE_ONLY=1
    export HOME=\"$MOCK_HOME\"
    . \"$WRAPPER\"
    check_codex_available claude-code
  " >/dev/null 2>"$TMP_STDERR"
  func_status=$?
  [ "$func_status" -eq 0 ]
  [ ! -s "$TMP_STDERR" ]
}
```

This is a documentation/coverage gap, not a functional defect. Severity: minor.
