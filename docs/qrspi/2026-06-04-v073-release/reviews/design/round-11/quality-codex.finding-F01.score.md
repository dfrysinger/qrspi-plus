---
verifier_status: passed
score: 75
actual_model: unknown
defect_class: internal-inconsistency
---

Cite Check: L391 contains the Outcome text "validated to equal the named task-tip SHA set at creation time" — confirmed verbatim. L396 capture procedure describes writing "full {integration-base, task-tips...} set" and comparing "the full parent set, with no parent[0]-stripping normalization". L405 edge case for single-task wave explicitly chooses "include the integration base in the expected set" for symmetry.

The contradiction is real: the Outcome describes the expected set as task-tips-only, while the Solution and edge-case discussion mandate the full set including integration-base. An implementer reading only the Outcome paragraph (a normal reading pattern for the "headline" summary of a goal) would implement task-tip-only comparison, which the L405 edge case explicitly says would fail on every `--no-ff` merge (actual parent[0] is always integration-base). This is a load-bearing internal inconsistency in a correctness-critical goal block. Cheap one-line fix.
