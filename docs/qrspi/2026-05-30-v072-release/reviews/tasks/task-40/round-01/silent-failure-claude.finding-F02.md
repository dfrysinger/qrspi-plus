---
reviewer: silent-failure-claude
task: 40
round: 1
finding: F02
severity: low
category: silent-suppression / under-reporting
file: tests/lint/test-bats-body-assertion-guard.bats
lines: 110-118
---

# F02 — BW02 walker silently suppresses all but the first violation per file

## What

The G26/BW02 awk pass uses a `flagged` latch to print at most one
diagnostic per file:

```awk
FNR == 1 { has_guard = 0; flagged = 0 }
/bats_require_minimum_version/ { has_guard = 1 }
/run --separate-stderr/ && !has_guard && !flagged {
  printf "%s:%d: BW02: feature \"run --separate-stderr\" ...\n",
         FILENAME, FNR
  flagged = 1
}
```

The inline comment explicitly documents this behaviour ("emit a diagnostic
and set flagged=1 so we report each file at most once"), so it is
intentional — but it is in tension with the G21 sibling rule (which prints
**every** unguarded hit) and with the file's own header docstring
("Diagnostic: file:line + triggering feature name for **every** violation")
and the task DoD wording ("BW02 violations report both the triggering
feature and `file:line`", in the same shape as the per-violation G21 rule).

## Why this matters

If a single file accumulates multiple `run --separate-stderr` call sites
without a `bats_require_minimum_version` declaration, the developer fixes
the first one, re-runs, sees green on that line, and may believe the file
is clean. The second / third call site is silently invisible to the lint
until the first is removed. For a "fail loudly" gate (the explicit
G21/G26 design intent), per-file deduplication is a silent under-report.

The per-file count is small today, so blast radius is low; flagging as
**low severity** rather than medium.

## Suggested resolution

Either:

- Drop the `flagged` latch so BW02 reports every occurrence (matches G21
  shape and the header docstring "for every violation"); or
- Adjust the header docstring + DoD wording to acknowledge per-file
  reporting, so the diagnostic contract matches the implementation.

The first option costs nothing and removes the silent-suppression
surface.
