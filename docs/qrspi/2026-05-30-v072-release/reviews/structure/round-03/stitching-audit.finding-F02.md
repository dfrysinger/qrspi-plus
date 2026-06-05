---
finding_id: R3-F02
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [70, 70]
---

# `config.md` Modify row missing CD-4 §I.4 halt-response config fields

## Gap description

The `config.md` Modify row in Slice 1.4 (structure.md line 70) carries the responsibility:

> "Surface `model_routing`, `trusted_path`, and validator blocks consumed by universal dispatch."

This covers the CD-1 config additions. But design.md CD-4 §I.4 (lines ~578–585) adds two
further config fields that are NOT covered by this row:

```yaml
orchestrator_rescue: false        # default; opt-in for silent orchestrator-driven fixes
max_drift_per_round: 3            # default; counts friction events
```

These fields are load-bearing for the halt-response protocol specified in CD-4 §I.3. Their
absence from the `config.md` row means:
1. The implementer working from the file map may not know `config.md` needs these additions.
2. No test row references these fields — the CD-4 §I.6 acceptance criteria require testing
   the full `orchestrator_rescue × interaction-mode` behavior matrix, and the missing
   config row is the structural gap that surfaces that test-coverage gap too.

## Downstream dead-end

CD-4 §I.3 specifies a three-tier rescue layer (mechanical fix, interpretive fix, subagent
re-dispatch) gated on `orchestrator_rescue`. Without the config field in the file map:

- The `using-qrspi/SKILL.md` and `implement/SKILL.md` prose that references
  `orchestrator_rescue` will refer to a config field that no implementer was told to add.
- The CD-4 §I.4 fields have no upstream creator in the phase — they are dead-end inputs.

## Producer/consumer chain broken

```
config.md (orchestrator_rescue, max_drift_per_round)  ← NOT in file map
    ↓ consumed by
halt-response protocol in using-qrspi/SKILL.md + implement/SKILL.md
    ↓ gated by
scripts/verifier-fan-in.sh halt-response dispatch
```

The `orchestrator_rescue` field is also read by `config-validation-procedure.md` consumers
(the validation procedure should validate the type/domain of the new fields), but the
validation row at Interface §4 (`validators:` block) only shows `change_type_enum` and
`finding_schema_required` — not the new CD-4 fields.

## Minimal-altitude fix

Extend the Slice 1.4 `config.md` Modify row responsibility to include: "Add
`orchestrator_rescue` (default: false) and `max_drift_per_round` (default: 3) config fields
per CD-4 §I.4 for the halt-response protocol."

Optionally: update Interface §4 to show the full config block including the CD-4 §I.4
additions alongside the CD-1 additions.
