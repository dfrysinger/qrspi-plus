---
reviewer_tag: scope-claude
round: 2
artifact: plan.md
verdict: clean
---

# scope-claude — round 02 — clean

Scope/boundary review of `docs/qrspi/2026-05-30-v072-release/plan.md` against `skills/plan/owns-defers.md`. The diff under review is the full new-file plan.md (2742 lines, 44 tasks across 7 slices). No companion artifacts loaded (per scope-reviewer protocol).

## 3-check results

**1. Boundary-drift detection (Plan DEFERS).** No violations.

- **Function signatures / type definitions / parameter shapes → structure.md.** No parenthesized parameter lists or return-type arrows found. Where Plan names observable output fields (e.g., `dispatch_spec.subagent_type`/`host`/`vendor`/`model`/`prompt_file` in T11 DoD, `actual_model:` in T09, `defect_class:` in T10, `KEY=VALUE` shape in T24, exit codes 10/11/12 in T12) the bullets cite `structure.md ### 10. Dispatch manifest schema` / `structure.md ### scripts/...` as the authoritative per-file schema source. Plan is naming testable observable surfaces, not authoring shapes — defensibly inside the "conversation, not contract" framing.
- **Full assertion text / `expect(...)` / test code → Implement-TDD.** No `expect(`, `assert.`, `assertEqual`, or `toBe(` patterns in Test Expectations. Every task's Test Expectations uses plain language verbs (grep, inspect, exercise, run, audit, confirm). Literal anchor phrases pinned for assertion (e.g., T31's `"Use simple language and provide context when presenting ideas"`, T32's `"Resumed after compaction — last locked decision: ..."` diagnostic, T21's `resolves outside repository`) are behavior-pin specifications, not assertion code.
- **Line-by-line logic / control-flow / pseudocode → Implement.** No `if/else`, `for`, `while`, switch, or numbered-step algorithmic walkthroughs in task bodies. Where ordering or branching is named (e.g., T12 convergence "broadens on missing/empty/full-artifact/superset/overlap/disjoint; narrows only for equal or proper-subset"), the wording describes decision-table outputs / observable behaviors rather than control flow.
- **Architecture decisions / trade-offs / system diagrams → design.md.** No "trade-off", "we considered", or "alternative approach" prose authoring. Rationale framings consistently cite `design.md ## GNN` / `design.md ### CD-N` as the upstream source. Where Plan acknowledges non-goals (e.g., T11 "G29 is moot / absorbed by CD-1, with no threshold rule"), it consumes a locked Design disposition rather than re-deciding.
- **Phasing / vertical slice authoring / roadmap / replan-gate criteria → phasing.md.** Borderline area surveyed:
  - The Phase 1 boundary ("Phase 1 is the whole release: all 35 goals, all seven slices") is consumed from phasing.md, not re-authored.
  - Slice headings (1.1–1.7) organize tasks under the already-decided phasing slices; no new slice rationale or replan trigger is authored.
  - The seven-bullet **Phase 1 Acceptance Criteria** block describes cross-task observable behavior at phase end — a natural aggregation of Plan-owned per-task Test Expectations, not replan-gate criteria. Defensible inside the OWNS surface.
  - "v0.7.3+ deferral" mentions appear as task **Out:** scope-bounding markers, not as forward-phase plan authoring.

**2. Scope compliance (Plan OWNS).** All four OWNS items covered for all 44 tasks.

- Ordered task specs: T01–T44 globally sequential; the one cross-slice reorder (T12 sequenced into Slice 1.4 ahead of Slice 1.3 G9 consumers) is called out explicitly with the rationale.
- Test expectations: every task carries a `**Test expectations**` block in plain language.
- Dependencies: every task lists `**Dependencies:**` (explicit "none" where applicable); many also list `**Blocks:**`. No forward dependencies observed in spot-check across slices.
- LOC estimates: every task carries `**LOC estimate:** ~N`; six oversized tasks (T12 ~280, T16 ~320, T19 ~210, T20 ~260, T25 ~340, T39 ~360) carry explicit `**Sizing exception:**` labels (`reusable primitives`, `schema-migration`, `CI scaffolding`).

**3. Lexical boundary-drift signals.** No leakage patterns triggered:

- No Structure-layer signature leaks (no parenthesized parameter lists with return types).
- No Implement-TDD assertion strings (no `expect(`, `assert.`, `toBe(`, `assertEqual`).
- No Implement-layer logic walkthroughs (no `if/else`, `for`, `while`, line-numbered logic).
- No Design-layer authoring vocabulary in task bodies ("trade-off", "we considered", "alternative approach").
- No Phasing-layer forward-plan prose ("phase 2 will…", "future phases…", roadmap-style references); future-version mentions are scope-out markers only.

## Length check

2742 lines / 44 tasks ≈ **62 lines per task** vs. Keeplii baseline ~52 lines/task. The per-task density is near baseline; the aggregate sits ~37% above the 2000-line soft top, but the elevation is accounted for by per-task **References** blocks (typically 5–8 lines × 44 = ~250 lines of pure pointer overhead) plus the Phase 1 acceptance / dependency-graph framing. Not "well outside" the soft band; no length finding.

## Verdict

Zero scope/boundary findings. Plan stays inside its OWNS surface and defers correctly to `design.md`, `structure.md`, and `phasing.md` throughout. The "conversation, not contract" framing is honored: tasks pin observable behaviors and acceptance pins without foreclosing Structure/Implement negotiation room.
