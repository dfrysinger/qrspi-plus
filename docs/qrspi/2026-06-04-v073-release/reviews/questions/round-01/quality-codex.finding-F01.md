---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/questions.md:L11", "docs/qrspi/2026-06-04-v073-release/questions.md:L15", "docs/qrspi/2026-06-04-v073-release/questions.md:L23"]
artifact: questions
round: 1
reviewer: quality-codex
---

Goal leakage: several questions expose the intended build direction directly (for example Q5, Q9, and Q17 name the exact control/expansion we appear to want), so a researcher reading only this list can infer the project target rather than conduct neutral discovery. Rewrite these to preserve the investigation surface but remove release-intent signals and implied destination framing (ask only how current behavior/documentation works, not whether specific hard-rules are inline, whether a known mechanism exists, or how to reduce a named prompt footprint).
