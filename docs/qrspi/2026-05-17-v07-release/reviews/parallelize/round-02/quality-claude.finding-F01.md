---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/parallelization.md:L63-L71]
artifact: parallelize
round: 2
reviewer: quality-claude
---

The same-wave file-disjointness audit section reports incorrect path-union counts for multiple waves. The counts claimed do not match the actual file-set sizes derivable from the Dependency Analysis table. Specific mismatches:

- **Wave 1** claims "union = 18 paths" but the Dependency Analysis table lists 23 distinct paths across the 12 Wave 1 tasks (T01: 1, T02: 1, T09: 1, T14: 1, T15: 3, T20: 2, T21: 2, T24: 1, T29: 2, T34: 4, T40: 3, T41: 2 = 23).
- **Wave 2** claims "union = 13 paths" but the table lists 14 distinct paths across the 9 Wave 2 tasks (T03: 1, T06: 3, T08: 1, T10: 4, T16: 1, T25: 1, T26: 1, T31: 1, T38: 1 = 14).
- **Wave 3** claims "union = 9 paths" but the table lists 8 distinct paths across the 4 Wave 3 tasks (T04: 2, T05: 2, T33: 2, T35: 2 = 8).
- **Wave 7** claims "union = 16 paths" but the table lists 21 distinct paths across the 10 Wave 7 tasks (T17: 1, T18: 1, T19: 2, T22: 3, T23: 2, T30: 5, T32: 2, T37: 1, T39: 2, T42: 2 = 21).

Waves 6 and 8 are correct (6 and 10 paths respectively). Wave 5 (2 paths) and Wave 4/9 (trivially satisfied) are not in dispute.

The wrong counts do not mask any actual intra-wave file overlap — the pairwise intersection = ∅ claim appears accurate when the actual file sets are inspected directly. However, the incorrect numeric assertions make the audit unreliable as a verification artifact: a reader relying on the stated count to spot-check the disjointness analysis will reach false conclusions, and a future automated validator that cross-checks this count against the Dependency Analysis table will fail. The counts should be corrected to match the Dependency Analysis table.
