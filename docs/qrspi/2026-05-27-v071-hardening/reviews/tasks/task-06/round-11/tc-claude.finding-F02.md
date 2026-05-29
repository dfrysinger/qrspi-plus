# tc-claude · Finding F02 · HIGH

## Title
TE1 positive copilot-cli emission test is environment-dependent: no isolated fixture proves the copilot-cli happy path

## Severity
**High** — the only tests asserting `output = "copilot-cli"` rely on the ambient host having `gh` installed at a trusted prefix. On a clean container, a minimal CI image, or a dev machine with `gh` absent, these tests emit `"claude-code"` and fail, leaving the copilot-cli happy path entirely unvalidated.

## Location
`tests/unit/test-host-detection.bats`  
- Line 149–160: `[host-detect] detect_host emits copilot-cli to stdout when COPILOT_CLI=1`
- Line 162–171: `[host-detect] detect_host exits 0 when COPILOT_CLI=1`
- Line 461–487: `[dispatch-surface] copilot-cli path emits [transport: task-tool] exactly once in stderr`
- Line 489–509: `[dispatch-surface] copilot-cli path does not emit [transport: shell-pipeline] in stderr`

## Description
All four tests that require the copilot-cli code path use `COPILOT_CLI=1` without controlling PATH or providing a fake `gh` binary at a trusted-prefix location. They depend on the ambient environment having `gh` at `/usr/bin/gh`, `/opt/.../gh`, or `/Applications/.../gh`. None of these are guaranteed in a minimal Docker container, a fresh developer machine, or any CI environment that does not pre-install `gh`.

The result is an implicit test skip disguised as a test pass: on environments without a trusted-prefix `gh`, these tests will silently fail (or will need to be re-understood as "expected failures").

This also means the critical three-condition guard in `detect_host`:
```bash
[[ "${COPILOT_CLI:-}" == "1" ]] && \
[[ -n "$_gh_path" ]] && \
[[ "$_gh_path" == /usr/* || "$_gh_path" == /opt/* || "$_gh_path" == /Applications/* ]]
```
has **no portable, self-contained test for the happy path** (all three conditions simultaneously true). A mutant that strips the second or third condition only collapses the copilot-cli path, and nothing in the suite would catch it on a minimal CI runner.

## Why a simple fixture is not straightforward
Writing to `/usr/bin`, `/opt/`, or `/Applications/` requires root. A standard test fixture cannot create a file there. Options:

1. **Test skip with `[ -z "$(command -v gh)" ] && skip "gh not installed"`** — makes the dependency explicit and prevents silent pass-on-empty.
2. **Separate integration-tier tag** — mark copilot-cli happy-path tests as `@integration` or `# bats test_tags=requires-gh` so they are only run in environments that satisfy the precondition, and the unit-tier always has an explicit skip rather than a surprise failure or surprise pass.
3. **Abstraction layer** — extract the prefix check into a helper function and test the helper with a fake path string directly (bypassing the filesystem), with a separate integration test for the full detect_host call.

## Impact
- A mutation that makes `detect_host` always return `"claude-code"` would be undetected in any CI environment without `gh`.
- The transport marker tests for the copilot-cli path (TE14) depend on the same environmental precondition, so transport-path distinguishability has no portable coverage.
