# Security Review — Task-20 Round-04 — Clean

reviewer: security-claude
round: 4
verdict: clean

## Scope

Reviewed `round-04.diff` covering:
- `scripts/dispatch-agent.sh` lines 423–424: relative → absolute path construction in
  `emit_dispatch_manifest_entry()` for `await_cmd` / `split_cmd` manifest fields.
- `tests/unit/test-dispatch-agent.bats`: one new end-to-end drain test.

## Analysis

### Injection (SQL / Command / Path / Shell)

No new injection risk. All variables interpolated into the manifest command strings at
`dispatch-agent.sh:423-424` are validated by allowlist regexes before this code path
is reached:

- `$REPO_ROOT` — derived from `BASH_SOURCE[0]` via `cd … && pwd -P`; not user-supplied
  in production. The `QRSPI_REPO_ROOT` override exists only for tests.
- `$job_id` — validated against `^[A-Za-z0-9_:@.-]+$` by `_validate_job_id` (no spaces,
  no shell metacharacters).
- `$OUTPUT_DIR` — validated against `^/[A-Za-z0-9_./:@-]+$` by `_validate_output_dir`
  (absolute, no spaces, no quotes).
- `$REVIEWER_TAG` (single-reviewer path) — validated against `^[a-z][a-z0-9_-]*$` at
  `dispatch-agent.sh:743` before reaching `emit_dispatch_manifest_entry`.

The downstream consumer (`await-round.sh`) uses `shlex.split` + `subprocess.run(shell=False)`,
not `eval`, so even a malformed value causes a parse/validation error rather than shell
execution. The EXEC_ROOTS path validator in `await-round.sh` independently enforces that
`argv[0]` must resolve under `<git-toplevel>/scripts/`, blocking any attacker-crafted
path that might appear in a tampered manifest.

### Authentication / Authorization

No auth or RBAC logic touched by this diff.

### Data Exposure

No secrets, tokens, or sensitive data flow through the changed lines. The manifest fields
store only script paths and a job ID.

### Input Validation

The fix does not widen the input surface. Validation for all embedded values was already
enforced at argument-parse time (pre-existing). The new test uses `mktemp -d` (non-
predictable tmpdir) and exports env vars scoped to the test process.

### Dependencies / Cryptography / Race Conditions

No dependency changes, cryptographic operations, or shared-state mutations in this diff.

## Conclusion

The diff is a narrowly-scoped correctness fix (relative → absolute path emission in
`emit_dispatch_manifest_entry`). All embedded values are already allowlist-validated at
parse time, and the downstream exec path uses `shell=False` throughout. No exploitable
vulnerability is introduced.
