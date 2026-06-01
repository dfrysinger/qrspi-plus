---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - structure.md §17 (.orchestrator-fixes.json rescue audit schema)
  - structure.md ## Architectural Diagram / subgraph S12 (Slice 1.2 Calibration + instrumentation)
  - structure.md ## File Map / Slice 1.2 (using-qrspi/SKILL.md row)
  - design.md CD-4 §I.3 (Rescue audit file lock)
---

The R4 fix introduced §17, which declares `using-qrspi/SKILL.md` as the consumer of `.orchestrator-fixes.json` — the round-summary prose surface reads per-tier rescue counts from this file to populate `round-NN-dispositions.md`. However, the Architectural Diagram's S12 subgraph (Slice 1.2) was not updated to reflect this new data-flow dependency: `.orchestrator-fixes.json` is absent as a node, and no edge representing the rescue-layer → `.orchestrator-fixes.json` → `UQ[skills/using-qrspi/SKILL.md]` path exists in the diagram. This gap was explicitly flagged as a caveat in the R4 fix description ("§17 adds a new consumer dependency on using-qrspi/SKILL.md round-summary prose that is not yet wired into the Architectural Diagram's Slice 1.2 subgraph") but was not resolved by R4 — it was named, not fixed. The practical risk is that Plan/Implement engineers navigating the S12 subgraph as the primary structural reference for Slice 1.2 will not see the `.orchestrator-fixes.json` reader obligation for `using-qrspi/SKILL.md`'s round-summary prose surface, increasing the likelihood that the consumer-side implementation is omitted or treated as optional. The §17 prose is correctly specified; the fix is to add a `.orchestrator-fixes.json` node and a directed edge into `UQ` in the S12 subgraph.
