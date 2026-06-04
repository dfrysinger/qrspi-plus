---
finding_id: R1-F02
reviewer_tag: silent-failure-codex
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F02 — Halt path leaves stale `kept-findings.txt` from prior successful run

Lines 263-269 halt path writes audit + exits 1 but does not remove/overwrite existing `kept-findings.txt`. If re-run in same round-dir after prior success, downstream consumers may consume stale file as if current.

Fix: on halt, unlink (or truncate-and-mark-invalid) the prior round's `kept-findings.txt` before exiting.

Note: closely related to T01 R3 sf finding about file-presence vs script-exit-success — same defect class.
