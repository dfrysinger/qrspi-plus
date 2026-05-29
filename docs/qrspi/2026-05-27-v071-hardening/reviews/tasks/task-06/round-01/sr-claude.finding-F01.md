---
finding: F01
reviewer: sr-claude
round: 1
task: 6
severity: minor
change_type: correctness
file: tests/unit/test-host-detection.bats
lines: [486, 530]
---

# TE15 Test Gap: `check_codex_available` claude-code success path not covered for stderr silence

## Spec requirement

Task-06.md TE15:

> "Neither function writes to stderr under normal (non-error) operation"

The spec says *both* functions must have their non-error paths verified to produce no stderr output.

## What the tests cover

The test file explicitly covers TE15 for three of the four normal-operation paths:

| Path                                | Test present |
|-------------------------------------|:------------:|
| `detect_host` → copilot-cli         | ✅ line 486   |
| `detect_host` → claude-code         | ✅ line 503   |
| `check_codex_available copilot-cli` | ✅ line 517   |
| `check_codex_available claude-code` (companion found, exit 0) | ❌ missing |

TE9 (line 423) verifies `check_codex_available claude-code` exits 0 when the companion glob resolves, but the `run bash -c` wrapper captures `$output` / `$status` only — stderr is *not* asserted. There is no separate test that redirects stderr to a temp file and asserts it is empty for this case.

## Why it matters

The implementation (`check_codex_available`'s `claude-code` branch, lines 122–135 of `scripts/run-codex-review.sh`) does not write to stderr in the success path, so the code is correct. However, the spec explicitly counts TE15 as a testable expectation, and the claude-code success path — the only remaining normal-operation case — is absent from the TE15 test coverage set.

## Recommended fix

Add a test in Section 3 (stderr-cleanliness block, around line 517 in the test file):

```bash
@test "[codex-availability] check_codex_available claude-code writes nothing to stderr when companion exists" {
  # TE15 — success path for claude-code must also be stderr-clean.
  mkdir -p "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.0/scripts"
  printf '// stub\n' \
    > "$MOCK_HOME/.claude/plugins/cache/openai-codex/codex/v1.0.0/scripts/codex-companion.mjs"
  TMP_STDERR="$TMP_DIR/check-claude-success-stderr.txt"
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
