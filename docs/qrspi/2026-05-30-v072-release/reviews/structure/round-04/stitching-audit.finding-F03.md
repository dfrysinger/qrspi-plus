---
finding_id: R4-F03
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [234, 235]
---

# `.orchestrator-fixes.json` rescue audit file has no interface contract in structure despite design.md locking its schema

## Gap description

R3 added `orchestrator_rescue` and `max_drift_per_round` to Interface §4 (structure.md
lines 234–235), bringing CD-4 §I.3's halt-response protocol into structure scope. Design.md
CD-4 §I.3 defines a companion artifact produced by the rescue protocol:

> "Rescue audit file (`<round-dir>/.orchestrator-fixes.json`). All rescue events (every
> tier) are logged to this JSON file. **Schema:** JSON object `{rescue_events: [{finding_id,
> cause, tier, original_value, fixed_value, fix_method, citation?, tier_outcome}, ...]}` where
> `tier_outcome ∈ {applied, failed}`. **Consumer:** orchestrator-side round-summary prose
> surface (see below)."
> — design.md CD-4 §I.3 (line 539)

Structure.md contracts the sibling audit file `.verifier-fan-in-audit.json` in **Interface
§11** (lines 352–368) with a full JSON schema block. But `.orchestrator-fixes.json`, which
has an equally locked schema in design.md and a named consumer (the round-summary surface
in `reviews/{step}/round-NN-dispositions.md`), has no corresponding interface contract in
structure.md. No Interface section names it. No file-map row includes it. No side-effect
note in §3, §14, or §15 references it.

The R3 fix that added `orchestrator_rescue` to §4 brought the rescue protocol into
structure but did not bring the rescue file it produces.

## Authority (cite design.md section)

design.md CD-4 §I.3 (lines 539–541):
- Defines `.orchestrator-fixes.json` writer (orchestrator rescue tiers), schema
  (`rescue_events` array with fields: finding_id, cause, tier, original_value, fixed_value,
  fix_method, citation?, tier_outcome), consumer (orchestrator-side round-summary prose
  surface writing to `reviews/{step}/round-NN-dispositions.md`), and co-existence semantics
  ("the rescue file and `.verifier-fan-in-audit.json` are separate files with separate writers").

design.md CD-4 §I.5 (line 587): "All rescue events (every tier) are logged to this JSON
file" — rescue file is mandatory, not optional.

## Impact on implementation

Plan implementers working from structure.md will not know:
1. That `.orchestrator-fixes.json` must exist at `<round-dir>/` after any rescue event.
2. What fields the schema requires (the design.md `rescue_events` array shape).
3. That the writer is the orchestrator, not a script.
4. That the consumer is the round-summary dispositions file.

Without a structure-level interface, implementations of `using-qrspi/SKILL.md`'s rescue
behavior will likely omit or invent a different schema for this file, breaking the audit
trail that design.md requires for post-hoc inspection of rescue actions.

Compare: `§11` for `.verifier-fan-in-audit.json` gives implementers the exact schema they
need. The rescue file deserves the same treatment because it has the same design-time
commitment.

## Fix (Structure-altitude only)

Add **Interface §17** — `.orchestrator-fixes.json` rescue audit schema — between the
existing §16 and the `## Architectural Diagram` section. Structure-altitude form (schema
only; no prose content):

```json
{
  "rescue_events": [
    {
      "finding_id": "R1-F03",
      "cause": "missing_change_type",
      "tier": 1,
      "original_value": "category",
      "fixed_value": "change_type",
      "fix_method": "frontmatter-key-rename",
      "citation": null,
      "tier_outcome": "applied"
    }
  ]
}
```

Writer: orchestrator rescue layer (after each tier 1/2/3 fix attempt, including failed
attempts). Path: `<round-dir>/.orchestrator-fixes.json`. Consumer: `using-qrspi/SKILL.md`
round-summary prose surface (sources per-tier counts for `round-NN-dispositions.md`).
Co-exists with `§11` `.verifier-fan-in-audit.json` — separate writers, separate files.

Also update the Section Contracts cross-reference list preamble (line 634) to note
`<round-dir>/.orchestrator-fixes.json` → §17.
