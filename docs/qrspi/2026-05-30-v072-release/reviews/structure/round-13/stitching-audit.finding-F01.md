---
finding_id: R13-F01
reviewer_tag: stitching-audit
reviewer: stitching-audit
round: 13
artifact: structure
section: "Check 6 — Test block test-detail removed"
severity: medium
kind: correctness
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:L1793-L1796
---

## Finding

Check 6 FAIL. The `tests/unit/test-second-reviewer-available.bats` block is not behavior-only: line 1795 still carries the literal stderr token string ``[second-reviewer-unavailable]``. The block no longer contains executable `bash scripts/...`, `echo $?`, numeric exit-code, or mutation-fixture wording, but this stderr-token survivor violates the R12 test-detail collapse requirement.

## Required fix

Rewrite the line 1795 bullet to behavior-level wording only, e.g. "Pins that unsupported hosts fail loudly with an unavailable-host diagnostic." Do not include executable commands, exit-code numbers, literal stderr tokens, or fixture-proof wording in this per-file test block.
