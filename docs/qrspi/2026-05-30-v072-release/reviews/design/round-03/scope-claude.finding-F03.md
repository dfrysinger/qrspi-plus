---
finding_id: R3-F03
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L2069
  - docs/qrspi/2026-05-30-v072-release/design.md:L1771
  - docs/qrspi/2026-05-30-v072-release/design.md:L2996
  - docs/qrspi/2026-05-30-v072-release/design.md:L2839
  - docs/qrspi/2026-05-30-v072-release/design.md:L2883
artifact: design
round: 3
reviewer: scope-claude
---

**Drift category — phasing / release-assignment / ordering authoring (installed v0.7.1 OWNS/DEFERS).** The installed contract DEFERS "Vertical slice authoring (Iron Law 1 — vertical-not-horizontal slicing)", "Phase boundaries and replan gates (Phase 1 PoC guideline...; replan-gate criteria)", and "roadmap.md (goal-to-phase assignment table)" to `qrspi:phasing`. The contract closes with an explicit Phasing pointer: "Phasing concerns (vertical slices, phase boundaries, Iron Law 1, the Phase 1 PoC guideline) are owned by `qrspi:phasing` — see `skills/phasing/SKILL.md`." Several sites in the artifact author release-assignment and inter-goal ordering decisions that defer to phasing under the installed contract.

**Concrete sites.**

- **G24 implementation-ordering paragraph (L2069).** "Implementation ordering: G24 lands AFTER G21 (`$body`-presence guard pattern is the dependency) and AFTER G22 / G23 / G25 prose edits settle (the rewritten pins need to match the final post-edit phrasing of the contract they guard, not a mid-flight version)." This is explicit goal-to-phase ordering (G24 after G21/G22/G23/G25) — exactly the shape of phasing.md's task-order graph. The dependency rationale is design-altitude (and worth preserving as a constraint), but the ordering commitment is phasing-altitude under the installed contract.
- **G18 cross-cutting note (L1771).** "G15 ships first (was locked before G18) — its `dependent_tests:` mechanism for sweep tasks is the structural template G18 mirrors." Names a per-goal ship order ("G15 ships first") — phasing decision.
- **G35 D7 hard-dependencies block (L2996).** "G1 deliverables #3 + #4 (the migration source — without them, Structure absorbing architecture/test-architecture creates a parallel authoring contract instead of a migration). G32 (`!cat` resolver — without it, the shared snippet doesn't expand at build time and the install artifact carries unresolved directives). Both ship in v0.7.2." The "Both ship in v0.7.2" commitment is phase-assignment; the dependency edges (G35 depends on G1#3, G1#4, G32) are a partial vertical-slice graph.
- **G32 open-questions block (L2839, throughout).** "v0.7.2 ships G31 + G32 with verified host-native `skills:` preload on the two primary hosts; v0.7.3+ resolves Codex portability once host behavior is empirically confirmed." Explicit release-line commitment ("ships in v0.7.2", "deferred to v0.7.3+").
- **G34 D1 hard-dependency paragraph (L2883).** "Hard dependency on G32: this goal cannot be implemented until G32 ships in the same release. The build pipeline is the single-source-of-truth mechanism..." Cross-goal ship-order constraint within v0.7.2 — vertical-slice graph fragment.

**Broader pattern.** The phrases "ships in v0.7.2", "deferred to v0.7.3+", "lands AFTER", "supersedes", and "co-ships with" recur throughout the artifact (sampled above; many additional sites). Each one is a small phasing decision the installed contract assigns to `qrspi:phasing` and the eventual roadmap.md.

**Why this matters under the installed contract.** The contract's phasing pointer is explicit — phase boundaries and release-assignment live in `skills/phasing/SKILL.md`. Authoring them inline in design.md (a) duplicates content phasing.md will later carry as canonical, (b) creates drift surface if phasing later orders the goals differently (e.g., a phasing-time vertical-slice decision moves G35 to a different phase, but design.md still says "Both ship in v0.7.2"), and (c) commits to vertical-slice decisions Plan and Phasing should still get to make.

**Note on G34's proposed loosening (advisory, NOT applied to this finding).** G34 D2 (L2894) proposes Design OWNS includes "Phasing/release-assignment phrases that name which goal/CD ships in which release (operator-authoritative; phasing.md is the canonical artifact but design.md may carry the labels inline for self-host reasoning)." Under G34 the "ships in v0.7.2" / "deferred to v0.7.3+" labels would be blessed. Even under G34, however, **inter-goal ordering** ("G24 lands AFTER G21", "G15 ships first", "G35 depends on G32 in the same release") arguably remains vertical-slice authoring — G34 blesses release labels, not the cross-goal dependency graph that produces them. So a residual subset of these sites (L2069, L1771's "ships first", G35 D7's dependency-edge list) remains drift even under G34.

**Recommended disposition.** Operator override at human gate per PI-HKP-005 for the release-label content (G34 will retroactively bless on the next round once installed). For the inter-goal ordering content specifically: if the operator wishes to bring it into altitude even under the proposed G34 loosening, replace the ordering commitments with dependency edges (e.g., L2069 becomes "G24 depends on G21's `$body`-presence guard pattern and on the post-edit phrasing of G22/G23/G25" — names the dependency without committing to ship order, which Phasing will resolve into a phase number).
