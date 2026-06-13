---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: ["plan.md:L877-L885"]
artifact: plan
round: 6
reviewer: test-coverage-claude
---

T37 (`scripts/measure-active-footprint.sh`) test expectations omit two of the four named diagnostics that structure.md § Interfaces contracts for this script: `footprint-tokenizer-missing:` and `footprint-skill-not-found:`. The Author Note cites structure.md but tests cover only `footprint-snippet-unresolvable:` and `footprint-snippet-cycle:`. An implementation that silently exits 0 with a zero-token count when the tokenizer is missing would pass all stated tests yet falsely satisfy G9 Acceptance bullet 7. Fix: add two test expectation bullets covering tokenizer-absent and top-level-skill-missing cases.

