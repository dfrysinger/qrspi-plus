---
verifier_status: passed
score: 70
actual_model: unknown
defect_class: altitude-drift
---

Cite Check: design.md exists; G9 § Pass 1 contains a "Three-tier content placement" table that explicitly assigns content types to named file locations including `using-qrspi/SKILL.md`, `skills/_shared/<topic>.md`, and `skills/<name>/references/<topic>.md` (design.md lines 507-513). The matrix matches the finding's quoted characterization verbatim. Pass 2 (lines 515-527) additionally enumerates concrete script file names that own specific responsibilities.

Substance: skills/_shared/design-altitude-boundary.md DEFERS list explicitly assigns "File architecture (which file holds which component, directory layout, module boundary lines)" to Structure. The G9 placement matrix is exactly that: a mapping of content categories → concrete file paths / directory layouts. This is a real altitude-drift finding aligned with the locked OWNS/DEFERS contract the scope-reviewer is dispatched against.

Caveats keeping score below 75: the design could plausibly defend the matrix as outcome-level intent (separating universal vs. shared vs. skill-specific vs. on-demand content) rather than file-architecture per se — the named paths arguably illustrate the separation rather than fix it. Structure could refine the exact paths. But naming specific files (`using-qrspi/SKILL.md`, `_shared/<topic>.md`, `references/<topic>.md`) and tying acceptance to those paths crosses the line into file architecture. Reasonable senior reviewer would flag this.
