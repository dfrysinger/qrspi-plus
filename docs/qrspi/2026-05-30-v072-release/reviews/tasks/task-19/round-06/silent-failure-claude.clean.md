# Silent-Failure Review — Clean

**Reviewer:** silent-failure-claude  
**Task:** T19  
**Round:** 6  
**Artifact:** tests/unit/test-second-reviewer-available.bats (TEST-ONLY ADDITIVE DELTA)

## Verdict: CLEAN — no material silent-failure gaps found

### Scope reviewed

Three changes in the round-06 diff:

1. **New test** "unknown host default path jointly asserts single-line host=unknown vendor=none"
2. **Added assertion** `grep -q 'vendor=nonexistent-vendor-xyz'` in "unknown vendor override" test
3. **Tightened grep** from `'nonexistent-vendor-xyz|vendor='` (disjunction) to `'vendor=nonexistent-vendor-xyz'`

---

### New "unknown host default path" test — analysis

**Execution path correctness:** `bash -c "unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI; \"$SECOND_REVIEWER\""` correctly clears both real detection signals before `$SECOND_REVIEWER` is exec'd. `_host-detect.sh` only checks `COPILOT_CLI=1` and `CLAUDE_PROJECT_DIR` (non-empty); with both absent, `detect_host` returns `unknown`. `lookup_default_second_reviewer "unknown"` hits the `*` case and returns `none`. The guard in `second-reviewer-available.sh` fires on `_default_vendor=none`, emits the single `[second-reviewer-unavailable] host=unknown vendor=none …` line to stderr, and exits 1. The test truly reaches the intended code path.

**Per-assertion regression-detection check:**

| Assertion | Regression it catches |
|---|---|
| `[ "$_status" -ne 0 ]` | Production exits 0 for unknown host |
| `[ "$line_count" -eq 1 ]` | Multi-line output OR newline dropped (→ wc -l returns 0) |
| `grep '^\[second-reviewer-unavailable\]'` | Tag changed or not at line start |
| `grep 'host=unknown'` | host field renamed or value changed |
| `grep 'vendor=none'` | vendor field renamed or value changed |

All five are independently non-vacuous. An empty stderr file fails `line_count -eq 1`. A single wrong-format line (e.g., a bash "command not found" infra error) would pass `line_count -eq 1` but fail the `^\[second-reviewer-unavailable\]` grep. No assertion can be satisfied vacuously by the others.

**Exit-code capture:** `local _status=0` + `|| _status=$?` is correct and distinct from the `|| true` pattern used in older tests. The `||` prevents bats errexit from firing; `_status` is correctly updated. The `[ "$_status" -ne 0 ]` assertion would hard-fail if production regressed to exit 0.

**Environment isolation:** `CODEX_CLI` is not a detection signal in `_host-detect.sh` (no branch exists for v0.7.2); unsetting it is belt-and-suspenders. The two genuine signals (`COPILOT_CLI`, `CLAUDE_PROJECT_DIR`) are correctly unset. Any CI environment that exports these signals would have them unset before `$SECOND_REVIEWER` runs, since the `unset` executes in the same `bash -c` context from which the script is launched.

---

### Added `vendor=nonexistent-vendor-xyz` assertion — analysis

Correctly requires both key and exact value in the diagnostic. Would catch a production regression that dropped `$_vendor` from the `printf` format string or changed the field separator. No gap.

---

### Tightened grep — analysis

Old disjunction `'nonexistent-vendor-xyz|vendor='` would pass if only `vendor=` (with any or empty value) appeared. New form `'vendor=nonexistent-vendor-xyz'` requires both key and value verbatim. The test still uses `|| true` (pre-existing, not changed), but that test's purpose is diagnostic-content verification, not exit-code coverage — exit-code coverage is provided by the adjacent "unknown vendor override" test. The grep alone is sufficient for the claimed coverage, and the tightened form eliminates the disjunction loophole.

---

### Pre-existing patterns not changed by this delta

The "diagnostic names requested vendor" test (line 276–284) still uses `|| true` with `grep -qE 'vendor='`. This is pre-existing and not within the round-06 delta. The new joint-assertion test provides tighter independent coverage of the same path, so the pre-existing test's weakness does not create a net gap.

---

No findings emitted. All new and modified test assertions are non-vacuous and would detect the regressions they claim to cover.
