---
reviewer_tag: test-coverage-claude
round: 8
finding_id: R8-F01
severity: medium
change_type: scope
referenced_files: [scripts/run-codex-review.sh, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F01 — `_validate_output_dir` + `_validate_job_id` rejection paths untested

## Finding

AC10 and AC11 explicitly test rejection of injection-laden `--reviewer-tag` and `--model` inputs (non-zero exit, named flag in stderr, no manifest written). Two symmetric injection surfaces exist with NO analogous tests:

1. `_validate_output_dir` (scripts/run-codex-review.sh:200-227) restricts `$OUTPUT_DIR` to `^/[A-Za-z0-9_./:@-]+$`. `$OUTPUT_DIR` is embedded verbatim in `split_cmd` (line 403).
2. `_validate_job_id` restricts captured `$job_id` to `^[A-Za-z0-9_:@.-]+$`. `$job_id` is embedded in `await_cmd` (line 402).

Every mock dispatcher in the suite emits a well-formed `JOB_ID=test-job-...` value, so the job_id rejection path has never been exercised.

## Severity

MEDIUM: production code is correct; missing test would let a regression weakening either validator escape acceptance.

## Suggested test additions

(a) Crafted `--output-dir` with space or `"`: assert non-zero exit + stderr names `--output-dir` + no manifest.
(b) Mock dispatcher emitting `JOB_ID=evil"injected`: assert non-zero exit + stderr names `job_id` + no manifest with malformed entry.
