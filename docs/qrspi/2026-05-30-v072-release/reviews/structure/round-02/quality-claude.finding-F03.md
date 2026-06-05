---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 488-489
---
**Architectural Diagram contains a spurious `VF --> PR` cross-subgraph edge with no design basis**

The Mermaid diagram (line 488 of structure.md, outside all `subgraph` blocks) contains:

```
VF --> PR
```

`VF` is `scripts/verifier-fan-in.sh` (subgraph S11). `PR` is `scripts/round-prepare.sh` (subgraph S13).

No interface contract, design.md decision, or CD-4 §I.7 flow description establishes a direct script-to-script dependency from `verifier-fan-in.sh` to `round-prepare.sh`. The locked CD-4 sequence (design.md lines 399–491) shows fan-in output flowing to `<round-dir>/kept-findings.txt` → orchestrator → apply-fix. `round-prepare.sh`'s responsibility (Interface §2) is "canonicalize cumulative diff/ref selection and next-round narrowing inputs" — it takes a `<task-branch>` and `<round-NN>` as inputs, not a kept-findings artifact.

The edge implies `verifier-fan-in.sh` produces output that `round-prepare.sh` consumes, which is architecturally incorrect. A reader following the diagram would misunderstand the post-fan-in data flow.

**Fix:** Remove the `VF --> PR` edge. If the intent was to show the round-loop connection (fan-in completing → orchestrator advances to next round → round-prepare for next round), that cross-round relationship should be represented differently (e.g., an orchestrator node, or a comment, or removed entirely as implicit pipeline flow).
