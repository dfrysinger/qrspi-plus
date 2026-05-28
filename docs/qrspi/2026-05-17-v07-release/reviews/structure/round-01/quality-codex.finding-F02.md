---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L11-L28, docs/qrspi/2026-05-17-v07-release/design.md:L269-L300]
artifact: structure
round: 1
reviewer: quality-codex
---

The Structure file map for G5 covers routing decisions and citation-density validation, but it does not allocate any file/module or test to the production-tuning instrumentation that Design requires: capturing fix-cycle counts, review-finding categories, routing decisions, and citation-density rerun events. That leaves the routing matrix as a static initial decision rather than the "living config" Design specified, and downstream Plan has no concrete place to implement or verify the telemetry. Fix: add the instrumentation responsibility to the relevant dispatch consumer file(s) and add a test that verifies routing decisions plus fix-cycle/review-finding metrics are recorded per task.
