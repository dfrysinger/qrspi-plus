---
finding_id: R3-F01
reviewer_tag: silent-failure-claude
round: 3
task: 01
severity: medium
change_type: correctness
referenced_files:
  - skills/_shared/verifier-filter-rule.md
---

## F01 — File presence check alone cannot distinguish complete output from partial-write / stale-file

Consumer obligation is keyed entirely on absent-vs-present. Two failure modes produce a file that exists but is not a valid current result:
- partial-write: script crashes mid-write; file exists but truncated
- stale file: prior round's `kept-findings.txt` remains when current script fails before touching file

The R2-F01 fix tightened absent-case handling but did not close present-but-wrong. Consumers have no instruction to check script exit code.

Proposed fix: require script exit-success check in addition to file presence, OR redirect to wherever exit-code handling is specified.
