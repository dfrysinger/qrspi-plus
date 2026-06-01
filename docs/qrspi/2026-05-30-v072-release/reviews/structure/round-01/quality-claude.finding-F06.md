---
finding_id: R1-F06
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

## Duplicate "Create" action for `scripts/round-prepare.sh` across Slice 1.3 and Slice 1.4

### What is wrong

`scripts/round-prepare.sh` appears with a **Create** action in two separate slices:

- **Slice 1.3** (Per-task review pipeline corrections):
  > `scripts/round-prepare.sh` | Create | Prepare per-task diff, scope, and
  > commit-anchor artifacts before every review round. | G9

- **Slice 1.4** (Dispatch infrastructure):
  > `scripts/round-prepare.sh` | Create | Canonicalize cumulative diff/ref selection
  > and next-round narrowing inputs. | G4

A file can only be created once. Two Create entries for the same file introduce the
same conflict as R1-F05: Plan will produce one task in Slice 1.3 that creates the
script for per-task diff/scope/commit-anchor purposes, and a second task in Slice 1.4
that creates the same file for diff/ref canonicalization purposes. The implementer
faces a conflict: they cannot create the same script twice from different task specs.

### Why this is a problem

The primary design motivation for `round-prepare.sh` is G4 (Canonical cumulative diff
helper) — this is Interface #2 in structure.md's Interfaces section, and the full CLI
contract is specified there. The G9 responsibility (per-task diff, scope, and
commit-anchor artifacts) is an extension layered on top of the same script per CD-1's
design notes ("Behavior: Check `<output-dir>/.round-prepare.json`; if absent,
auto-invoke `round-prepare.sh` (G4), forwarding `--task-branch` and
`--implementer-commit` when set").

Slice 1.3 processes before Slice 1.4 in implementation order. A Plan reader would
create the script in Slice 1.3 with G9's per-task responsibilities, then see a second
"Create" in Slice 1.4 for G4's canonicalization work — an unresolvable conflict.

### Expected fix

The Slice 1.3 entry should use **Modify** rather than **Create**:

| `scripts/round-prepare.sh` | **Modify** | Add per-task diff, scope, and commit-anchor artifact emission alongside the existing canonical diff/ref selection logic. | G9 |

The Create entry in Slice 1.4 is correct and should remain as-is, since G4 owns the
canonical definition of this script's contract (it is Interface #2). This mirrors the
same correct pattern used for `scripts/dispatch-agent.sh` (Create in its canonical
slice, Modify in extending slices).
