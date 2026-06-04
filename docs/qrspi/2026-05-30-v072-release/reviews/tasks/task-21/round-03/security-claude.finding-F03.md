---
finding_id: F03
reviewer: security-claude
severity: low
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:577-578, scripts/dispatch-agent.sh:688-691]
---
**Batch artifact guard conditioned on `-f` creates TOCTOU gap.** Guard at L577 skipped when file absent at check time; cat at L691 (re-tested) reads file if created in between. Fix: enforce boundary unconditionally when `BATCH_ARTIFACT_ABS` non-empty, separate from existence check. Convergent with sf-claude F01.
