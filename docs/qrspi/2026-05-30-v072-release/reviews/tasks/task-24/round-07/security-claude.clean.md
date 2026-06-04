# Security Review — Task 24 · Round 07 · CLEAN

**Reviewer:** security-claude  
**Round:** 7  
**Artifact:** `tests/unit/test-detect-interaction-mode.bats` (test-only delta)  
**Production script:** `scripts/detect-interaction-mode.sh` — FROZEN / sec-CLEAN in 4 prior rounds  
**Date:** 2026-06-03

---

## Scope

Round-07 delta is test-only: 3 new bats tests (no `[T24]` prefix) and a
grep-target scope fix for the `## Auto Mode Active` regression check.
The production script is unchanged and carries 4 consecutive prior
security-clean rounds; its content was confirmed consistent with the
frozen diff hunk but not re-analysed as a new surface.

---

## Findings

None.

---

## Analysis

### 1. Injection

All `bash -c "..."` test subshells interpolate two bats-supplied variables:

* `$SCRIPT` — set in `setup_file` via `pwd -P` (canonicalized absolute path)
  plus a fixed suffix.  Always starts with `/`; no user-controlled input.
* `$tmpdir` (`$BATS_TEST_TMPDIR`) — allocated per-test by bats; not
  user-supplied.

The `\"$SCRIPT\"` double-quote-escape pattern is consistent with the
existing (previously reviewed) tests.  No new injection surface.

The frozen production script uses `printf '%s'` for all
`QRSPI_INTERACTION_MODE`-derived output (`EVIDENCE=…`); no format-string
risk.

### 2. Grep-target fix (`## Auto Mode Active`)

The new test scopes the `## Auto Mode Active` encapsulation check to
`agents/` only, intentionally skipping `skills/`.  The inline comment
documents why: the string legitimately exists in
`skills/goals/SKILL.md` and `skills/design/SKILL.md` as canonical
prior art — a skills/ check would produce a false failure.

Exit-code check uses `[ "$status" -eq 1 ]` (exact: no-match exit),
not `-ne 0`, which is the correct pattern to avoid a `grep` error
(exit 2) silently masquerading as a passing no-match.  No security
issue.

### 3. No-file-write assertions (new: Claude Code + override branches)

Use `$BATS_TEST_TMPDIR` (per-test isolated directory), `find -maxdepth 1
-type f`, and `wc -l`.  No shared mutable state; no race condition risk.

### 4. Native-detection precedence test

Exercises both `COPILOT_CLI=1` and `CLAUDE_PROJECT_DIR` set simultaneously
and asserts `COPILOT_CLI` wins.  Pure assertion logic; no new dangerous
code path.

### 5. EVIDENCE semantic assertion

Greps `$output` (captured bats string) for `safe default` and
`QRSPI_INTERACTION_MODE`.  No sink, no injection, no data exposure.

### 6. Authentication / Authorization / Cryptography / Dependencies

Not applicable to this test harness delta.  No credentials, secrets,
PII, or cryptographic operations introduced.

---

## Verdict

**CLEAN.** No exploitable security issues identified in the round-07
test-only additions.
