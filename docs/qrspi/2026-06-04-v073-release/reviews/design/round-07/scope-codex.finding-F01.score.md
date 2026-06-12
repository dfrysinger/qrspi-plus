---
verifier_status: passed
score: 35
actual_model: unknown
defect_class: altitude-drift
---
Citations resolve to real ranges. L13-L55 spans CD-1 and CD-2, which name specific script paths (`scripts/upstream-paths.sh`, `scripts/review-prep.sh`, `scripts/dispatch-agent.sh` modes) and output-path conventions (`<artifact-dir>/reviews/<step>/round-NN.*`). L505-L563 covers G9 Pass 1's three-tier placement table.

Per `skills/design/owns-defers.md` → `_shared/design-altitude-boundary.md`: Design OWNS "Cross-Goal Decisions that establish vocabulary, named architectural components by purpose" but DEFERS "File architecture (which file holds which component, directory layout, module boundary lines)."

Evaluation: The R06 softening on G9 Pass 1 explicitly inserted the carve-out "the specific file paths in the 'Lives where' column are the established conventional locations and may be refined by Structure if needed (the tier identity is what Design fixes, not the literal path string)." That directly addresses the boundary concern on the L505-L563 range. For L13-L55, CD-1 and CD-2 use script names as component identifiers (named-by-purpose), which is on the OWNS side of the line — Design legitimately names the components whose orchestrator/structure contracts the CDs establish. The output-path patterns are framed as conventional path shapes consumed by callers, not as directory-layout commitments.

The finding does not identify which prose is drift beyond a general assertion, and does not engage with the R06 softening. The boundary concern is real-in-principle but largely mitigated; remaining instances (e.g., specific script filenames in CD names) are defensible as component-by-purpose naming under the OWNS list. Lower-moderate confidence; below the 50 keep threshold.
