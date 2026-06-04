# Silent Failure Review — Round 5 — CLEAN

**Reviewer:** silent-failure-claude  
**Task:** Task 15 — G18 Plan cross-task consumer surface  
**Round:** 5  
**Artifact:** tests/integration/test-reference-gate-pause.bats  
**Scope hint:** tests/integration/test-reference-gate-pause.bats  

## Result: CLEAN

No silent failure findings in the R5 diff or the surrounding T15-authored G18 block.

## Verification of R5 Fixes

R5 closes F01 and F02 from R4 by adding `|| return 1` guards to the two
previously unguarded `section="$(extract_section …)"` assignments.

Scanning all `local section` + `section="$(extract_section …)"` patterns
in the G18 block (L408–644):

| Line  | Target file          | Guard present |
|-------|----------------------|---------------|
| L496–497 | `$PLAN_SKILL`     | ✅ Added by R5 |
| L565–566 | `$PLAN_REVIEWER_AGENT` | ✅ Pre-existing (prior round) |
| L619–620 | `$PLAN_REVIEWER_AGENT` | ✅ Added by R5 |

No other `section="$(extract_section …)"` assignments exist in the G18
block. The two R5 fixes are the last unguarded instances.

## Why the Guard Is Load-Bearing

`skill-markdown.bash` confirms: `extract_section` returns 1 with a loud
`skill-markdown:` stderr diagnostic on failure (unreadable file, anchor
not found, empty extract). In bash, `local section; section="$(cmd)"`
always returns 0 because `local`'s own exit code masks the subshell exit
code. Without the explicit `|| return 1`, a failing `extract_section`
would leave `$section` empty and all downstream string comparisons would
run against empty input — either passing vacuously or producing misleading
error messages with no indication the section extraction failed.

## `extract_and_grep` Direct Calls — No Issue

All single-line `extract_and_grep` calls in the G18 block propagate
failures correctly: the helper itself calls `extract_section` with
`|| return 1` (skill-markdown.bash L165), and direct calls in BATS (without
`run`) propagate non-zero exit codes to fail the enclosing `@test`.

## Pre-existing Advisory (Outside T15 Scope)

`extract_section` (skill-markdown.bash L93) uses a predictable
`/tmp/skill-md-extract-stderr-$$` temp path while `extract_section_fence_aware`
was already hardened to `mktemp` (noted as "sec.F01 fix"). This inconsistency
is pre-existing, not introduced by T15, and not a silent failure — it would
surface as a loud diagnostic, not a masked pass. No T15 action required.
