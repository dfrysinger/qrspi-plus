---
artifact: structure
severity: low
location: structure.md `## Architectural Diagram` → `subgraph hygiene` (Slice 4 cluster)
---

# Slice 4 cluster in the Architectural Diagram does not include the new test file row

## What

The R5 fix added a third row to the Slice 4 File Map for `tests/unit/test-parallelize-vocab.bats`, but the Slice 4 cluster in the Architectural Diagram still shows only two nodes (`PAR_SKILL` and `PAR_AGENT`) with a single `shape contract` edge between them. Every other slice in the artifact that touches a test file shows that test node in the diagram with a `behavior pinned by` / `asserted by` / `unit coverage` edge to the component it pins (Slice 1: `CTRL_CHK → TEST_LLM`; Slice 2: `GITIGNORE → COMMIT_TEST`; Slice 3: `HELPER → TEST_PATTERNS` + `HELPER → TEST_HELPERS`; Slice 8: `AGENTS → TEST_LINT`). Slice 4 is now the only slice in the artifact where a test file appears in the File Map but is absent from the Architectural Diagram.

## Why it matters

The diagram's stated purpose ("Modules are grouped by the three portability mechanisms … Arrows are runtime data-flow or dependency direction") and its de facto coverage pattern across all other slices is that the File Map and the diagram are kept in sync. The R5 fix correctly closed the design↔file-map gap that Codex R4 flagged, but it left a new structure-internal consistency gap: the diagram now under-represents the Slice 4 boundary by one node. Readers cross-referencing "what files does Slice 4 touch?" between the File Map and the diagram will get inconsistent answers. The omission is small (one node + one edge) and does not affect any other slice's correctness.

## Suggested fix

Add a single node + edge to the `subgraph hygiene` cluster mirroring the pattern used by Slices 1/2/3/8:

```mermaid
    PAR_TEST["test-parallelize-vocab.bats\nWave N rule pinned"]
    PAR_AGENT -->|"rule asserted by"| PAR_TEST
```

placed immediately after the existing `PAR_SKILL → PAR_AGENT` edge. No other diagram edits are required; Section Contracts already excludes modified files from heading-level re-assertion ("the existing top-level section structure is preserved by all Phase 1 edits"), so no Section Contracts update is needed for the new row.
