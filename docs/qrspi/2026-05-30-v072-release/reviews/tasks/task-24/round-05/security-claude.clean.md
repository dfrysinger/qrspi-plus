# Security Review — Round 5 — CLEAN

**Reviewer:** security-claude  
**Round:** 5  
**Artifact:** `scripts/detect-interaction-mode.sh` + `tests/unit/test-detect-interaction-mode.bats`  
**Scope:** Additive test-only diff (5 new bats tests: FINDING A–E labels); script frozen, sec-CLEAN confirmed in rounds 3 and 4.

---

## Disposition: NO SECURITY FINDINGS

No exploitable vulnerabilities found in either the frozen script or the five new test additions.

---

## Review Summary by Category

### 1. Injection
**Script (frozen):** All output is via `printf` with literal format strings. The only user-controlled value that reaches `printf '%s\n'` is `QRSPI_INTERACTION_MODE`, and it passes through an explicit `case` statement that restricts it to the literals `auto` and `interactive` before the `printf` executes (script lines 100–116). The `COPILOT_CLI` and `CLAUDE_PROJECT_DIR` variables are compared to known literals only; neither is ever interpolated into a command or output format string. No injection surface exists.

**New tests:** The five new bats tests (FINDING A–E, lines 527–617) use the same `run bash -c "..."` pattern established in prior rounds. `$SCRIPT` is set from `pwd -P` over a deterministic path rooted at `$BATS_TEST_FILENAME`; it is not attacker-controlled during test execution. The `CLAUDE_PROJECT_DIR='/some/project'` value is a hardcoded literal in every test invocation. No injection path exists.

### 2. Authentication and Authorization
Not applicable. This is a local shell helper with no network surface, no authentication context, and no access-control decisions. The helper only reads env vars and writes to stdout/stderr.

### 3. Data Exposure
The script header embeds `COPILOT_AGENT_SESSION_ID=fff21ea0-f5c1-5736-8915-9b157f49df28` (line 67) as a verification citation. This is a historical observation-session identifier, not a reusable credential. It grants no access to any system and does not represent a secret. No sensitive data flows to logs, error messages, or stdout beyond the controlled `DETECTION_TYPE/VERDICT/EVIDENCE/PLATFORM/INSTRUCTION` output fields, whose values are all bounded enumerations or literal strings embedded in the script source.

### 4. Input Validation
`QRSPI_INTERACTION_MODE` is the only user-supplied input consumed by the script. It is validated via `case` before any use; the wildcard arm exits non-zero with diagnostics (lines 118–123). All other env vars (`COPILOT_CLI`, `CLAUDE_PROJECT_DIR`) are read only for comparison; their values never reach a dangerous sink. No unbounded input, no deserialization, no regex with catastrophic backtracking.

The new tests exercise the validation boundary (invalid value `yolo` → non-zero exit, positional arg → non-zero exit) and confirm it holds.

### 5. Dependency Risks
No external dependencies. The script requires only `bash` ≥ 3.2 and standard POSIX utilities (`printf`, `echo`). The tests require only `bats` ≥ 1.5.0 and `find`/`wc`. No packages with known CVEs are introduced.

### 6. Cryptography
No cryptographic operations. Not applicable.

### 7. Race Conditions
The script performs no file I/O and holds no shared mutable state. All outputs go to stdout/stderr. No TOCTOU or concurrent-access surface exists.

---

## New Test Content (round-05 additions) — Security Assessment

| Test | Security-relevant assertion | Assessment |
|---|---|---|
| FINDING A — `## Auto Mode Active` absent from `agents/` | Grep regression preventing Claude Code in-context signal leakage into agent prose | Correct; no false-negative risk |
| FINDING B — Claude Code branch output-shape KEY=VALUE | Validates no unexpected lines emitted by Claude Code branch | Correct isolation |
| FINDING C — Precedence: `COPILOT_CLI=1` wins over `CLAUDE_PROJECT_DIR` | Validates deterministic branch selection under ambiguous env | No security impact; correct precedence |
| FINDING D — Semantic EVIDENCE content for unknown-host safe-default | Validates evidence names override-var absence and safe-default outcome | Strengthens audit-trail correctness |
| FINDING E — No-file-write for Claude Code branch | Asserts Claude Code branch does not write `.interaction-mode-audit.json` | Extends single-writer guarantee coverage to all three branches |

None of the five new tests introduce new code paths, new env var reads, or new shell constructs. All are structurally identical to the existing test patterns already reviewed in rounds 3 and 4.

---

## Confidence
High. The diff is narrow (test file only, 5 tests), the script is frozen, and two prior security-clean confirmations cover the script's full logic. No new attack surface was introduced.
