---
finding_id: R1-F02
severity: medium
change_type: test-coverage
referenced_files:
  - tests/unit/test-dispatch-sites.bats
  - tests/unit/test-third-party-finding-splitter.bats
reviewer: spec-claude
round: 1
---

## Companion/splitter fixture coverage missing "raw capture under `.dispatch/`" assertion

**What the spec requires (Test expectations bullet):**
> "Companion/splitter fixture coverage verifies `JOB_ID=<id>` launch output, payload-silent await behavior, **raw capture under `.dispatch/`**, stable `F01`, `F02`, ... materialization, `NO_FINDINGS` sentinel writing, and loud failure for missing flags/raw output/boundaries/write errors."

**What is implemented:**

The tests in `tests/unit/test-dispatch-sites.bats` for the companion await contract are:

```bats
@test "task-20 companion: dispatch-companion.sh await subcommand is recognised (no 'unrecognised subcommand')" {
  run scripts/dispatch-companion.sh await __NO_SUCH_JOB__
  [ "$status" -ne 127 ]
  ! [[ "$output" =~ "unrecognised subcommand" ]]
}
```

This test only verifies:
1. The `await` subcommand doesn't return exit 127 (command-not-found)  
2. The output doesn't contain the string "unrecognised subcommand"

Neither assertion verifies that `await <job-id>` writes raw reviewer output to `<round-dir>/.dispatch/<tag>.raw`. A successful `.raw`-write path is entirely untested.

**Missing test (required):**

A test that:
1. Creates a job record under `.dispatch/.jobs/<job-id>` with a valid vendor/model/prompt-file/tag/round-dir
2. Invokes `dispatch-companion.sh await <job-id>`
3. Asserts `.dispatch/<tag>.raw` was created (and optionally asserts no payload echo to stdout/stderr)

**Also unverified: positive JOB_ID assertion on launch**

The test "dispatch-companion.sh launch output contains only `JOB_ID=` (no payload echo)" negatively asserts no prompt-body sentinel appears in stdout — but does not positively assert `JOB_ID=` IS present on stdout. If the launch path fails silently (writes nothing to stdout), the negative assertion still passes. The spec test expectation reads "verifies `JOB_ID=<id>` launch output", implying a positive assertion.

**Note:** F02 is causally related to F01 (an await test would currently fail because the implementation is a stub), but is reported separately because the spec requires both a working implementation AND a test that verifies the behavior.
