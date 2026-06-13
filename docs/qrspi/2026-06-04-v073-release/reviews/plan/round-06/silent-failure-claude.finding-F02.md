---
finding_id: R6-F02
severity: medium
change_type: correctness
referenced_files:
  - "docs/qrspi/2026-06-04-v073-release/plan.md:L1310-L1327"
artifact: plan
round: 6
reviewer: silent-failure-claude
---

T37 (`measure-active-footprint.sh`) test expectations omit `footprint-tokenizer-missing:` despite the Author Note confirming structure.md § Interfaces enumerates it as a contracted failure mode. An untested implementation might silently substitute a different tokenizer or produce a 0 token count, satisfying tests while producing a footprint report that falsely satisfies G9's "<30K tokens" acceptance criterion. Fix: add test expectation requiring `footprint-tokenizer-missing:` named diagnostic with non-zero exit and no report file when the pinned tokenizer is absent.

