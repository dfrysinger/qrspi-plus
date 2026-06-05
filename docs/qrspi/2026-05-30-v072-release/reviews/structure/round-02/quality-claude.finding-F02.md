---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 337-355
---
**Interface §11 `.verifier-fan-in-audit.json` schema diverges from the locked shape in design.md CD-4 §E**

Structure.md Interface §11 (lines 341–354) defines:

```json
{
  "round_dir": "reviews/plan/round-01",
  "scored": 6,
  "failed": 1,
  "dropped": 2,
  "kept": 4,
  "halts": [...]
}
```

Design.md CD-4 §E (lines 444–453) gives the **locked** shape:

```json
{
  "scored": 12,
  "kept": 4,
  "dropped": 8,
  "halts": [],
  "thresholds": { "style": 80, "clarity": 80, "correctness": 70 }
}
```

Three discrepancies:

| Discrepancy | Structure §11 | Design CD-4 §E | Direction |
|---|---|---|---|
| `round_dir` field | present | absent | extra in structure |
| `failed` field | present | absent | extra in structure |
| `thresholds` field | absent | **present and locked** | missing from structure |

The `thresholds` field is the most significant: CD-4 §C step 4 explicitly requires "counts + **threshold echo**" in the audit file, and CD-4 §E locks the field name and per-enum values. Omitting `thresholds` from Interface §11 means Plan tasks implementing `scripts/verifier-fan-in.sh` have contradictory schema authority — structure.md says three fields are excluded/added versus the design-locked contract.

**Fix:** Update Interface §11's JSON example to match CD-4 §E exactly: remove `round_dir` and `failed`, add `thresholds: { "style": 80, "clarity": 80, "correctness": 70 }`. If `round_dir` is an intentional addition not in CD-4 §E, the design authority must be cited; otherwise it is unsanctioned schema extension.
