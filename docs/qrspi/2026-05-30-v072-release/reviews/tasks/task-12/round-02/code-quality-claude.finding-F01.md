---
finding_id: R2-F01
reviewer_tag: code-quality-claude
round: 2
task: 12
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-round-prepare.bats
---

**F01 — Stale source-line reference in backward-loop deletion-failure test comment.**

The new backward-loop deletion-failure test (`test-round-prepare.bats` lines 464–484, added in commit b3a74ee) contains a comment pointing at `round-prepare.sh:203-205` as the line range under test. Verify against the current `round-prepare.sh` — if the line range has drifted since the comment was written (e.g., due to other in-flight tasks editing `round-prepare.sh`), the reader will follow a dead pointer.

**Recommendation:** describe what's under test by name ("backward-loop flag deletion error path"), not by source-line number — line numbers in test comments drift silently as the script evolves.
