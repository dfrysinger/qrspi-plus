# Security review — task-21 round-08 (security-claude): CLEAN

No new attacker-reachable security findings in this round's diff.

## Round-7 closure verified

- **sec-claude R7 F02 (marker-injection breakout)** — closed cycle-8 514a6cd.
  `FORBIDDEN_MARKERS` array enumerates 5 sentinels
  (`<<<AGENT-BODY-END>>>`, `<<<UNTRUSTED-SCOPE-HINT-START`,
  `<<<UNTRUSTED-SCOPE-HINT-END`, `<<<UNTRUSTED-ARTIFACT-START`,
  `<<<UNTRUSTED-ARTIFACT-END`); both `reject_if_contains_marker_file`
  and `reject_if_contains_marker_value` iterate the array. Three new
  bats regressions pin the SCOPE-HINT-END / UNTRUSTED-ARTIFACT-START
  / UNTRUSTED-ARTIFACT-END rejection paths via `--scope-hint` and
  `--field` value injection.

## Round-7 deferrals (per dispatch — not re-flagged)

- sec-claude R7 F01: `QRSPI_REPO_ROOT` env override broadens the
  canonical-root boundary (= sec-codex R3+R6).
- TOCTOU symlink swap between `assert_ancestor_under_repo_root`
  pre-mkdir and `assert_path_under_repo_root` post-mkdir
  (sec-codex R3+R6).
- mktemp + mv non-atomic job-record write
  (sec-claude R5 F03 LOW).

## Round-8 surface coverage confirmed

- `assert_path_under_repo_root` applied after existence check and
  before any `cat`/strip_frontmatter on every path family in single
  mode: `agent-file`, additional `skill[*]`, `subject-code` /
  `artifact-body`, `task-def`, `companion[*]`, `diff-file`. Batch
  mode covers `--artifact` and per-tag `--agents` file paths.
- `assert_file_exists` is hoisted above the batch block so the
  existence + boundary two-step pattern fires identically in both
  single-mode and batch-mode code paths (eliminates the
  `[[ -n ... && -f ... ]]` silent-skip path in batch mode).
- Batch mode adds `[a-z][a-z0-9_-]*` allowlist on `--agents` tags
  (mirror of single-mode `--reviewer-tag`), preventing crafted tags
  from redirecting prompt-file path construction.
- Batch mode adds inline `[A-Za-z0-9_:@.-]+` grammar check on the
  job-id returned from `dispatch-companion launch`; an invalid id
  emits a WARN line and records a `failed` manifest entry rather
  than `exit 1`-ing mid-batch and orphaning the broker job.
- `dispatch-companion.sh launch` adds two-stage `--round-dir`
  enforcement (ancestor pre-mkdir + canonical post-mkdir) so a
  rejected out-of-repo `--round-dir` leaves no filesystem state
  outside the repo (regression test pins this). `--prompt-file`
  shares the same canonical-root boundary guard.
  `--tag` is allowlist-validated.
- `dispatch-companion.sh await` re-validates `_job_tag` against
  the same `[a-z0-9_-]` grammar and runs `assert_path_under_repo_root`
  on `_job_round_dir` extracted from the persisted job record before
  using either to construct `_raw_dir` / `_raw_file`. Closes the
  crafted-job-record traversal surface end-to-end.
- `path-guard.sh` source guard: when the file is present but
  empty/corrupt, the wrapper exits non-zero with
  `not defined after sourcing` rather than continuing with no-op
  boundary enforcement (test pins this with a fake repo root + empty
  `path-guard.sh`).
- `agents/qrspi-implementer.md` carries the
  `## Orchestrator-Only Scripts (Bash Allowlist)` section naming
  both post-rename scripts and forbidding relative / absolute /
  alias / shell-expansion invocation shapes.
- `dispatch-companion.sh` audit comment documents the legacy
  `--provider/--artifact-dir` form as stdin-only and explains why the
  vendor-neutral `launch` raw-path surface shares the dispatch-agent
  boundary guard.

## Edge considerations checked and dismissed

- `--round` value lacks an allowlist and is emitted via
  `printf 'round: %s\n' "$ROUND"`; theoretically a marker-bearing
  round value would inject. ROUND is structurally an integer-valued
  orchestrator-supplied scalar that never carries artifact-derived
  data, so it falls outside the untrusted-content-into-LLM-channel
  threat model the round-7 marker tightening targeted. Not an
  attacker-reachable vector.
- Companion `NAME` is allowlisted to `[A-Za-z_][A-Za-z0-9_]*`;
  companion paths are boundary-guarded and content-scanned for
  markers. Filename-as-id injection via `<<<`-bearing filenames
  would require an attacker-creatable file under canonical
  `$REPO_ROOT/` — implausible without an independent write primitive.
- Path-guard prefix anchoring (`case "$canon/" in "$canon_root"/*)`)
  correctly distinguishes `/repo/foo` from `/repo-evil/foo` and
  permits `canon == canon_root` (e.g. when caller passes the repo
  root itself as a path arg).
- `_validate_output_dir` excludes `<`, so `--output-dir` cannot
  inject markers via the `round_subdir:` line.

No findings.
