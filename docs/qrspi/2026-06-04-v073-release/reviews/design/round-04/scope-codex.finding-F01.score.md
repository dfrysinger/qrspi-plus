---
verifier_status: passed
score: 25
actual_model: unknown
defect_class: altitude-mismatch
---

The finding asserts design.md drifts into Structure-owned file architecture by naming concrete script/agent/skill files (e.g. `scripts/upstream-paths.sh`, `scripts/review-prep.sh`, `agents/qrspi-finding-verifier.md`, `skills/implementer-protocol/SKILL.md`).

Checking against `skills/_shared/design-altitude-boundary.md`:

- Design OWNS "Cross-Goal Decisions (CDs) that establish vocabulary, named architectural components by purpose" — naming a new component `scripts/upstream-paths.sh` is on-altitude naming-by-purpose.
- Design OWNS "prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing)" — this inherently requires citing the SKILL/agent file the prose lands in, so the references to `agents/qrspi-finding-verifier.md § Rubric`, `skills/implementer-protocol/SKILL.md § Hygiene contract`, `skills/plan/SKILL.md`, etc., are required for the verbatim prose-design blocks to be actionable.
- Design DEFERS "which file holds which component, directory layout, module boundary lines" — there are a few mild instances (e.g., "Outputs are written to known relative paths under `<artifact-dir>/reviews/<step>/round-NN.*`", "`tests/lint/test-bats-test-name-id-hygiene.bats`"). But the design author already hedges where appropriate ("tests/lint/ or tests/unit/").

The bulk of the cited "file prescriptions" fall under OWNS (named components + prompt-prose edit sites), not DEFERS. The finding identifies a real but narrow tension and overgeneralizes it into broad boundary drift. A senior design reviewer would not require rewriting CD-1/CD-2/G1/G3 to scrub these names; doing so would strip out the vocabulary the CDs are built on.

Low-to-moderate confidence as a real issue worth action — score 25.
