# Structure round-8 dispositions

3 of 4 reviewers clean. 1 finding applied.

## Applied (2)

- **scope-codex R8-F01** (medium, scope; verified 85) — Internal inconsistency in `tests/helpers/skill-markdown.bash` interface section (line 242). The section said "Behavioral surface; exact function names land in Plan/Implement" but then defined exact function names and parameter shapes (`extract_section`, `extract_and_grep`, `assert_section_contains`, `require_repo_root`). Per Structure OWNS ("Function/script exports and parameter shapes"), Structure owns these. Replaced the deferral sentence with: "Function names and parameter shapes are Structure-owned per OWNS 'Function/script exports and parameter shapes'; bodies are Plan/Implement."

- **quality-claude R8-F01** (low, correctness; verifier-skipped — obvious half-fix from R7) — The R7-F01 fix dropped the `G14` tag from `test-wave-context-shape.bats` in the Slice 5 file map, but the diagram's `G14Consumers` node string still listed it. Removed the file from the diagram node string (kept the other 6 actual G14 consumers).

## Clean reviewers (2)

- scope-claude (round-08): clean.
- quality-codex (round-08): clean.

## Notes

- Convergence trend: R1=5/5, R2=4/5, R3=1/1, R4=1/2, R5=1/2, R6=1/1, R7=2/2, R8=2/2.
- Round 9 expectation: full convergence (4-clean).
