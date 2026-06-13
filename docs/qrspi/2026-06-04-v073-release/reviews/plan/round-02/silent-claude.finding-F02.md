---
finding_id: R2-F02
severity: high
change_type: behavior
referenced_files: [docs/qrspi/2026-06-04-v073-release/plan.md:L448, docs/qrspi/2026-06-04-v073-release/plan.md:L451, docs/qrspi/2026-06-04-v073-release/plan.md:L468, docs/qrspi/2026-06-04-v073-release/plan.md:L469]
artifact: plan
round: 2
reviewer: silent-claude
---

T16's dispatch-defect contract names the **Design** step as the surface where absent `absorption_map_path:` is a halt-loud `dispatch-defect:` failure, and explicitly enumerates `goals/research/phasing/structure/parallelize` as the steps where the parameter is optional. The **Plan** step is named in neither list, leaving the plan-spec-reviewer's behaviour on absent `absorption_map_path:` silently unspecified — and the silent default in that gap is the failure mode this finding-type was created to surface.

Plan text — T16 description (L448): "(b) a dispatch-defect contract clause: at the Design step, an absent `absorption_map_path:` parameter is a dispatch defect; the reviewer halts with a `dispatch-defect:` named diagnostic and exits non-zero rather than silently no-op. The absorption_map_path is optional only at goals/research/phasing/structure/parallelize steps, where the design absorption map has no applicable role." T16 test expectations (L451): "The design reviewer's dispatch-defect clause names absent `absorption_map_path:` at the Design step as a dispatch defect (`dispatch-defect:` diagnostic, non-zero exit), and names goals/research/phasing/structure/parallelize as the only steps where the parameter is optional." T17 test expectations (L468–469): "A Design-step dispatch with `absorption_map_path:` absent halts the reviewer with a `dispatch-defect:` named diagnostic and non-zero exit … A goals/research/phasing/structure/parallelize-step dispatch with `absorption_map_path:` absent proceeds normally."

The plan-spec reviewer at the Plan step **needs the absorption map to do its job**. T16's first clause (L448 first sentence) is unambiguous: "The plan-spec reviewer body gains a clause asserting no plan task carries an absorbed-goal ID (per the redirect map produced by `scripts/design-absorption-markers.sh`); a violation surfaces as a `change_type: scope` finding." The redirect map is the load-bearing input for the absorbed-ID check — without it, the reviewer cannot enumerate absorbed IDs to check tasks against. T15 reinforces this by directing the plan-author to consume the map pre-fan-out; T03's test expectations include a `--step plan` fixture that proves the absorption-map is written to the path the plan-spec reviewer consumes (L212: "A `--step plan` fixture asserts the absorption-map is written to the expected path for the plan-spec reviewer to consume").

If `absorption_map_path:` is absent at a Plan-step plan-spec reviewer dispatch, three branches are possible per the plan as currently written:

1. The reviewer halts with `dispatch-defect:` and non-zero exit (the Design-step contract). T16/T17 do **not** specify this for the Plan step.
2. The reviewer proceeds normally (the goals/research/phasing/structure/parallelize-step contract). T16/T17 do **not** name the Plan step in this list either, but a strict reading of "optional only at [those steps]" by elimination would include Plan as "not optional, must halt" — yet T17's test fixtures only exercise the Design halt direction, leaving the Plan halt direction unverified by any test.
3. The reviewer silently no-ops the absorbed-ID check (finds zero absorbed-ID tasks because it has no map to compare against) and produces a clean review. **This is the silent-fallback default** if the reviewer rubric prose says "for each absorbed ID in the redirect map, assert no task carries that ID" and the map is empty/absent.

Branch 3 is the load-bearing failure mode. The G3 acceptance criterion in plan.md L143 says "The v0.7.3 self-host Plan step round-01 produces zero plan-spec-reviewer absorption findings (meta-acceptance for G3)." A silent-fallback Plan-step plan-spec reviewer that finds zero absorption findings because the map never reached it would **satisfy** that acceptance criterion while the actual G3 mechanism is broken. The plan's own meta-acceptance is undetectable from a green/red signal in this branch.

The same gap exists symmetrically: T17's test expectations exhaustively cover the Design-step dispatch-defect direction (L468) and the "optional at goals/research/phasing/structure/parallelize" no-false-positive direction (L469), but **do not include any Plan-step test case** for absent `absorption_map_path:`. The dispatch-defect bats fixture file `tests/unit/test-design-reviewer-dispatch-defect.bats` exists; no `test-plan-spec-reviewer-dispatch-defect.bats` exists.

Resolution scope (one or the other, not both):

- **Option A (most consistent with the G3 acceptance shape):** T16 description and test expectations explicitly add the Plan step alongside the Design step in the dispatch-defect contract — absent `absorption_map_path:` at the Plan step is a `dispatch-defect:` named diagnostic and non-zero exit. T17 adds a Plan-step dispatch-defect fixture asserting the halt direction. The optional-step list explicitly names goals/research/phasing/structure/parallelize as the only optional steps (Plan and Design are mandatory).
- **Option B (if the plan-spec reviewer is designed to handle an empty map gracefully — but this contradicts T16's first clause):** T16 explicitly names what behaviour the plan-spec reviewer takes when the map is absent (e.g., "treats absence as an empty absorbed-ID set; emits zero absorbed-ID findings; logs the dispatch shape at info severity"). This would require an explicit acceptance criterion change because Option B silently negates the G3 meta-acceptance signal — so Option A is the route that preserves the goal.

The current plan as drafted leaves the Plan-step branch unspecified, and the silent default of "no map → no findings → green review" passes the G3 acceptance while failing G3's actual purpose.
