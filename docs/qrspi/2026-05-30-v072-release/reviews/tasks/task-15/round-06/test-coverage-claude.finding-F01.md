---
id: F01
reviewer: test-coverage-claude
round: 6
file: tests/integration/test-reference-gate-pause.bats
line: 493
severity: low
change_type: clarity
status: accepted
---
The two consumer-surface worked-example tests are named "worked example A/B" (L493, L513) but the SKILL labels
those examples "Worked example C/D" (SKILL L675/L686); A/B in the SKILL are the SWEEP examples (L631/645).
The R6-added grep is section-scoped so it passes correctly, but the failure message "Worked example A must show
the public-symbol rename framing" would send a debugger to the wrong SKILL block.
Secondary (pre-existing, non-blocking) note: co_edit_count / no-change greps span the whole section.
ADJUDICATION: ACCEPTED — fix-cycle 6 renames A->C, B->D in the two test names/comments/failure messages (pure string).
Secondary whole-section-grep note: declined (same fragility rationale as tc-codex F01).
