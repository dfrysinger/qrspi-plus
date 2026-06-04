# Spec Reviewer — Task 32, Round 5: CLEAN

The R5 increment (commit 6556574) adds an all-validations-passed gating clause
to the end-of-phase finalize pass in both `skills/design/SKILL.md` and
`skills/goals/SKILL.md`, with two new `bats` tests pinning the exact phrase
"Only flip status if all validations pass".

This is a strict tightening of behavior the task spec already requires
(Definition of Done: "Both skills define finalize validation and status
transition behavior exactly as scoped"; Test expectation: "Tests pin the
finalize pass: Goals validates … and flips … Design validates … and flips
…"). Gating the status flip on validation success is the natural reading of
"validates … and flips", prevents advancing a failing artifact through the
gate, and adds no surface area beyond the three Target files.

Verification:
- Completeness: finalize-pass behavior reinforced in both SKILLs; all
  R4-verified items remain intact in the diff.
- Scope: changes confined to the three Target files; no auxiliary files.
- Interpretation: "Only flip status if all validations pass" + halt /
  re-enter dialogue / "Do NOT advance the gate with a failing artifact"
  matches the spec's finalize-validation intent.
- Test coverage: two new tests grep a finalize-unique phrase in each SKILL.
- Extras: none.
- Target-files deviation: none.
