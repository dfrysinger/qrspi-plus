---
verifier_status: passed
score: 80
actual_model: unknown
defect_class: internal-contradiction
---

Cite Check: L396 contains the quoted "compares the full parent set, with no parent[0]-stripping normalization" sentence and describes the sidecar as storing "the full {integration-base, task-tips...} set" — a single combined set. L397 is the round-13-tightened step 3, which validates (a) `actual_parents[0] == captured_integration_base_sha` and (b) `set(actual_parents[1:]) == set(captured_task_tip_shas)`. L405's single-task edge-case bullet repeats "no parent[0]-stripping normalization."

Both quoted snippets verified verbatim. The contradiction is real and substantive: step 3 (b) by definition strips parent[0] (it slices `actual_parents[1:]`), and it reads `captured_integration_base_sha` and `captured_task_tip_shas` as two separately addressable fields, not a single combined set. The L396 prose and L405 edge case actively misdescribe the algorithm an implementer must build.

This isn't a stylistic nit — design.md is the artifact an implementer reads to write the validator and its capture-sidecar schema. The contradiction would lead an implementer either to (i) build a single-set sidecar that can't support invariant (a), or (ii) build a single set-equality validator that loses the first-parent ordering check that round 12 was specifically tightened to add. Either resolution silently negates round-12's correctness gain.

Score 80: real, locally verifiable, directly impacts implementer behavior, and is a regression introduced by round-13's incomplete edit (step 3 tightened, step 2 + edge-case prose left stale).
