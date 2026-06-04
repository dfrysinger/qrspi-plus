---
reviewer_tag: test-coverage-claude
round: 8
finding_id: R8-F02
severity: low
change_type: scope
referenced_files: [scripts/run-codex-review.sh, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F02 — "Dispatcher exits 0 but emits no JOB_ID" guard never triggered

## Finding

scripts/run-codex-review.sh:1019-1022 has an explicit fail-loud guard:

```bash
if [[ -z "$_job_id" ]]; then
  echo "error: dispatcher exited 0 but emitted no JOB_ID" >&2
  exit 1
fi
```

Every mock dispatcher in the test suite emits a JOB_ID unconditionally. The guard has never been exercised.

## Severity

LOW: production code correct; if removed by future refactor, no test would catch it.

## Suggested test

Mock dispatcher exits 0 writing only non-JOB_ID output. Assert: (a) exit code non-zero, (b) stderr contains "no JOB_ID", (c) manifest state per guard ordering at lines 1010-1022.
