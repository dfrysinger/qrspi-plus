---
finding_id: R1-F03
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:L423-L432]
artifact: design
round: 1
reviewer: scope-claude
---

The CD-4 section ("Verifier-Fan-In Pipeline"), component E at lines 423–432 provides a complete field-level JSON schema for `.verifier-fan-in-audit.json` — a fenced JSON literal with specific key names (`scored`, `kept`, `dropped`, `halts`, `thresholds`) and concrete threshold values (`{ "style": 80, "clarity": 80, "correctness": 70 }`). The Design DEFERS rule calls out "field-level schema layouts (JSON keys, table columns, struct fields)" as Structure/Plan/Implement territory. The design's own Sub-Rule A reinforces this: data-contract artifacts are specified at Design phase by name + purpose + necessary fields; the schema layout belongs downstream.

Additionally, the concrete threshold values (80/80/70) committed here are simultaneously asserted elsewhere in the design as "Plan task authors lock the full per-enum table" (line 417) — the JSON example pre-empts the Plan-time lock that the design itself defers. This creates a mild consistency risk: if Plan authors assign different floor values, the design's embedded JSON becomes incorrect.

The Design-appropriate treatment is to describe the audit file's purpose and its required high-level fields in prose: "Audit JSON records scored/kept/dropped counts, the threshold values applied keyed by change_type, and any halt entries." Retain the file-path identity and purpose already stated in component E; remove the fenced JSON literal.

To resolve: replace the fenced JSON block at lines 424–432 with a prose description of the file's necessary fields, deferring concrete threshold values and key names to the Plan task spec or a dedicated structure artifact.
