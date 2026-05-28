---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L61-L65, skills/phasing/owns-defers.md:L14-L18]
artifact: phasing
round: 4
reviewer: scope-codex
---

The Slice 1 replan gate crosses from phasing criteria into design/interface and implementation detail. Phasing owns slice/phase grouping and replan-gate criteria, but the OWNS/DEFERS rule explicitly defers architecture, interface contracts, and implementation prose to later artifacts. The bullets require the universal dispatcher to work across specific transports, require no per-call-site special-casing, name the `model_routing:` key, and specify dispatch instrumentation details. Those are valid downstream design/structure/implement constraints, but they are too specific for phasing.md.

Fix: keep the replan gate at the observable slice boundary, such as "a configured routing site dispatches through the universal dispatcher to the cheap provider and records enough telemetry to compare cost," and move the transport/key/special-casing details to the artifact that owns those contracts.
