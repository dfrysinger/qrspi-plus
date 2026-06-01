# stitching-audit.finding-F01

**reviewer_tag:** stitching-audit
**round:** 9
**artifact:** structure
**section:** ## File Map (Slice 1.2) + Mermaid diagram (subgraph S12)
**severity:** must-fix
**kind:** cross-section inconsistency

## Finding

The R8 fix corrected the Slice 1.2 file-map row to use the OLD/pre-rename filename
(`scripts/run-codex-review.sh`) and added the cross-slice rename note. However, the
Mermaid dependency diagram was **not updated** in parallel.

**Diagram line (structure.md ~line 517):**
```
subgraph S12[Slice 1.2 Calibration + instrumentation]
    DM[scripts/dispatch-agent.sh]          ← still NEW name
```

**File-map row (Slice 1.2, structure.md ~line 37):**
```
| `scripts/run-codex-review.sh` | Modify | … **Note:** this file is renamed to
  `scripts/dispatch-agent.sh` in Slice 1.4 …
```

The two representations are now inconsistent: the table correctly identifies the Slice 1.2
target as `run-codex-review.sh`, but the diagram node still labels it `dispatch-agent.sh`
(the post-rename name that the file doesn't have until Slice 1.4 lands).

Note: `subgraph S14` correctly labels its node `DAg[scripts/dispatch-agent.sh]` for the
Slice 1.4 rename row. S12 and S14 now represent different points in the file's lifecycle
but the diagram collapses them to the same label, making it appear as though Slice 1.2
modifies a file that doesn't yet exist by that name.

## Required fix

Change the S12 diagram node label from `scripts/dispatch-agent.sh` to
`scripts/run-codex-review.sh` to match the corrected file-map row:

```
DM[scripts/run-codex-review.sh]
```

Optionally add a note edge or annotation indicating it is renamed in S14, mirroring
the cross-slice note in the file-map table.
