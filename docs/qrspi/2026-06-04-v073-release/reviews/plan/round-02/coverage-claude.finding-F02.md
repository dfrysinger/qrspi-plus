---
reviewer: coverage-claude
finding_id: F02
artifact: plan.md
round: 2
severity: minor
change_type: behavioral
category: Error Conditions
task_refs: [T19]
---

## Finding

T19 (`scripts/orchestration-boundary-check.sh`) Description states the
script "accepts `--phase <implement|integration|test> --artifact-dir
<path>`," but the Test expectations do not cover the unknown-phase
error path.

The script reads `<phase-base>` from a per-phase location keyed on the
`--phase` value (implement→wave-state sidecar, integration→`reviews/
integration/phase-base.txt`, test→`reviews/test/phase-base.txt`). A
caller passing `--phase deploy` would either silently look for a
non-existent `reviews/deploy/phase-base.txt` and surface it as
a generic "missing phase-base.txt" Dispatch defect (wrong root cause),
or fall through to undefined behavior — neither is explicitly governed.

Compare with T01, which explicitly tests:

  > Unknown step name exits non-zero with the
  > `upstream-paths-unknown-step:` named diagnostic listing valid step
  > values; stdout is empty (CD-1 Acceptance bullet 2 — fail-loud
  > direction).

T19 has the analogous flag (`--phase`) with the analogous closed
enumeration but no analogous test expectation.

## Test that cannot be written deterministically

"A caller passing `--phase <unknown-value>` (e.g., `--phase deploy`)
exits non-zero with diagnostic `<X>:` listing the valid phase values;
no `phase-base.txt` lookup is attempted under the bogus phase
directory" — neither the diagnostic token nor the halt direction is
specified.

## Recommended fix

Add one Test-expectation bullet to T19 mirroring T01's fail-loud
unknown-step bullet. Suggested:

> An unknown `--phase` value (e.g., `--phase deploy`) exits non-zero
> with the `obc-unknown-phase:` named diagnostic listing the valid
> phase values (`implement`, `integration`, `test`); no `phase-base`
> read is attempted under the bogus phase directory.

(Diagnostic name illustrative.)
