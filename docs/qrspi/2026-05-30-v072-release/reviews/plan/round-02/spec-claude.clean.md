---
reviewer: spec-claude
round: 2
artifact: plan.md
status: clean
---

# Spec-Claude Round 2 — Clean

Verification checklist passed against `docs/qrspi/2026-05-30-v072-release/plan.md` (full route, round 2).

## 1. Completeness — every goal carries a task with test expectations
All 35 goals (G1–G35) have explicit primary-task coverage with concrete `## Test Expectations` blocks. Mapping:

G1→T30, G2→T33, G3→T20, G4→T12, G5→T34, G6→T03, G7→T01, G8→T04, G9→T13, G10→T35, G11→T06, G12→T02, G13→T05, G14→T07, G15→T14, G16→T21, G17→T36, G18→T15, G19→T08, G20→T09, G21→T40, G22→T16, G23→T17, G24→{T22,T23,T42,T43,T44}, G25→T18, G26→T41, G27→T19, G28→T10, G29→T11, G30→T32, G31→{T25,T26}, G32→T39, G33→T31, G34→T29, G35→{T37,T38}.

Cross-cutting decision tasks (T24 CD-4 interaction-mode helper, T27 CD-2 evergreen-output rule, T28 CD-3 multi-actor-flow-check) provide additional reinforcement at surfaces those CDs span; they do not substitute for primary goal coverage.

Phase 1 Acceptance Criteria (7 bullets in `### Phase 1 Acceptance Criteria`) name cross-task observable behaviors at phase boundary — end-to-end pipeline run, fail-loud invariant firing, sub-threshold instrumentation, build-pipeline reproducibility, full bats green, GitHub-issue closure, release-PR readiness. Each criterion is testable and traces to specific backing tasks (e.g., fail-loud invariants → T03/T16/T17/T18/T20/T21/T35; build pipeline → T39; etc.).

## 2. Scope — nothing outside the goals
Every task and target file traces to a goal or to one of the three approved CDs. The seven-slice decomposition (apply-fix/verifier backbone, rubric calibration, per-task review pipeline, dispatch infrastructure, skill-prose, structure-absorbs-architecture, build/release tooling) maps cleanly to the four coherent surfaces named in the Overview. No "nice-to-have" or premature-optimization tasks observed.

## 3. Interpretation — goal intent preserved or correctly remapped
G29's original "canonize `artifact_path`" framing is correctly remapped via T11 to the design-locked disposition "absorbed by CD-1, no parser contract, manifest provenance only" — matching design.md ## G29's locked outcome. Test expectations verify the chosen design (large-artifact dispatch auditable via `.dispatch-manifest.json`; no threshold rule introduced) rather than the obsolete original framing. All other goals' tasks match their stated intent.

## 4. Test Coverage Mapping
Every goal's success condition has at least one verifiable test expectation. Test expectations are specific (bats fixtures with named files, grep audits with literal anchor phrases, R1–R7 content-semantic reviews, acceptance fixtures with named round-directory artifacts) rather than vague.

Edge cases and error conditions are covered: T03 wrong-channel diagnostic, T04 missing-`change_type` diagnostic, T05 out-of-enum halt, T06 wrong-extension rejection, T08 cite-check fixtures (missing files, out-of-range lines, quoted-content mismatch, missing anchors), T12 commit-anchor recovery codes (10/11/12), T21 symlink-escape and out-of-repo `--companion` regressions, T34 mismatch/missing-header/malformed-header halt diagnostics, T35 fabricated-citation rejection, T39 symlink-escape regression mirroring T21.

T18 (G25) is the lightest test surface — explicit DoD non-goal of "no bats test introduced" because the section-level invariant is prose-only. However, downstream T22 (depends on T18) requires the class-level invariant remain present, and T44's regex-pin tests transitively guard the silent-fallback contract the paragraph establishes. Not a coverage gap.

## 5. Placeholder Detection
Scanned task specs for TBD/TODO/"similar to Task N"/"appropriate handling"/"as needed". None found. File paths are exact (target-file lists name specific paths). LOC estimates present on every task. T42's target-file conditional ("…or the current `…test-t10-*.bats` successor that owns the T10 `model_routing:` host/tier assertions") is deliberate audit-aware behavior per design.md ## G24's note that historical F01 files may be moot — the spec provides explicit locate-then-parameterize guidance rather than leaving the implementer to guess.

## 6. Task Sizing
Each of the six tasks above the 200 LOC ceiling carries a `Sizing exception` field from the closed set:
- T12 (~280, reusable primitives) — `round-prepare.sh` + `await-round.sh` + manifest/anchors JSON. Components are coupled (scripts consume manifest data); no individual sub-task would produce observable behavior change.
- T16 (~320, schema-migration) — agent-frontmatter sweep across 41 agent files plus the schema-defining config/skills edits.
- T19 (~210, reusable primitives) — `second-reviewer-available.sh` + `_host-detect.sh` + `_resolve-lib.sh` matrix + consumer migration.
- T20 (~260, reusable primitives) — three-script rename + shared snippet + 12-skill migration; atomic to avoid mixed old/new dispatch paths.
- T25 (~340, reusable primitives) — six new G31 primitive files; T26 depends on T25 producing them all at once.
- T39 (~360, CI scaffolding) — build pipeline + CI workflow + CONTRIBUTING + four bats files.

Each exception value is in the documented closed set (`schema-migration`, `CI scaffolding`, `reusable primitives`). No task title uses "+ joining" to bundle distinct feature names without an exception. The three cross-cutting CD tasks (T24, T27, T28) list multiple goal IDs because they implement CDs that span those goals, but each task delivers a single coherent CD component (interaction-mode helper / evergreen-output snippet+includes / multi-actor-flow snippet+includes) — not feature-bundling.

No tasks identified that fail the floor: each task in the surveyed set traverses the layers needed for its behavior and produces observable behavior change when merged alone.

## Result
No findings. Plan artifact is approved by spec-claude for round 2.
