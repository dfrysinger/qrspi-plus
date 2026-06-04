---
finding_id: R1-F01
reviewer_tag: code-quality-codex
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
  - skills/_shared/verifier-dispatch-prose.md
  - tests/unit/test-verifier-dispatch-prose.bats
  - tests/unit/test-verifier-fan-in-script.bats
---

## F01 — QRSPI-internal IDs (G12, CD-4, R1-F01) on code/test/comment surfaces

ID hygiene rule disallows QRSPI tracker tokens outside `docs/qrspi/`. Examples:
- `scripts/verifier-fan-in.sh:2,24,30` — `G12`, `CD-4`
- `skills/_shared/verifier-dispatch-prose.md:5,6,9,17` — `CD-4`, `CD-1`
- `tests/unit/test-verifier-dispatch-prose.bats:4,32` — `CD-4`
- `tests/unit/test-verifier-fan-in-script.bats:3,88-90` — `CD-4`, run-style tokens

Fix: replace with plain descriptive wording / neutral fixture IDs.
