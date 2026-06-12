---
status: draft
---

# Phasing: qrspi-plus v0.7.3 — pipeline correctness + prompt-footprint reduction

## Purpose

v0.7.3 is a single-phase maintenance release. It closes the eight P0 defects surfaced by the v0.7.2 self-host run plus the prompt-footprint reduction tracked as G9. No work is deferred to a future phase, so no inter-phase replan gates are required and no content is moved to `future-*.md`.

## Phases

### Phase 1 — v0.7.3 release (current)

- **Scope.** All nine goals (G1–G9) and all three cross-goal design decisions (CD-1, CD-2, CD-3) ship together.
- **Slices.** One slice — `v0.7.3 release`. Per Iron Law 1, slices must be end-to-end demonstrable; for a single-phase maintenance release with no follow-on phase to defer integration risk into, decomposing into smaller slices would impose review overhead without delivering the integration-risk benefit that vertical slicing exists to provide. The replan-gate criteria below apply to the whole slice.
- **Phase 1 PoC guideline — N/A.** The PoC guideline asks Phase 1 to prove the full stack end-to-end *when there is a Phase 2+ to push deferred layers into*. v0.7.3 has no Phase 2; every layer the release touches is in this phase by construction.
- **Replan-gate criteria (end-of-phase).**
  - All nine goal Acceptance criteria pass (per each goal's `## Acceptance` block in `design.md`).
  - Plugin installs cleanly from the published plugin and marketplace manifests (G8 lockstep) on a fresh Copilot CLI session.
  - A self-host smoke run executes the full QRSPI pipeline end-to-end against a fixture artifact and converges without orchestration-boundary breaches (G5) or parent-SHA drift (G6).
- **Intra-slice sequencing constraints (carried from `goals.md` § Cross-Cutting Notes).** G9's skill-body trim must land after G1–G7's correctness work settles (merge-churn avoidance). G6 and G7 are designed and implemented as a paired unit (shared round-mechanics surface). Wave ordering for these constraints is owned by Plan; Phasing surfaces them here so the constraint travels with the slice into Plan-step authoring.

## Slices

### v0.7.3 release

End-to-end demonstrable unit: the running v0.7.3 plugin installed in a fresh Copilot CLI session, capable of executing a full QRSPI pipeline run that exercises the verifier rubric (G1), test-name hygiene (G2), plan-author boundary (G3), apply-fix `plan`-step upstream entry (G4), orchestration-boundary observability (G5), stage-commit parent-SHA validation (G6), narrow-round ref selection (G7), centralized plugin version source (G8), and the reduced active-skill-prompt footprint (G9).

Goal IDs covered: G1, G2, G3, G4, G5, G6, G7, G8, G9. Cross-goal design decisions covered: CD-1, CD-2, CD-3.

## Amendments introduced during Phasing

None.

## Goal-ID consistency

The canonical goal-ID set for v0.7.3 is { G1, G2, G3, G4, G5, G6, G7, G8, G9 }. Every goal ID appearing in `goals.md`, `questions.md`, `research/summary.md`, `design.md`, and `roadmap.md` resolves to this set. `future-goals.md`, `future-questions.md`, `future-research-summary.md`, and `future-design.md` carry no goal IDs because v0.7.3 defers no content.
