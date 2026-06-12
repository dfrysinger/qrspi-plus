---
artifact: structure
reviewer: quality-codex
change_type: correctness
severity: blocking
---

# G5 phase-base anchor is structurally wrong for Integrate/Test boundary checks

## Location

`docs/qrspi/2026-06-04-v073-release/structure.md`:

- File Map: line 88
- Interface: lines 326-333
- Diagram: lines 568-570

## Finding

Structure now specifies that `scripts/orchestration-boundary-check.sh` reads `<phase-base>` from:

`<artifact-dir>/reviews/implement/wave-state/wave-W<N>-expected-parents.txt`

and treats the wave-1 `integration_base_sha=` as the phase-base SHA.

That is not a coherent structure for G5 across all phases. The implement wave-1 sidecar captures the Implement phase's pre-wave integration base. It is not the start point for the Integrate or Test phase ranges, so using it for `reviews/integration/orchestration-boundary.md` or `reviews/test/orchestration-boundary.md` will include prior-phase commits and can report false orchestration-boundary violations.

It also diverges from `design.md` G5, which says the phase-base selection is per phase and deferred to Plan via a recoverable phase/start anchor, not globally fixed to Implement wave 1.

## Required fix

Define a per-phase phase-base anchor contract in `structure.md`, e.g. a phase-specific sidecar/anchor path for `implement`, `integration`, and `test`, or explicitly delegate the concrete read-site to Plan as design currently does. Then update the File Map, Interface block, and diagram so `orchestration-boundary-check.sh` does not hard-code the Implement wave-1 sidecar as the base for every phase.
