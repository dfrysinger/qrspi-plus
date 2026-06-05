---
finding_id: R3-F03
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [12, 28]
---

# No test file row covers CD-4 §I halt-response protocol acceptance criteria

## Gap description

Design.md CD-4 §I (halt-response protocol, lines ~538–718) specifies an extensive set of
acceptance criteria (§I.6) that must be verified by tests. None of the test rows in the
Slice 1.1 or Slice 1.4 File Maps cover any part of this protocol.

### What §I.6 requires to be testable

Per design.md CD-4 §I.6, the halt-response behavior must be verified across:

1. **Halt-cause × mode matrix**: four halt causes (`drift_count > max_drift_per_round`,
   `hard-blocked`, `scope-exceeded`, `config-invalid`) × two interaction modes
   (`interactive`, `auto`) × two `orchestrator_rescue` values (`true`/`false`) =
   16 fixture combinations.

2. **Tier-rescue behaviors**: tier-1 (mechanical find-and-replace), tier-2 (interpretive
   cascade), tier-3 (sub-agent re-dispatch) must each fire correctly and must NOT fire when
   `orchestrator_rescue: false`.

3. **Interactive-mode menu**: six-option menu must render with correct options; each selection
   must produce the documented effect (Apply fix, Skip finding, Accept as-is, Flag for human,
   Enable rescue round-scoped, Enable rescue run-scoped).

4. **Auto-mode halt**: when `drift_count > max_drift_per_round` in auto mode, the pipeline
   must halt and produce a valid `.orchestrator-fixes.json` audit file.

5. **`.orchestrator-fixes.json` audit file**: the Interface §11 schema (structure.md lines
   308–335) covers the audit file schema, but no test row validates that the file is written,
   that its schema is valid, and that `drift_count` appears in the expected fields.

### Current Slice 1.1 test rows

The existing test rows in Slice 1.1 (structure.md lines 25–27) cover:
- `tests/unit/test-verifier-dispatch.bats` — CD-4 verifier dispatch mode (G8, G13)
- `tests/unit/test-verifier-sidecar.bats` — verifier sidecar output (G11, G14)

Neither test file covers the halt-response protocol. The halt-response is downstream of
verifier dispatch — the `verifier-fan-in.sh` output gates the halt-response — but no test
file maps to the halt-response path at all.

## Stitching gap

The full verifier chain in structure.md (Architectural Diagram lines 456–530) shows:

```
verifier-fan-in.sh → [halt-response logic] → orchestrator-fixes.json / interactive menu
```

The upstream tests (verifier dispatch, sidecar extension) end at `verifier-fan-in.sh`'s
inputs. The downstream behavior — the halt-response logic, the rescue tiers, the
`drift_count` / `orchestrator_rescue` gate — has no test row. This creates a structural gap
where the most user-visible behavior (pipeline halt, interactive menu, automated rescue)
will enter implementation with zero specified test coverage.

## No R1/R2 coverage

R1 added `test-verifier-dispatch.bats` and `test-verifier-sidecar.bats` rows.
R2 made no further test additions. Neither round addressed halt-response testing.

## Minimal-altitude fix

Add a test file row in Slice 1.1 (the slice that owns verifier fan-in):

```
| `tests/integration/test-halt-response.bats` | Create | Test halt-response protocol:
  drift_count threshold gate, orchestrator_rescue × interaction-mode matrix,
  interactive menu options, auto-mode halt, `.orchestrator-fixes.json` schema.
  Fixture coverage per CD-4 §I.6. | G12, G13 |
```

The integration rather than unit placement is appropriate because the test must wire together
`verifier-fan-in.sh` output, config loading, and the halt-response dispatch path.
