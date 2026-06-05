---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 651-651
---
**Hook-Point Locations §G34 cites wrong design section: "design.md CD-4 §D1" should be "design.md G34 §D1"**

Structure.md line 651 reads:

> `skills/_shared/design-altitude-boundary.md` is `!cat`-included in two consumer files **per design.md CD-4 §D1**:

`CD-4 §D1` is the design section for the Verifier-Fan-In Pipeline's `--verifier-fanout` extension to `dispatch-agent.sh`. It has no relationship to the design-altitude-boundary snippet. The correct authority is **`design.md G34 §D1`** — the decision node that establishes the Candidate-B (`!cat` single shared snippet into both consumers) pattern for `skills/_shared/design-altitude-boundary.md` (design.md lines 2895–2895, heading "D1 — Adopt Candidate B").

The sibling G35 entry on line 660 correctly cites "per design.md G35 §D1" — the G34 entry is inconsistently and incorrectly cross-referenced.

**Impact:** A Plan author or reviewer consulting the cited "CD-4 §D1" will read the verifier dispatch flag specification and find no authority for the design-altitude-boundary `!cat` pattern. The correct source (G34 §D1, lines 2895–2923) and its hard dependency statement ("Hard dependency on G32") are invisible from this incorrect citation.

**Fix:** Change line 651 from `per design.md CD-4 §D1` to `per design.md G34 §D1`.
