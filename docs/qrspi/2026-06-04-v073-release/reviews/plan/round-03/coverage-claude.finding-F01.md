---
reviewer: coverage-claude
finding_id: F01
artifact: plan.md
round: 3
severity: minor
change_type: behavioral
category: Error Conditions
task_refs: [T19]
---

## Finding

T19 (`scripts/orchestration-boundary-check.sh`) Description states the
script "accepts `--phase <implement|integration|test>`", and round 3
added per-phase fail-loud coverage for both branches (wave-1 sidecar
for `implement`, phase-base.txt for `integration`/`test`). However,
the unknown-`--phase` error path — raised as coverage-claude F02 in
round 02 — remains uncovered by any test expectation in this round
either.

A caller passing `--phase deploy` (or any value outside the closed
enumeration) currently has unspecified behaviour. Three observable
outcomes are all consistent with the current spec:

1. The script silently looks for `reviews/deploy/phase-base.txt`,
   doesn't find it, and surfaces a "missing phase-base.txt" Dispatch
   defect — wrong root cause (the real defect is "unknown phase"),
   wrong diagnostic name (`phase-base-missing:` instead of an
   unknown-phase token).
2. The script falls through to undefined behaviour (e.g., empty
   `<phase-base>` value passed to `git log` → reads entire history,
   floods report with false-positive entries).
3. The script loud-halts with some unspecified diagnostic.

Compare with T01, which explicitly tests:

  > Unknown step name returns the always-appended SKILL paths only
  > and exits 0 — no diagnostic on stderr (CD-1 Acceptance bullet 2
  > — fail-soft direction; matches structure.md row 17).

T19 has the analogous closed-enumeration flag (`--phase`) with the
analogous unknown-value case, but no analogous test expectation. The
round-03 changes added wave-1-sidecar coverage symmetric with
phase-base.txt coverage for the known-phase cases, but did not
address the unknown-phase fall-through.

## Test that cannot be written deterministically

"A caller passing `--phase <unknown-value>` (e.g., `--phase deploy`)
exits non-zero with diagnostic `<X>:` listing the valid phase values
(`implement`, `integration`, `test`); no `phase-base` read is attempted
under the bogus phase directory; no `git log` runs against an undefined
phase-base value" — neither the diagnostic token nor the halt direction
is specified.

## Recommended fix

Add one Test-expectation bullet to T19 covering the unknown-phase
fail-loud direction. Suggested:

> An unknown `--phase` value (e.g., `--phase deploy`) exits non-zero
> with the `obc-unknown-phase:` named diagnostic listing the valid
> phase values (`implement`, `integration`, `test`); no `phase-base`
> read is attempted under the bogus phase directory and no `git log`
> runs against an undefined phase-base value.

(Diagnostic name illustrative; the matching contract clause should
also land in the T19 Description so the fail-loud direction is the
spec, not implementation-defined.)
