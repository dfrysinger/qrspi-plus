---
verifier_enabled: true
scored: 2
kept: 2
dropped: 2
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: quality-claude-r03-F01
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
artifact: phasing
---

# Slice 1.5 Surface enumerates "Structure" but no slice-1.5 goal edits Structure SKILL.md

## Where

`phasing.md` § "### Slice 1.5 — Skill prose & interactive dialog quality" — the Surface line:

> **Surface:** SKILL.md prose hardening across Goals, Design, Structure, Plan; Goals + Design interactive dialog quality + compaction-resilient incremental persistence; reviewer-authority discipline; scope-reviewer alignment with the detailed-solution boundary.

## What

The Surface line lists four target skills as receiving "SKILL.md prose hardening" in slice 1.5: Goals, Design, **Structure**, Plan. But none of the nine goals listed in slice 1.5 (G1, G2, G5, G10, G17, G30, G31, G33, G34) edit Structure SKILL.md prose:

- **G1** edits Design SKILL.md (Dialogue Conduct + Sub-Rules A/B + template).
- **G2** edits Plan SKILL.md (schema-migration task shape).
- **G5** edits Plan SKILL.md (idempotent post-approval split contract).
- **G10** edits reviewer-protocol SKILL.md (no-fabricated-authority anti-pattern).
- **G17** edits implementer-protocol SKILL.md and qrspi-test-writer agent (stale gitignore prose).
- **G30** edits Goals + Design SKILL.md (compaction-resilient persistence + dialogue conduct).
- **G31** edits reviewer agents + prompt-design-guide (prompt-prose reviewer wiring).
- **G33** edits Design SKILL.md (simple-language dialog rule, folded into G1's Dialogue Conduct).
- **G34** edits Design scope-reviewer + design owns-defers (scope-reviewer alignment).

The Structure SKILL.md prose work is owned by **slice 1.6** (G35), which gets its own dedicated slice precisely because the Structure-absorption shape is distinct. Mentioning "Structure" in 1.5's Surface creates ambiguity about whether 1.5 and 1.6 overlap on Structure SKILL.md, which they do not.

The Surface line is also **incomplete**: it omits implementer-protocol (touched by G17) and reviewer-protocol (touched by G10), both of which are edited by slice-1.5 goals.

This is consistent with the round-02 boundary-drift fix abstracting concrete file paths up to generic skill names without reconciling the abstracted list against the actual goal contents.

## Why it matters

Downstream consumers (Structure, Plan, Replan) read the slice Surface line to decide what edit surface each slice claims. The current text suggests slice 1.5 and slice 1.6 both touch Structure SKILL.md, which could lead a Plan task author to either (a) duplicate Structure SKILL.md edits across two parallel slices or (b) skip the Structure-absorption work assuming slice 1.5 covers it. The omission of implementer-protocol and reviewer-protocol from the surface enumeration also means scope-tagger / reviewers may not anticipate edits landing in those skill files when reviewing slice-1.5 work.

The roadmap.md slice 1.5 theme column avoids this trap by saying only "SKILL.md prose hardening + Goals/Design dialog quality" — the phasing.md slice prose drifted from that more accurate framing.

## Suggested fix

Either:

(a) Replace "Goals, Design, Structure, Plan" with the actual edited skills: "Goals, Design, Plan, reviewer-protocol, implementer-protocol" (and drop "Structure" — Structure SKILL.md prose is slice 1.6's responsibility).

(b) Drop the per-skill enumeration entirely and lean on the thematic framing already in the second clause: "SKILL.md prose hardening + interactive dialog quality across the authoring skills; reviewer-authority discipline; scope-reviewer alignment." — letting the per-goal entries downstream define the precise edit set.

Option (b) is closer to the round-02 stripping intent (no concrete file/skill paths in Surface prose). Choose at author discretion.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 60
reason: Verified against goals.md — none of slice 1.5's nine goals (G1/G2/G5/G10/G17/G30/G31/G33/G34) edit Structure SKILL.md (G35 in slice 1.6 owns that), and the Surface line also omits implementer-protocol (G17) and reviewer-protocol (G10); real but low-severity clarity drift between Surface enumeration and goal contents.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: quality-claude-r03-F02
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/roadmap.md
artifact: phasing
---

# Slice 1.2 lists G29, but Surface + Demonstrable-by don't address G29's dispatch-contract surface

## Where

`phasing.md` § "### Slice 1.2 — Verifier rubric calibration + instrumentation":

> **Goals:** G19, G20, G28, G29
> **Surface:** verifier scoring rubric (hallucination class detection, model calibration), and the dispositions + sub-threshold-observations instrumentation formalized in G28.
> **Demonstrable by:** a review round that produces both above-threshold and sub-threshold findings; confirming the dispositions document fires the Sub-Threshold Observations block correctly and the verifier rejects fabricated or hallucinated findings.

`roadmap.md` slice 1.2 theme column similarly: "Hallucination class + model calibration + dispositions instrumentation."

## What

Slice 1.2's goal list includes **G29** ("Reviewer dispatch contract has no escape hatch for large artifacts (canonize `artifact_path`)") — a reviewer-protocol dispatch-contract change adding an `artifact_path` escape hatch for artifacts above a size threshold. But the slice's Surface line and Demonstrable-by criteria cover only G19 (hallucination cite-check), G20 (substituted-model calibration), and G28 (convergent-evidence / sub-threshold-observations). G29's contribution is invisible in both descriptors:

- **Surface:** names "verifier scoring rubric" and "dispositions + sub-threshold-observations instrumentation" — neither covers reviewer-dispatch ingress shape.
- **Demonstrable by:** "a review round that produces both above-threshold and sub-threshold findings" exercises G19/G20/G28 only. A review round against a small artifact does NOT exercise the `artifact_path` escape hatch (the wrapped-body path remains the default). G29 needs a review round against a large artifact (>30 KB per the goals.md candidate threshold) to actually exercise.

This creates two downstream-consumer problems:

1. **Implicit goal — high omission risk in Plan.** A Plan task author reading slice 1.2 sees three rubric/instrumentation goals + an unmentioned G29; the natural carving will produce tasks for G19/G20/G28 surface and miss G29's reviewer-protocol contract edit + per-skill dispatch-contract migrations across the 8 dispatching skills.
2. **Acceptance gate doesn't cover G29.** Phase 1's acceptance gate item 3 (Instrumentation completeness) inherits slice 1.2's framing — it requires sub-threshold-observations + verifier-fan-in + interaction-mode audit, but never asserts the artifact_path escape hatch is exercised. G29 ships untested by the phase-level gate.

## Why it matters

goals.md's Cross-Cutting Notes block contains an explicit cross-link that contradicts G29's current placement:

> G6 and G29 share the same dispatch-contract surface (`skills/reviewer-protocol/SKILL.md`) and are likely co-scheduled.

That is, G29's natural co-slice is **G6** (in slice 1.1 — apply-fix / verifier backbone, which already includes reviewer-protocol disk-write contract work) — not the rubric-calibration cluster. Placing G29 in slice 1.2 splits the reviewer-protocol edit surface across two slices for no apparent benefit, while leaving G29 under-described in its assigned slice.

## Suggested fix

Choose one:

(a) **Relocate G29 to slice 1.1** (apply-fix / verifier backbone). The slice 1.1 Surface already names "reviewer disk-write reliability" and "the apply-fix protocol's core data shape" — both of which extend cleanly to cover dispatch-ingress shape (the reciprocal of disk-write egress). Update slice 1.1 demonstrable-by to add a clause exercising the artifact_path escape hatch against a >threshold artifact. Update slice 1.2 goal list to remove G29 and roadmap.md row to match.

(b) **Keep G29 in slice 1.2, but expand Surface + Demonstrable-by to name it.** Add a clause to Surface: "...and the reviewer dispatch-contract escape hatch for large artifacts (G29)." Add a clause to Demonstrable-by: "...and dispatching a reviewer round against a >threshold artifact via the `artifact_path` form confirms the wrapped-body / path-based escape hatch routes correctly." Also extend Phase 1 acceptance gate item 3 to assert the escape hatch fires.

Option (a) matches goals.md's cross-link guidance and produces tighter slice cohesion (slice 1.2 becomes a clean rubric/instrumentation cluster; slice 1.1 absorbs the reviewer-protocol dispatch-contract work alongside the reviewer-protocol disk-write work it already owns). Option (b) preserves the current slice-assignment table but trades slice cohesion for less churn.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 68
reason: Verified — slice 1.2's Surface and Demonstrable-by genuinely omit G29's dispatch-ingress contract work, and goals.md Cross-Cutting Notes explicitly links G6+G29 to slice 1.1's reviewer-protocol surface; acceptance gate item 3 likewise doesn't exercise the artifact_path escape hatch, creating a real downstream-omission risk for Plan.
<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/phasing.md:L148, docs/qrspi/2026-05-30-v072-release/phasing.md:L152-L153, docs/qrspi/2026-05-30-v072-release/reviews/phasing/round-02-dispositions.md:L40-L43, skills/phasing/owns-defers.md:L15]
artifact: phasing
round: 3
reviewer: scope-claude
---

The round-02 fix removed the literal schema-field name `model_routing` from Slice 1.4 surface prose (per the R2 disposition: "unified `model_routing` schema → unified dispatch-routing config schema") on the grounds that schema/symbol names cross the Phasing → Structure DEFERS line (`skills/phasing/owns-defers.md` L15). The same literal string survives in Phase 1 acceptance gate item 2 (L152: "dispatch with missing model_routing"). The parallel YAML field name `change_type` shows the same shape of drift in items 1 and 2 (L148 "no change_type enum silent fall-through (G13)", L153 "dispatch with invalid change_type"). This is residual drift from an incomplete propagation of an already-accepted fix, not a new front.

**Why this is load-bearing, not pedantic:**

1. **The fix's own disposition flagged this exact string as DEFERS-bound.** R2's edits list (round-02-dispositions L40–43) explicitly treats `model_routing` as a Structure-layer schema name that phasing must not commit to. The boundary call was made; only the propagation is incomplete. Same literal string, same artifact, same DEFERS rule, missed in one location — the convergent reviewer signal that established the boundary in R2 directly demands the same surgery here.

2. **Acceptance-gate commitments are stickier than surface prose.** The phase gate is what Test reads to decide whether v0.7.2 ships. If Structure later renames the schema field (e.g., from `model_routing` to `routing` or `dispatch.routing`), the gate language is now wrong and either fails spuriously or has to be re-edited. That coupling is exactly what the OWNS/DEFERS rule prevents. The same is true for `change_type` — if the per-finding schema field gets renamed, the gate breaks.

3. **The G-ID grounding isn't a defense the R2 fix accepted.** L147–148 already grounds the failure modes via goal IDs ("G7/G22/G23", "G13"). The R2 fix did not treat goal-ID grounding as cover for the schema-name reference in Slice 1.4 — it stripped the name and kept the G-ID. Same calculus applies here.

**Proposed remediation shape (illustrative, Phasing decides the wording):**

- L148 `no change_type enum silent fall-through (G13)` → `no silent fall-through on invalid finding-type values (G13)` — the G-ID is the stable handle.
- L152–153 `dispatch with missing model_routing, dispatch with invalid change_type, reviewer with malformed sidecar` → `dispatch with missing routing config, dispatch with an invalid finding-type value, reviewer with a malformed sidecar` — capabilities, not schema field names.

**What I checked and confirmed clean (so this round's fix did land for everything else on the R2 strip list):** the literal strings `run-codex-review.sh`, `using-qrspi/SKILL.md`, `scripts/build-plugin.sh`, `.interaction-mode-audit.json`, `~/.copilot/installed-plugins/`, `test_helpers/extract.bash`, `round-NN.diff`, `round-NN-commit.txt`, `_assert_host_block_has_routing`, `_extract_h4`, `_extract_routing_block`, and `!cat` are all absent from the current artifact. The R2 fix landed correctly for every item on its stated strip list *except* `model_routing`, and missed the parallel `change_type` instances.

**Not flagged here (sub-threshold for R3 convergence):**

- `SKILL.md` in Slice 1.5 (L97, L103) — a file-suffix reference rather than a path, present across all prior rounds, and not isolated by the R2 finding. Re-raising in R3 against the convergence rule would be opening a new front rather than closing a known one.
- `verifier_enabled: true` in Slice 1.1 (L57–58) — config-flag name, borderline by the same yardstick as `model_routing`, but not in the R2 strip list and not previously flagged. Same convergence reasoning.
- Goal-ID references (G1–G35) and outcome-level demonstrability criteria are explicitly OWNS-side per the dispatch and not at issue.

`change_type: scope` (not `correctness`) because the fix is to *remove* commitments Phasing is not authorized to make in the acceptance gate, not to correct any factual error. Severity `medium` — same as R2-F01 it descends from, because the load-bearing argument is identical and only the residual surface is smaller.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L47-L130
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L144-L167
artifact: phasing
round: 3
reviewer: scope-codex
---

## Residual phasing boundary drift after R2 fix

Residual boundary drift remains: several slice surfaces and
acceptance-gate checks still specify implementation/task-detail internals
(e.g., named scripts/helpers, config keys, H4-paragraph edit surfaces,
and detailed instrumentation mechanics). Under Phasing DEFERS, these
details belong to Structure/Plan/Implement/Test. Keep phasing at
phase/slice outcome boundaries (what is demonstrably delivered), and
move mechanism-level specifics to downstream artifacts.
<!-- @@CLEAN: quality-codex.clean @@ -->
---
finding_id: clean
artifact: phasing
round: 3
reviewer: quality-codex
---

# Clean — no findings

No artifact-quality findings for phasing.md in round 03.
