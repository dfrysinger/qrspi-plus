---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 170-177,337-355
---
`structure.md`'s fan-in interfaces drift from the CD-4 locked contract in `design.md`:

1. **Interface §1** says `kept-findings.txt` is "newline-separated finding IDs" (lines 175–176), but CD-4 component D locks this as **one absolute finding-file path per line**.
2. **Interface §11**'s `.verifier-fan-in-audit.json` example uses `halts[].reason` and omits the locked `thresholds` object (lines 341–355), while CD-4 component E/I.1 lock `halts[].cause` semantics and threshold echo in the audit object.

This creates a structural contract mismatch for downstream Plan/Implement/test authoring. Update Interfaces §1 and §11 so they match CD-4's canonical fan-in outputs (`kept-findings.txt` path lines; audit object with threshold echo and halt-cause shape).
