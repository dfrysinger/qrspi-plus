---
verifier_status: passed
score: 30
actual_model: unknown
defect_class: altitude-mismatch
---

The finding cites real prose in the artifact — design.md does name specific script paths (`scripts/upstream-paths.sh`, `scripts/review-prep.sh`, `scripts/orchestration-boundary-check.sh`), specific shared snippet directories (`skills/_shared/`), specific lint-test paths (`tests/lint/test-bats-test-name-id-hygiene.bats`), and per-skill references subdirectories. So the citations are accurate.

However, the OWNS/DEFERS contract is fuzzy on this exact boundary. Design OWNS "Cross-Goal Decisions (CDs) that establish vocabulary, named architectural components by purpose" and explicitly admits acceptance-criteria-altitude shapes like "one bats file per script under `scripts/`" as OWNED. Naming a CD as "`scripts/upstream-paths.sh` extraction" is component-naming, not file-architecture authoring; the convention `scripts/<name>.sh` is a project-wide given, not a Structure-altitude module-boundary decision.

The finding asserts a sweeping violation without isolating any single passage where the design crosses cleanly from "named component by purpose" into "module boundary line that Structure should author." The G9 three-tier placement table (lines 507-513) is the strongest candidate (it does prescribe placement across `using-qrspi`, `_shared/`, per-skill body, and `references/`), but that placement is the load-bearing decision content of G9 itself — moving it to Structure would gut G9's outcome. The other examples cited (CD-1, CD-2, G3, G5, G9 acceptance) are within established design-altitude norms in this repo.

Real boundary tension exists, but the finding is broad, doesn't isolate the strongest specific example, and largely targets prose that fits the OWNS column. Round-5 design after multiple prior review passes raises the bar for sweeping scope claims. Drop.
