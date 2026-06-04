# Security Review — Clean Sentinel

**Task:** T19 · `second-reviewer-available.sh` helper  
**Round:** 6  
**Reviewer:** security-claude  
**Scope:** Test-only additive delta (no production changes)  
**Delta ref:** round-06.diff  

---

## Verdict: CLEAN

No material security findings. The test-only delta adds three changes, all reviewed below.

---

## Change-by-change analysis

### 1. New `@test` — "unknown host default path jointly asserts single-line host=unknown vendor=none" (diff lines 11–39)

```bash
bash -c "
  unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI
  \"$SECOND_REVIEWER\"
" >/dev/null 2>"$_stderr_file" || _status=$?
```

**`$SECOND_REVIEWER` in `bash -c "..."`**  
`SECOND_REVIEWER` is set in `setup_file()` as `"$REPO_ROOT/scripts/second-reviewer-available.sh"`.  
`REPO_ROOT` is resolved either by walking up from `BATS_TEST_DIRNAME` to find `.git`, or via `git rev-parse --show-toplevel` — both sources are controlled by the repository's own file-system layout, not by any external or user-supplied input.  
The value is double-quoted inside the bash -c string (`\"$SECOND_REVIEWER\"`), so word-splitting and glob-expansion are suppressed in the inner shell.  
Attack scenario: an attacker would need to control `REPO_ROOT` (i.e., plant a `.git` directory at a path with embedded shell metacharacters). That is not a realistic attack on a CI test harness; it is a pre-existing host-compromise precondition, not a vulnerability introduced by this delta.

**`$_stderr_file` redirect target**  
`TMP_DIR` is produced by `mktemp -d` in `setup()`, which creates a directory with mode 0700 and an unpredictable suffix. The stderr file path is double-quoted at the redirect site. No symlink-race or predictable-path risk.

**`unset COPILOT_CLI CLAUDE_PROJECT_DIR CODEX_CLI`**  
Safe environment-variable clearing; no expansion or injection vector.

### 2. New grep assertion in existing "unknown vendor override" test (diff line 49)

```bash
grep -q 'vendor=nonexistent-vendor-xyz' "$_stderr_file"
```

Fixed literal pattern, no interpolated variables. Clean.

### 3. Strengthened grep pattern in existing "unavailable vendor diagnostic" test (diff lines 57–58)

```diff
- grep -qE 'nonexistent-vendor-xyz|vendor=' "$_stderr_file"
+ grep -q 'vendor=nonexistent-vendor-xyz' "$_stderr_file"
```

Assertion tightening only. No security-relevant change.

---

## Categories checked

| Category | Finding |
|---|---|
| Injection (command, shell expansion, path traversal) | None |
| `eval` / unsafe `bash -c` with user-controlled input | None — all interpolated vars are repo-internal, not user-supplied |
| Predictable or world-writable temp paths | None — `mktemp -d` used throughout |
| Sensitive data exposure (credentials, tokens) | None — test harness only |
| Input validation / unquoted variable expansion | None |
| Auth / access control | N/A (test file) |
| Cryptography | N/A (test file) |
| Race conditions (TOCTOU) | None — `TMP_DIR` is per-test, unguessable |
