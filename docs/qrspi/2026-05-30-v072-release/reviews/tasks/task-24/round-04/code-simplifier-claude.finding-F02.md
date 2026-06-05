# F02: Specific `.interaction-mode-audit.json` assertion is subsumed by the subsequent general no-files check

**Reviewer:** code-simplifier-claude  
**Round:** 4  
**File:** `tests/unit/test-detect-interaction-mode.bats`  
**Lines:** 366 (specific check) vs. 369–370 (general check)  
**Category:** Dead Code (§2) / Verbose Patterns (§3)  
**Severity:** Advisory / non-blocking

---

## What's happening

In the `[T24] Copilot CLI branch creates no .interaction-mode-audit.json` test, a specific file-existence assertion appears three lines before a strictly stronger general assertion that fully subsumes it:

```bash
[ "$status" -eq 0 ]
[ ! -f "$tmpdir/.interaction-mode-audit.json" ]   # line 366 — specific check
# Also assert no unexpected regular files were created
local n_files
n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$n_files" -eq 0 ]                              # line 370 — general check (subsumes line 366)
```

If zero files exist in `$tmpdir` (`n_files -eq 0`), the specific audit file certainly does not exist. The specific check at line 366 **can never fail independently** from the general check at line 370: any world in which line 366 would fail is also a world where line 370 fails. It adds zero independent test coverage.

---

## Proposed simplification

Remove line 366 (the specific file assertion) and rely solely on the general `n_files -eq 0` check, which already covers the audit-file prohibition and all other files:

```bash
[ "$status" -eq 0 ]
# Assert no files at all were created (covers .interaction-mode-audit.json and any other files)
local n_files
n_files="$(find "$tmpdir" -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$n_files" -eq 0 ]
```

The comment already names what is being prohibited. No behavior change; the test passes/fails identically in all scenarios.

---

## Context

The `[T24] Unknown host branch creates no files at all` test (lines 373–384) doesn't have the redundant specific check — it goes directly to the `n_files` assertion. Removing line 366 from the Copilot CLI test makes the two no-files tests consistent with each other.

Note: the `Unknown host branch creates no files at all` test only checks the unknown-host branch. A third no-files test for the override branch is not present; the existing coverage is sufficient since the prohibition is structural (the script has no `>` or file-write calls), not branch-specific.
