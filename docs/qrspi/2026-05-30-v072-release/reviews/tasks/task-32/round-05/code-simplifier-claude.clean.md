# Code Simplifier — Clean

Task 32, round 5. Reviewed the diff against base for `skills/goals/SKILL.md`, `skills/design/SKILL.md`, and `tests/unit/test-interactive-skill-prompts.bats`.

No semantics-preserving simplifications to propose.

Notes on patterns considered and rejected:

- **Cross-skill prose duplication** (Incremental Persistence, Resume-after-compaction, Simulated-compaction durability, Finalize pass): ~80% identical text across the two SKILL.md files. The repo uses `!cat` shared-snippet includes elsewhere (e.g. `!cat skills/design/owns-defers.md` at design/SKILL.md:251), which would normally be a strong simplification candidate. Rejected because the new bats tests grep the SKILL.md files directly (not expanded output), so extraction would break the in-task test contract. Not semantics-preserving relative to the task's pinned tests.
- **Minor wording differences** between the two skills' parallel sections (`Per Dialogue Conduct Rule 8 above` vs `Per Rule 8 above`; trailing `transformation step` present in Design, absent in Goals): each variant reads cleanly in its local context. Aligning them would be cosmetic, not a complexity reduction.
- **Rule-numbering gap (1,2,3,4,6,7,8) in Goals Dialogue Conduct**: intentional and documented in the section's introductory paragraph to preserve number-parity with Design and signal the deliberate Rule-5 absence contract. Renumbering would erase load-bearing semantics.
- **Long parenthetical in the Subagent inputs bullet** (`(REQUIRED — ... MUST merge ...)`): the `MUST merge` phrase is a bats test anchor (`sf-F01`); keeping it inline preserves the contract-to-bullet attachment without adding indirection.
- **Bats test file**: each test pins a single contract with a single grep; names cite spec IDs (spec-F01, sf-F01, sf-F02). No dead assertions, no over-parameterization, no redundant intermediate variables.
