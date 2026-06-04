---
finding_id: R3-F01
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-verifier-fan-in-script.bats
reviewer_tag: code-quality-claude
round: 3
task: 02
---

Test naming convention drift: R2 tests use `"R2 fix N: <desc>"` while R1 tests use `"fix FNN: <desc>"`. R2 ordinals (1, 2, 3) are ephemeral and carry no stable identity. R1 prefix at least cross-references stable finding IDs.

**Fix:** Drop the `R2 fix N:` prefix; let the behavioral suffix stand alone (e.g., `"score with > 3 digits is rejected as score_unparseable"`). The section header comment `# Round-02 review fixes` already provides organisational grouping.

Locations (5 tests): lines 402, 417, 429, 445, 457.
