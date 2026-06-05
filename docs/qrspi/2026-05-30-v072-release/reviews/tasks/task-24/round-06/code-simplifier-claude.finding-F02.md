---
finding: F02
reviewer: code-simplifier-claude
round: 6
severity: advisory
blocking: false
category: verbose-pattern
file: tests/unit/test-detect-interaction-mode.bats
lines: [366]
---

# F02 — Redundant explicit `.json` file-existence check

## Summary

The test `[T24] Copilot CLI branch creates no .interaction-mode-audit.json`
(lines 357–371) contains two consecutive assertions about the same directory:

```bash
# line 366 — explicit targeted check
[ ! -f "$tmpdir/.interaction-mode-audit.json" ]

# lines 368–370 — comprehensive count check (strictly stronger)
local n_files
n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$n_files" -eq 0 ]
```

If `n_files -eq 0` passes, then _no_ file exists in `$tmpdir`, which necessarily
includes `.interaction-mode-audit.json`.  The explicit `[ ! -f ... ]` check is
therefore fully subsumed by the count assertion and adds no additional coverage.

## Impact

Minor: one superfluous assertion per test run, zero diagnostic value (both
assertions fail on the same condition).  The pattern also differs from the
parallel `[T24] Unknown host branch creates no files at all` test (lines 373–384),
which only has the count check and omits the targeted file check, creating a
small structural asymmetry between the two no-file-write tests.

## Proposed change

Remove the redundant targeted-file check, aligning with the sibling test's
structure:

```diff
 @test "[T24] Copilot CLI branch creates no .interaction-mode-audit.json" {
   local tmpdir="$BATS_TEST_TMPDIR"
   run bash -c "
     export COPILOT_CLI=1
     unset CLAUDE_PROJECT_DIR QRSPI_INTERACTION_MODE
     cd \"$tmpdir\"
     bash \"$SCRIPT\"
   "
   [ "$status" -eq 0 ]
-  [ ! -f "$tmpdir/.interaction-mode-audit.json" ]
-  # Also assert no unexpected regular files were created
   local n_files
   n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
   [ "$n_files" -eq 0 ]
 }
```

No behaviour change; the stricter assertion (`n_files -eq 0`) already covers the
removed one completely.
