# T6 Traceability Summary — Round 11

**Reviewer:** gt-claude  
**Round:** 11  
**Artifact:** `scripts/run-codex-review.sh` + 4 test files (`test-host-detection.bats`, `test-codex-review-host-detection.bats`, `test-codex-review-codex-availability.bats`, `test-codex-review-source-guard.bats`)  
**Goal anchor:** G6 (goals.md §G6 "Cross-CLI Codex auto-detection")  
**Task:** task-06.md (`goal_ids: [G6]`), plan.md §Task 6

---

## 1. Forward Chain: Goal → Criterion → Test → Implementation

```
G6 (goals.md §G6)
 └─ plan.md Phase 1 acceptance criterion:
      "Codex reviewer dispatches succeed end-to-end on both Claude Code and
       Copilot CLI hosts using the host-appropriate transport." (line 64)
 └─ task-06.md Test Expectations TE1–TE17
      └─ test-host-detection.bats (primary coverage file)
      └─ test-codex-review-host-detection.bats (sec.F01 R5/R7/R8 security)
      └─ test-codex-review-codex-availability.bats (sec.F02 R5 security)
      └─ test-codex-review-source-guard.bats (sec.F01 positive-path guard)
           └─ detect_host() + check_codex_available() + dispatch surface
              in scripts/run-codex-review.sh (diff lines 38–55, 63–106, 139–190)
```

---

## 2. Spec Bullet → Test Name Map

### Core test expectations (task-06.md TE1–TE17)

| TE# | Spec bullet (abbreviated) | Test file | Test name |
|-----|--------------------------|-----------|-----------|
| TE1 | detect_host emits copilot-cli when COPILOT_CLI=1 | test-host-detection.bats | `[host-detect] detect_host emits copilot-cli to stdout when COPILOT_CLI=1` ⚠ |
| TE1 | (exit code 0 subtest) | test-host-detection.bats | `[host-detect] detect_host exits 0 when COPILOT_CLI=1` ⚠ |
| TE1+ | (positive-path regression guard, skip-aware) | test-codex-review-source-guard.bats | `[r5-sec.F01] detect_host trusts marker when gh is in a system-controlled prefix (/usr\|/opt\|/Applications)` |
| TE2 | detect_host emits claude-code when COPILOT_CLI unset | test-host-detection.bats | `[host-detect] detect_host emits claude-code when COPILOT_CLI is unset` |
| TE3 | detect_host emits claude-code when COPILOT_CLI="" | test-host-detection.bats | `[host-detect] detect_host emits claude-code when COPILOT_CLI is empty string` |
| TE4 | detect_host emits claude-code for COPILOT_CLI=0 | test-host-detection.bats | `[host-detect] detect_host emits claude-code when COPILOT_CLI=0` |
| TE4 | detect_host emits claude-code for COPILOT_CLI=true | test-host-detection.bats | `[host-detect] detect_host emits claude-code when COPILOT_CLI=true` |
| TE4 | detect_host emits claude-code for COPILOT_CLI=yes | test-host-detection.bats | `[host-detect] detect_host emits claude-code when COPILOT_CLI=yes` |
| TE5 | 2-branch probe: only literal "1" triggers copilot-cli | test-host-detection.bats | `[host-detect] 2-branch probe: COPILOT_CLI=11 is not the literal string 1 so emits claude-code` |
| TE6 | COPILOT_CLI_BINARY_VERSION alone not a trigger | test-host-detection.bats | `[host-detect] COPILOT_CLI_BINARY_VERSION set but COPILOT_CLI unset still emits claude-code` |
| TE7 | detect_host output solely determined by COPILOT_CLI | test-host-detection.bats | `[host-detect] detect_host result is unchanged when other Copilot env vars are present` |
| TE8 | check_codex_available copilot-cli → exit 0 without filesystem probe | test-host-detection.bats | `[codex-availability] check_codex_available returns exit 0 for copilot-cli without filesystem probe` |
| TE9 | check_codex_available claude-code → exit 0 when companion glob resolves | test-host-detection.bats | `[codex-availability] check_codex_available returns exit 0 for claude-code when companion glob resolves` |
| TE10 | check_codex_available claude-code → non-zero when no companion files | test-host-detection.bats | `[codex-availability] check_codex_available returns non-zero for claude-code when companion glob is empty` |
| TE11 | Unrecognized host → non-zero exit | test-host-detection.bats | `[codex-availability] check_codex_available returns non-zero for unrecognized host argument` |
| TE11 | Unrecognized host → single-line stderr diagnostic naming host value | test-host-detection.bats | `[codex-availability] check_codex_available emits single-line stderr diagnostic for unrecognized host` |
| TE12 | Mismatch: names both detected host and config value | test-host-detection.bats | `[dispatch-surface] mismatch warning names both the detected host and the codex_reviews config value` |
| TE12 | Mismatch is warning-only: dispatch runs, exit code from transport | test-host-detection.bats | `[dispatch-surface] mismatch is warning-only: dispatch runs and exits with transport exit code` |
| TE13 | claude-code path: shell-pipeline marker exactly once | test-host-detection.bats | `[dispatch-surface] claude-code path emits [transport: shell-pipeline] exactly once in stderr` |
| TE13 | claude-code path: task-tool marker absent | test-host-detection.bats | `[dispatch-surface] claude-code path does not emit [transport: task-tool] in stderr` |
| TE14 | copilot-cli path: task-tool marker exactly once | test-host-detection.bats | `[dispatch-surface] copilot-cli path emits [transport: task-tool] exactly once in stderr` ⚠ |
| TE14 | copilot-cli path: shell-pipeline marker absent | test-host-detection.bats | `[dispatch-surface] copilot-cli path does not emit [transport: shell-pipeline] in stderr` ⚠ |
| TE15 | detect_host: no stderr on copilot-cli path | test-host-detection.bats | `[host-detect] detect_host writes nothing to stderr on copilot-cli path` |
| TE15 | detect_host: no stderr on claude-code path | test-host-detection.bats | `[host-detect] detect_host writes nothing to stderr on claude-code path` |
| TE15 | check_codex_available copilot-cli: no stderr | test-host-detection.bats | `[codex-availability] check_codex_available copilot-cli writes nothing to stderr under normal operation` |
| TE15 | check_codex_available claude-code success path: no stderr | **MISSING** ⚠ | — (gap, see F03) |
| TE16 | Non-zero transport exit code propagated unchanged | test-host-detection.bats | `[dispatch-surface] non-zero transport exit code is propagated unchanged on shell-pipeline path` |
| TE17 | Mismatch path does not suppress non-zero transport exit code | test-host-detection.bats | `[dispatch-surface] mismatch path does not suppress non-zero transport exit code` |

### Security / correctness fix tests (R3–R9, not in original TE bullets)

| Fix ID | Description | Test file | Test name |
|--------|-------------|-----------|-----------|
| R3/sec.F01 | detect_host emits claude-code when gh absent from PATH | test-host-detection.bats | `[r3-sec.F01] detect_host emits claude-code when COPILOT_CLI=1 but gh binary not reachable in PATH` |
| R3/sec.F02 | HOME with `..` rejected | test-host-detection.bats | `[r3-sec.F02] check_codex_available emits diagnostic and returns non-zero when HOME contains .. component` |
| R3/sec.F03 | _codex_reviews sanitized to true\|false literal | test-host-detection.bats | `[r3-sec.F03] codex_reviews value is validated to a safe literal before echoing in mismatch diagnostic` |
| R3/sf.F01 | source guard: return 0 2>/dev/null \|\| exit 0 | test-host-detection.bats | `[r3-sf.F01] source guard exits cleanly when script is directly executed with QRSPI_SOURCE_ONLY=1` |
| R3/sf.F02 | dispatch pipeline uses set -o pipefail | test-host-detection.bats | `[r3-sf.F02] dispatch section uses a pipefail-safe invocation for compose_prompt pipeline` |
| R3/sf.F03 | check_codex_available call site has no 2>/dev/null suppression | test-host-detection.bats | `[r3-sf.F03] check_codex_available at dispatch call site does not suppress its stderr diagnostic` |
| R5/sec.F01 | gh path outside /usr\|/opt\|/Applications rejected | test-codex-review-host-detection.bats | `[r5-sec.F01] detect_host rejects copilot-cli marker when gh resolves outside /usr\|/opt\|/Applications` |
| R5/sec.F01+ | positive-path: trusted-prefix gh still accepted (skip-aware) | test-codex-review-source-guard.bats | `[r5-sec.F01] detect_host trusts marker when gh is in a system-controlled prefix (/usr\|/opt\|/Applications)` |
| R5/sec.F02 | relative HOME rejected for companion glob | test-codex-review-codex-availability.bats | `[r5-sec.F02] check_codex_available rejects relative HOME with exit 1 and stderr containing 'absolute'` |
| R7/sec.F01 | PATH /usr/../injection rejected via realpath normalization | test-codex-review-host-detection.bats | `[r7-sec.F01] PATH with /usr/../ injection rejected` |
| R7/sec.F02 | symlink in trusted prefix pointing to untrusted dir rejected | test-codex-review-host-detection.bats | `[r7-sec.F02] symlink in trusted prefix pointing to untrusted dir rejected` |
| R8/sec.F01 | fail-closed when both realpath and readlink -f are absent | test-codex-review-host-detection.bats | `[r8-sec.F01] detect_host fail-closed when realpath and readlink-f both absent` |

---

## 3. Backward Trace: Implementation → Test → Spec → Goal

| Implementation behavior | Test(s) | Spec criterion | Goal |
|------------------------|---------|----------------|------|
| `detect_host()` copilot-cli branch | TE1 tests (fragile, see F01), R5/sec.F01 positive guard | TE1 | G6 |
| `detect_host()` claude-code branch (COPILOT_CLI≠1) | TE2–TE7 tests | TE2–TE7 | G6 |
| `detect_host()` R3 binary-reachability gate | `[r3-sec.F01]` | R3/sec.F01 | G6 |
| `detect_host()` R5/R7 trusted-prefix prefix check | `[r5-sec.F01]`, `[r7-sec.F01]` | R5/sec.F01 | G6 |
| `detect_host()` R7 symlink follow via realpath | `[r7-sec.F02]` | R7/sec.F02 | G6 |
| `detect_host()` R8 fail-closed when realpath/readlink absent | `[r8-sec.F01]` | R8/sec.F01 | G6 |
| `check_codex_available()` copilot-cli arm | TE8, TE15 (copilot-cli stderr) | TE8, TE15 | G6 |
| `check_codex_available()` claude-code arm (companion found) | TE9 | TE9 | G6 |
| `check_codex_available()` claude-code arm (no companion) | TE10 | TE10 | G6 |
| `check_codex_available()` `*` arm (unknown host) | TE11 (exit + diagnostic) | TE11 | G6 |
| `check_codex_available()` HOME `..` rejection | `[r3-sec.F02]` | R3/sec.F02 | G6 |
| `check_codex_available()` relative HOME rejection | `[r5-sec.F02]` | R5/sec.F02 | G6 |
| `QRSPI_SOURCE_ONLY=1` source guard (`return 0 2>/dev/null \|\| exit 0`) | `[r3-sf.F01]` | R3/sf.F01 | G6 |
| `_codex_reviews` `true\|false` normalization case | `[r3-sec.F03]` (structural grep) | R3/sec.F03 | G6 |
| No `check_codex_available ... 2>/dev/null` at call site | `[r3-sf.F03]` (structural grep) | R3/sf.F03 | G6 |
| `set -o pipefail` in dispatch subshells | `[r3-sf.F02]` (structural grep) | R3/sf.F02 | G6 |
| `[transport: shell-pipeline]` stderr marker | TE13 tests | TE13 | G6 |
| `[transport: task-tool]` stderr marker | TE14 tests (fragile, see F02) | TE14 | G6 |
| Mismatch diagnostic (names host + config) | TE12 tests | TE12 | G6 |
| Exit-code propagation (no suppression) | TE16 test | TE16 | G6 |
| Mismatch path exit-code propagation | TE17 test | TE17 | G6 |

No implementation behavior found without a trace to G6. No YAGNI signals identified.

---

## 4. Gap Analysis

| Criterion | Task should cover? | Test expectation? | Actual test? | Status |
|-----------|-------------------|-------------------|--------------|--------|
| TE1 (copilot-cli positive path) | Yes | Yes | Yes, but fragile (F01) | ⚠ Gap |
| TE2–TE7 (claude-code paths) | Yes | Yes | Yes, robust | ✓ |
| TE8–TE11 (check_codex_available) | Yes | Yes | Yes, robust | ✓ |
| TE12 (mismatch warning) | Yes | Yes | Yes, robust | ✓ |
| TE13 (shell-pipeline marker) | Yes | Yes | Yes, robust | ✓ |
| TE14 (task-tool marker) | Yes | Yes | Yes, but fragile (F02) | ⚠ Gap |
| TE15 (no stderr — detect_host both paths) | Yes | Yes | Yes | ✓ |
| TE15 (no stderr — check_codex_available copilot-cli) | Yes | Yes | Yes | ✓ |
| TE15 (no stderr — check_codex_available claude-code success) | Yes | Yes | **Missing** (F03) | ⚠ Minor gap |
| TE16 (exit-code propagation) | Yes | Yes | Yes, robust | ✓ |
| TE17 (mismatch + exit-code propagation) | Yes | Yes | Yes, robust | ✓ |

---

## 5. Findings Summary

| ID | Severity | Title |
|----|----------|-------|
| F01 | High | TE1 tests fragile in CI — detect_host requires trusted gh binary but tests don't ensure one is present |
| F02 | High | TE14 dispatch-surface tests fragile in CI — COPILOT_CLI=1 insufficient without trusted gh |
| F03 | Minor | TE15 gap — check_codex_available claude-code success path missing stderr-clean assertion |

### Symbols used
- ⚠ = affected by a finding
- ✓ = clean trace, no gap
