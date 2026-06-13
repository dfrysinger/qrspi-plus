---
finding_id: R6-F02
severity: medium
change_type: correctness
referenced_files: ["plan.md:L229-L241"]
artifact: plan
round: 6
reviewer: test-coverage-claude
---

T03 (`scripts/review-prep.sh`) test expectations are silent on the behavior when the round-anchor file `reviews/<step>/round-<NN-1>-commit.txt` is absent at round ≥ 2 (distinct from the SHA-format-invalid case which assumes the file exists). The parallel T26/T27 contract requires an `anchor-file-missing:` named diagnostic, but T03's own contract is unspecified. Fix: add one test expectation bullet covering anchor-file-absent at round ≥ 2.

