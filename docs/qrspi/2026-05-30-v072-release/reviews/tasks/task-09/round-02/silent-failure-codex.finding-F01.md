---
finding_id: R2-F01
severity: medium
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1440
---

# AC5 swallows ALL dispatch exit codes with `|| true`

**Location:** AC5 (`[reviewer-model-audit AC5]`) at `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1440`.

**Defect:** `bash "$REPO_ROOT/scripts/run-codex-review.sh" ... >/dev/null 2>/dev/null || true` suppresses every non-zero exit from the dispatch script. The trailing `[ -f "$manifest" ]` check catches the "manifest never written" case, but the test cannot distinguish:
- Acceptable: codex launcher failed (no Codex in CI) — manifest was written first, launcher exits non-zero
- Unacceptable: dispatch script crashed in an unexpected path that happens to leave a stale manifest

A future regression that makes the script crash with an exit code after writing the manifest but before completing dispatch invariants would be silently masked.

**Suggested fix:** Capture the exit code, then assert that the only acceptable non-zero code is the documented launch-time failure (e.g., the script's exit code for "codex-companion-bg.sh launch failed"). Example:

```bash
local exit_code=0
bash "$REPO_ROOT/scripts/run-codex-review.sh" ... >/dev/null 2>/dev/null || exit_code=$?
# Accept exit 0 (dispatch fully succeeded) or the documented launch-failure code (CI without codex).
case "$exit_code" in
  0|<documented-launch-failure-code>) ;;
  *) echo "AC5 dispatch exited with unexpected code: $exit_code"; return 1 ;;
esac
```

If `run-codex-review.sh` does not yet have a stable exit-code contract for "launch failed vs. dispatch failed", document the acceptable codes inline in AC5 with a comment explaining the rationale.
