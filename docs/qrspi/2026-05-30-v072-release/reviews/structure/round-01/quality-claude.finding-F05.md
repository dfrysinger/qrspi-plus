---
finding_id: R1-F05
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

## Duplicate "Create" action for `scripts/dispatch-agent.sh` across Slice 1.2 and Slice 1.4

### What is wrong

`scripts/dispatch-agent.sh` appears with a **Create** action in two separate slices:

- **Slice 1.2** (Verifier rubric calibration + instrumentation):
  > `scripts/dispatch-agent.sh` | Create | Persist resolved host/vendor/model metadata
  > into the dispatch manifest for later observability. | G20, G29

- **Slice 1.4** (Dispatch infrastructure):
  > `scripts/dispatch-agent.sh` | Create | Universal batched dispatch entrypoint:
  > resolve tier/model, prepare rounds, write manifests, and emit first-party task specs.
  > | G3, G4, G16, G22, G23, G25, G27

A file can only be created once. Having "Create" in two different slices is ambiguous:
Plan will either create the file in Slice 1.2 tasks (with only the G20/G29
instrumentation responsibility) and then face a conflict when Slice 1.4 tries to
Create it again, or Plan will interpret one entry as canonical and silently ignore
the other's responsibility description — causing G20/G29 observability requirements
to fall through the crack.

### Why this is a problem

The primary responsibility of `scripts/dispatch-agent.sh` is unambiguously the CD-1
universal dispatch entrypoint (Slice 1.4's description). The G20/G29 observability
work (persisting host/vendor/model metadata into the dispatch manifest) is an
additional capability layered onto the same script — it requires the script to already
exist with its core entrypoint logic in place.

Given slice ordering (1.2 precedes 1.4), a Plan reader would create the file in
Slice 1.2 with only observability instrumentation logic, then find a second "Create"
for the same file in Slice 1.4 — which is a conflict. Either way, the
implementer receives contradictory instructions.

### Expected fix

The Slice 1.2 entry should use **Modify** rather than **Create**:

| `scripts/dispatch-agent.sh` | **Modify** | Add host/vendor/model metadata persistence into the dispatch manifest for later observability. | G20, G29 |

The Create entry in Slice 1.4 is correct and should remain as-is. This aligns with
the standard pattern in the file map where a file is Created in the slice that owns
its core contract and Modified in subsequent slices that extend it.
