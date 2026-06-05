---
finding_id: R5-F02
severity: low
change_type: clarity
referenced_files:
  - structure.md §11 (.verifier-fan-in-audit.json schema)
  - structure.md §17 (.orchestrator-fixes.json rescue audit schema)
  - design.md CD-4 §I.3 (Rescue audit file / schema authority cited by §17)
  - design.md CD-4 §C (verifier-fan-in.sh / implicit §11 schema authority)
---

§17 (added in R4) introduces a structured schema-documentation convention — explicit "Writer:", "Consumer:", and "Schema authority: design.md CD-4 §I.3" prose appended after the JSON example block — that its sibling interface section §11 (`.verifier-fan-in-audit.json`) does not follow. §17 even explicitly invites comparison by stating "Co-exists with §11 `.verifier-fan-in-audit.json` — separate writers, separate files, no merge semantics," yet §11 carries no "Schema authority" pointer, no "Writer:" attribution, and no "Consumer:" identification. The canonical schema definition for §11 is in design.md CD-4 §C (the `verifier-fan-in.sh` component specification), but structure.md provides no path to it — an implementer extending or reading §11's schema contract has no pointer to its design-time authority. R4 applied the more rigorous convention only to the new section, leaving the established section under-specified by comparison. The fix is to add a one-sentence schema-authority, writer, and consumer annotation to §11 following the §17 pattern, resolving the asymmetry. No functional behavior is affected; the risk is purely implementer-navigation confusion when the two sections are read as a pair.
