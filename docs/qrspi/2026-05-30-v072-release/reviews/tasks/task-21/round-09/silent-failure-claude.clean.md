# Silent-Failure Hunter — clean (Task 21, Round 9)

Reviewer: silent-failure-claude
Round: 9
Subject: dispatch-agent.sh, dispatch-companion.sh, scripts/lib/path-guard.sh, agents/qrspi-implementer.md, tests/unit/test-dispatch-agent.bats, tests/unit/test-dispatch-sites.bats

## Verdict

No new silent-failure findings.

## Coverage

Walked the round-9 diff focusing on swallowed errors, silent fallbacks,
missing error paths, inappropriate transformation, log-and-continue, and
partial state on failure. Inspected each new/changed surface:

1. `scripts/lib/path-guard.sh` (`_qrspi_canonicalize`,
   `assert_ancestor_under_repo_root`, `assert_path_under_repo_root`):
   every error branch exits 1 with a diagnostic on stderr; canonicalize
   helper distinguishes empty-stdout-success from non-zero-exit and
   returns 1 in both cases. The R8 broken-symlink-walk fix correctly
   terminates the ancestor walk on `-L` so symlinks are never walked
   past as "non-existent".
2. `dispatch-agent.sh`: source-time sentinel (`command -v
   assert_path_under_repo_root || exit 1`) closes the corrupt-lib gap.
   Batch-mode `--artifact` existence + boundary checks now run before
   the prompt-emission block (the prior `[[ -n .. && -f .. ]]` silent
   skip is gone). Batch-mode `--agents` tag allowlist mirrors single-
   mode grammar before any path construction. JOB_ID grammar check
   emits a `failed` manifest entry + WARN + `continue` per the deferral
   list (per-agent launch-failure batch exit-0 is on the don't-re-flag
   list). Marker-injection guard expanded from a single literal to the
   five-marker `FORBIDDEN_MARKERS` array iterated in both file and
   value variants.
3. `dispatch-companion.sh`: launch-mode `--prompt-file` and
   `--round-dir` get the boundary guard; `--round-dir` is wrapped in a
   two-stage (ancestor pre-mkdir, canonical post-mkdir) check that
   eliminates the previously-observed out-of-repo mkdir partial-state
   class. The post-boundary `_qrspi_canonicalize` call is wrapped with
   `|| die`. await-mode re-validates `_job_tag` (case allowlist) and
   `_job_round_dir` (boundary guard) extracted from the persisted job
   record before constructing `_raw_dir` and `_raw_file`.
4. `agents/qrspi-implementer.md`: the new
   "Orchestrator-Only Scripts (Bash Allowlist)" section forbids both
   post-rename script names under all four invocation shapes; nothing
   to flag from a silent-failure lens.
5. Test fixtures: per-test `mktemp -d` directories were moved under
   `$REPO_ROOT/.bats-tmp.*` so legitimate dry-run inputs canonicalize
   inside the repo boundary; teardowns rm -rf the fixtures. New
   regression coverage pins `resolves outside repository` for every
   path-argument family in single mode, batch mode, and companion
   launch/await; pins the "no filesystem state on rejection"
   contract for both the bare out-of-repo and the in-repo-broken-
   symlink-to-out-of-repo cases; and pins the corrupt-lib fail-closed
   sentinel.

## Deferrals respected

Per dispatch parameters, did NOT re-flag:
- `_resolve-lib.sh || true`
- batch `_path` no-WARN
- reviewer-protocol/emission-override silent-skip asymmetry
- `resolve_tier 2>/dev/null`
- per-agent launch-failure batch exit-0
