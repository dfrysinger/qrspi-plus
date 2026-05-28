---
finding_id: R8-F03
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1060]
artifact: design
round: 8
reviewer: quality-claude
---

The system-diagram Mermaid block ends with the edge:

```
BatsBackstop --> CI
```

This reads as "BATS backstop flows into / depends on CI," but the actual relationship (per Decision 8 lines 969–973 and the G18 design body lines 849, 873) is the inverse: CI (G17) provides the runtime that hosts the BATS backstop. G18's BATS pin "depends on G17's CI workflow being present (otherwise the pin has no automatic place to run)."

Arrow direction in Mermaid flowcharts conventionally points to the dependency target / downstream consumer. The current arrow says BatsBackstop produces CI; the prose says CI hosts BatsBackstop. A downstream reader trying to reconcile the diagram against the prose will hesitate.

Recommend either reversing the arrow to `CI --> BatsBackstop` (CI provides the runtime; BATS backstop is hosted on it), or relabeling the edge with `|hosted on|` if the original orientation is intentional. The fix is one character but it removes a small reader-friction that the rest of the diagram does not have.
