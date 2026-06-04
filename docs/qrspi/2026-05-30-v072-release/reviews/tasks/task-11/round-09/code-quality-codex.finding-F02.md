---
reviewer_tag: code-quality-codex
round: 9
finding_id: R9-F02
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F02 — Test hermeticity: hard-coded `/tmp/foo bar/round-01` outside per-test TMP_DIR

## Finding

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1743,1766-1769` (AC12) uses:
```bash
local crafted_outdir='/tmp/foo bar/round-01'
```

This path is OUTSIDE the per-test `$TMP_DIR` scope. Two problems:
1. **Pre-existing state collision:** if `/tmp/foo bar/` exists from a prior failed run with manifest content, the "no manifest written" assertion at lines 1766-1769 could pass spuriously OR fail when it should pass.
2. **Cleanup leak:** if the test fails after `_validate_output_dir` somehow accepts the path, `/tmp/foo bar/` could leak outside the `rm -rf "$TMP_DIR"` cleanup.

## Severity

MEDIUM: flake risk + cleanup leak. Doesn't affect correctness of the validator under test, but produces a fragile acceptance test.

## Suggested fix

Use a path under TMP_DIR that still contains the disallowed character:
```bash
local crafted_outdir="$TMP_DIR/foo bar/round-01"
```
The path remains absolute, still contains the space that `_validate_output_dir` must reject, and stays inside per-test cleanup scope.
