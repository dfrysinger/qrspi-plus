---
reviewer: security-claude
task: 11
round: 4
verdict: clean
---

# Security Review — Task 11, Round 4: Clean

No exploitable security vulnerabilities found.

## R3 Fix Verification

All three R3 security findings are correctly resolved in this diff:

### F01 — OUTPUT_DIR injection in split_cmd
**Fixed.** `_validate_output_dir` (regex `^/[A-Za-z0-9_./:@-]+$`) is called at the
`--output-dir` parse case *before* `OUTPUT_DIR` is assigned (diff lines 233–236). At the
point `emit_dispatch_manifest_entry` constructs `split_cmd`, `$OUTPUT_DIR` has already been
allowlist-gated. Characters permitted by the validator are safe in an unquoted shell word,
so downstream consumers that eval-expand `split_cmd` cannot be injected through this field.

### F02 — job_id injection in await_cmd
**Fixed.** `_validate_job_id` (regex `^[A-Za-z0-9_:@.-]+$`) is called at line 959 before
`emit_dispatch_manifest_entry "$_job_id" "pending"`. The failed-path call
`emit_dispatch_manifest_entry "" "failed"` passes an empty string which is safe (appends
only trailing whitespace to the `await_cmd` string). No unvalidated job_id value can
reach the manifest.

### F03 — compose_prompt redirect symlink overwrite
**Fixed.** `rm -f "$_fp_prompt_file"` (line 905) executes immediately before the `>`
redirect, atomically removing any pre-existing file or attacker-planted symlink. The path
components (`$OUTPUT_DIR` and `$REVIEWER_TAG`) are both validated so the path itself cannot
escape the `.dispatch/` subdirectory.

### F04 — Lock dir pre-creation DoS / SIGKILL stale-lock
**Fixed.** The EXIT/INT/TERM trap (`trap 'rmdir "$_manifest_lock_dir" 2>/dev/null || true'`)
is armed immediately after the winning `mkdir` in `_append_manifest_entry`. A 30-second
mtime probe (lines 277–285) provides stale-lock recovery for SIGKILL cases.

## T11 New Additions — No New Vulnerabilities

**`emit_dispatch_manifest_entry` / `emit_first_party_manifest_entry`:** Every
user-controlled value (`$REVIEWER_TAG`, `$MODEL`, `$job_id`, `$prompt_file`, `$agent_name`)
is passed exclusively via jq `--arg`, which provides unconditional JSON string encoding as
defense-in-depth on top of the parse-time allowlist validators. Neither `await_cmd` nor
`split_cmd` receives unvalidated input: `OUTPUT_DIR` and `REVIEWER_TAG` are validated at
parse time; `job_id` is validated at the call site before entry into the function. The
`agent_name` field (from `basename "${AGENT_FILE%.md}"`) is stored as a JSON string only
and does not appear in any eval-expanded command field.

**`eval "$_saved_opts"` in `_append_manifest_entry`:** The `_saved_opts` variable is
populated from `set +o | grep -E 'errexit|errtrace|functrace'` — output entirely controlled
by the bash built-in, never by user input. The eval is safe.

**`_lock_age` not declared with `local` (line 280):** This variable leaks to script scope
as a plain integer derived from `date +%s` arithmetic. It is not user-controllable and
poses no security risk.

## Reviewed Surfaces

- `scripts/run-codex-review.sh`: `_validate_output_dir`, `_validate_job_id`,
  `_append_manifest_entry`, `emit_dispatch_manifest_entry`,
  `emit_first_party_manifest_entry`, first-party dispatch path (lines 895–914),
  third-party JOB_ID capture loop (lines 926–960)
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`: T11 AC1–AC4, AC6 additions;
  TE10/TE11/TE13 revisions; AC5/AC9 shape-assertion updates
