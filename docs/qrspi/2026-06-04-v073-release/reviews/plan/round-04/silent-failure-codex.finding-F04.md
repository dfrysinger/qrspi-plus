---
finding_id: R4-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L203-L210
artifact: plan
round: 4
reviewer: silent-failure-codex
---

Swallowed malformed-input behavior in T02 marker parsing. T02 silently ignores non-enumerated absorption-marker shapes instead of surfacing an error from the parser itself. That can produce incomplete absorption maps while appearing successful (`exit 0`), and downstream consumers can't distinguish "no markers" from "unrecognized marker drift" unless separate lint happened to run.
