# Spec Reviewer (claude) — Task 21, Round 10: CLEAN

Verified the round-10 cumulative diff (4ec927b) closes all three target findings:

## R9 F01 sec-codex — path-string injection
- `reject_if_path_unsafe_for_emission` added in `scripts/dispatch-agent.sh`
  (rejects `\n`, `\r`, or any FORBIDDEN_MARKER in the path string before
  it is emitted into `id=<path>` / `diff_file_path: <path>`).
- Applied to all four path families: PRIMARY (subject-code/artifact-body),
  task-def, companion[*], diff-file.
- New test: `path-emission: --subject-code path containing newline
  rejected before prompt emission`.
- FORBIDDEN_MARKERS array expanded from a single literal to all five
  wrapper markers (AGENT-BODY-END, UNTRUSTED-SCOPE-HINT-START/END,
  UNTRUSTED-ARTIFACT-START/END), with three new marker-rejection tests
  for `--scope-hint` and `--field` value paths.

## R9 F02 sec-codex — job-record line injection
- `scripts/dispatch-companion.sh` launch mode rejects `\n`/`\r` in
  --vendor / --model / --prompt-file / --round-dir / --tag values before
  any job-record line is written.
- Tag allowlist `^[a-z][a-z0-9_-]*$` enforced at launch.
- Await mode re-validates `_job_tag` (allowlist) and `_job_round_dir`
  (`assert_path_under_repo_root`) extracted from the persisted record
  before constructing `_raw_dir`.
- New tests: `companion launch: --vendor with embedded newline rejected
  before job-record write`; `companion await: job record with traversal
  tag rejected with 'invalid tag'`; `companion await: job record with
  out-of-repo round_dir rejected with 'resolves outside repository'`.

## R9 F01 cq-claude / cq-codex — R8 reviewer-tag hygiene strip
All implementation-history tags removed from production comments:
- `Per T04 of the v0.7 release` → `Per-task implementer dispatch shim`
- `Per T04: this shim does NOT...` → `This shim does NOT...`
- `Allowlist validation (T09 R2 fix):` → `Allowlist validation:` (×2)
- `unchanged from pre-T04` → `unchanged from earlier shim refactor` (×2)
- `R5 F04: Multi-reviewer batched dispatch` → `Multi-reviewer batched dispatch`

## Cross-cutting checks
- Definition-of-done items (lines 39–45 of task-21.md) all satisfied,
  including `resolves outside repository` diagnostic, broken-symlink
  boundary handling, no-raw-path read before checks pass, and the
  Orchestrator-Only Scripts allowlist with all four invocation shapes.
- Test-expectation lines 49–56 all have matching tests in
  `tests/unit/test-dispatch-agent.bats`.
- Target-files deviation (advisory): production touches `agents/qrspi-implementer.md`
  (in-spec), `scripts/dispatch-agent.sh` / `dispatch-companion.sh` (in-spec),
  `tests/unit/test-dispatch-agent.bats` (in-spec), plus the new shared
  `scripts/lib/path-guard.sh` and small fixture-path adjustments in
  `tests/unit/test-dispatch-sites.bats`. All accepted per prior spec
  amendments (v0.7.3 deferral noted in dispatch).

No new findings.
