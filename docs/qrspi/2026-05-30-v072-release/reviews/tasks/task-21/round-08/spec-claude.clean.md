# spec-claude — Task 21, round 8 — CLEAN

Cumulative diff (task-base 85a18f9 → fix-cycle-8 514a6cd) reviewed against
task-21.md spec. All R7 fix-cycle remediations land cleanly and no new
spec-completeness, scope, or interpretation defects are visible.

## Completeness

- Single fail-closed `assert_path_under_repo_root` guard sourced from
  `scripts/lib/path-guard.sh` (spec line 24).
- Guard applied to every prompt-ingested path family in single mode:
  `--subject-code` / PRIMARY_PATHS (dispatch-agent.sh L980), `--task-def`
  (L988), `--companion` (L997), `--diff-file` (L259-L266); plus
  batch-mode `--artifact` (L120) and `--agents` agent file (L147), and
  skill paths discovered via agent frontmatter (L972) (spec lines 25, 42).
- Existence check precedes boundary check; boundary check precedes any
  `cat`/prompt emission (spec line 43).
- `agents/qrspi-implementer.md` carries the top-of-body
  `## Orchestrator-Only Scripts (Bash Allowlist)` section with both
  post-rename names and all four forbidden invocation shapes
  (relative / absolute / alias / shell-expansion) (spec line 44).
- `scripts/dispatch-companion.sh` audited: shares the guard on
  `launch:--prompt-file` and `--round-dir`, with documented stdin-only
  rationale comment for the legacy `--provider`/`--artifact-dir` form
  (spec line 45). The two-stage `--round-dir` guard
  (pre-mkdir ancestor + post-mkdir canonical) closes the partial-state
  regression that R7 surfaced.

## Test coverage

All eight test expectations (spec lines 49-56) have matching tests in
`tests/unit/test-dispatch-agent.bats`:

- `/etc/hosts` rejection with `resolves outside repository`.
- Symlink-out-of-repo rejection plus pre-emission proof
  (`<<<AGENT-BODY-END>>>` and `<<<UNTRUSTED-ARTIFACT-START` absent).
- Readable out-of-repo `--companion` boundary rejection (with explicit
  `[ -r ... ]` sanity assertion proving it isn't a missing-file effect).
- All four flag families pinned (`--subject-code`, `--artifact-body`,
  `--companion`, `--diff-file`) plus batch-mode parallels.
- Valid repo-local dry-run pass cases for each.
- Canonicalization-failure case using `QRSPI_REPO_ROOT=/no/such/...`
  with a sentinel-not-emitted proof confirming no read happens before
  the boundary check.
- Structural grep for the implementer allowlist section.
- Audit grep for `dispatch-companion.sh` guard / no-raw-path comment.

## R7 fix-cycle disposition (verified)

- sec-claude R7 F02: `FORBIDDEN_MARKERS` array (5 sentinels) + 3 new
  marker-injection regression tests at the scope-hint and `--field`
  surfaces.
- sf-claude R7 F02: inline regex grammar check at the orphan-broker
  site with WARN + `emit_dispatch_manifest_entry "" "failed"` +
  `continue`, replacing the prior `_validate_job_id` hard exit that
  would have orphaned an upstream broker job.
- cq-claude R7 F01: `path-guard.sh` header documents both public
  functions and the `_qrspi_canonicalize` helper.
- cq-claude R7 F02: defense-in-depth `command -v` guards for both
  `assert_path_under_repo_root` and `assert_ancestor_under_repo_root`
  after sourcing in both dispatch scripts; fail-loud behavior pinned by
  bats test against an empty `path-guard.sh`.
- cq-claude R7 F03: residual T-IDs stripped from comments
  (`T04` → "earlier shim refactor", `T09 R2 fix` → "Allowlist
  validation", `R5 F04:` heading removed).
- cq-claude R7 F04: companion await tag-validation hard-exit changed
  from `exit 13` to `exit 1`.

## Scope and target-files deviation

The new `scripts/lib/path-guard.sh` shared module is not in the spec's
Target files list (spec line 13). The dispatch context confirms this is
a deferred amendment (sec-codex/spec-codex tracked in v0.7.3 deferrals),
so no new flag is raised.

The added tag allowlist regexes (batch `--agents` tag, companion
launch `--tag`, companion await `_job_tag` re-validation) trace to the
"every prompt-ingested file path" requirement (spec line 24) because
those tags become components of the assembled prompt-file path; pinned
by tests in the round-08 diff at the path-traversal-tag and
crafted-job-record cases. Not over-engineering.

## TDD evidence

87/87 bats green per dispatch context. The tests in the diff include
sentinel-not-emitted, pre-emission-marker-absent, and grammar-rejection
assertions, not just bare exit-status checks — substantive behavioral
coverage.

## Verdict

CLEAN — gate passes; downstream reviewers may proceed.
