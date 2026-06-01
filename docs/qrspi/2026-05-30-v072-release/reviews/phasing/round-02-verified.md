---
verifier_enabled: true
scored: 2
kept: 1
dropped: 2
failed: 0
clean: 1
---

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: phasing
round: 2
reviewer: quality-codex
---

## `phasing.md` claims no future-phase content but `design.md` carries explicit v0.7.3+ planning

**Summary.** `phasing.md` asserts there is no future-phase content (`## Future-phase content` says none; `deferred_to_future: 0`), but the
current-phase pruned artifact set contains explicit future-release content in
`design.md` (multiple "Open Questions for v0.7.3+" sections and future
follow-up planning). That violates the four-artifact pruning quality rule
("no future content leaked into current-phase artifacts") for a single-phase
release.

**Required fix.** Remove/relocate future-release planning text from
current-phase artifacts into the appropriate `future-*.md` channel (or strip
it entirely if truly out of scope), so current artifacts contain only Phase 1
content consistent with phasing's "none deferred" claim.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 20
reason: Conflates "future PHASE" (intra-release, what phasing.md's `deferred_to_future` tracks per goal-ID-based pruning) with "future RELEASE" (v0.7.3+ follow-up notes attached to current-phase goals G10/G13/G14 in design.md); phasing SKILL's pruning rule is goal-ID-based and all 35 goals are correctly current-phase, so future-design.md is legitimately empty and the claim is consistent.
<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/phasing.md:L73, docs/qrspi/2026-05-30-v072-release/phasing.md:L86-L92, docs/qrspi/2026-05-30-v072-release/phasing.md:L121-L130, docs/qrspi/2026-05-30-v072-release/phasing.md:L163-L172, skills/phasing/owns-defers.md:L15]
artifact: phasing
round: 2
reviewer: scope-claude
---

phasing.md crosses the Phasing → Structure boundary by enumerating concrete file paths AND function/helper signatures inside slice "Surface" prose and inside the Phase 1 acceptance gate. The DEFERS rule (`skills/phasing/owns-defers.md` L15) is explicit and load-bearing: "File paths, module boundaries, interface contracts, file maps → owned by Structure. Phasing names slices and phases; it does NOT enumerate files or function signatures." The same rule's closing line tags "skill-implementation jargon" as a drift signal.

This boundary concern was raised by scope-codex in round 1 (R1-F01, score 55, dropped below the verifier threshold). Re-raising with stronger framing because the volume across the artifact — not any single instance — is what makes this load-bearing, and because the function-signature enumeration is a particularly bright DEFERS line that round 1 did not isolate.

**Function / helper signatures (clearest DEFERS violation — these are Structure or Plan territory, never Phasing):**

- Slice 1.7 (L124–126) names `_assert_host_block_has_routing` callers, `_extract_h4`, and `_extract_routing_block` and even prescribes where they should be deduplicated to (`test_helpers/extract.bash`). That is a Structure decision — Phasing is committing the helper layout before Structure has authored it.

**File / script paths embedded in slice Surface prose and acceptance gate:**

- Slice 1.3 (L73): `round-NN.diff`, `round-NN-commit.txt` (artifact-filename specs — Structure/Plan).
- Slice 1.4 (L86–88): `run-codex-review.sh`, `using-qrspi/SKILL.md`, the `model_routing` schema name.
- Slice 1.7 (L121–130): `test_helpers/extract.bash`, plus the `!cat skills/.../*.md` syntax which is Implement-skill jargon.
- Phase 1 acceptance gate item 3 (L165): `.interaction-mode-audit.json` with field-provenance commitment.
- Phase 1 acceptance gate item 4 (L169–172): `scripts/build-plugin.sh`, `~/.copilot/installed-plugins/qrspi-plus/`.

**Why this matters (load-bearing argument the round-1 framing under-sold):**

1. Phasing is upstream of Structure. Every file path or function name committed here pre-empts Structure's authoring rights and turns Structure into a transcription step. If Structure later concludes the right helper is `extract_routing_block_for_host` in `test_helpers/routing.bash`, phasing.md is now wrong and must be re-edited — coupling churn the OWNS/DEFERS rule exists to prevent.
2. The drift is not cosmetic. The slice-grouping argument in Slice 1.4 ("the whole cluster shares the same H4-paragraph edit surface in `using-qrspi/SKILL.md`, so grouping them in one slice prevents Plan from carving overlapping tasks") is making a *Structure-layer* argument (shared edit surface) to justify a *Phasing-layer* grouping (slice membership). That is precisely the cross-skill reasoning DEFERS forbids — even if the conclusion happens to be right, Phasing is not the layer authorized to make it.
3. The acceptance-gate file-path commitments (item 4, `scripts/build-plugin.sh` at v0.7.2 HEAD producing an artifact installable at `~/.copilot/installed-plugins/qrspi-plus/`) bake Structure-level naming into the release gate. Renaming the script in Structure now requires re-editing the phase gate.

**Proposed remediation shape (illustrative, not prescriptive — Phasing decides the wording):**

- In slice Surfaces, replace concrete file/function names with the *capability* being hardened. E.g. Slice 1.7's helper-dedup item becomes "deduplicate the bats helper layer that today copies the host-routing assertion across multiple test files" — no `_assert_host_block_has_routing`, no `test_helpers/extract.bash`. Structure picks the names.
- Acceptance gate item 4: replace `scripts/build-plugin.sh` with "the plugin build pipeline (G32)" and replace the install-target path with "the standard plugin install location". The G-ID is the stable handle; the path is Structure's decision.
- Slice 1.4: keep the "shared edit surface" insight but attribute it conditionally ("Structure is expected to confirm these touch a shared surface; if it does not, Plan may split"). That frames Phasing's grouping as falsifiable downstream rather than committing the edit surface.

The slice decomposition itself is sound — only the over-specification of the slice "Surface" bullets and the acceptance gate is at issue. Treating this as `change_type: scope` (not `correctness`) because the fix is to *remove* commitments Phasing is not authorized to make, not to correct any factual error.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L78-L93
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L115-L128
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L131-L165
  - skills/phasing/owns-defers.md:L15-L18
artifact: phasing
round: 2
reviewer: scope-codex
---

## Phasing boundary drift: phasing.md contains Structure/Plan-level file-path and task-spec detail

**Summary.** `phasing.md` crosses the Phasing DEFERS boundary by specifying
concrete file paths, script names, helper/function-level surfaces, and
procedural test/task specs inside slices and the phase acceptance gate.

**Evidence.**

- Slice 1.4 names concrete files/surfaces: `run-codex-review.sh`,
  `using-qrspi/SKILL.md`.
- Slice 1.7 names helper/module paths: `test_helpers/extract.bash`,
  `_extract_h4`, `_extract_routing_block`.
- Phase 1 gate names executable/script/path specifics:
  `scripts/build-plugin.sh`, `~/.copilot/installed-plugins/...`.
- Acceptance criteria include ordered procedural trip-tests and
  implementation-level checks, which are task-spec detail.

**Boundary rule (from `skills/phasing/owns-defers.md`).**

DEFERS:
- File paths, module boundaries, interface contracts, file maps → owned
  by Structure.
- Task specs, LOC estimates, ordered task lists, per-task test
  expectations → owned by Plan.

**Required fix.** Rewrite slices and acceptance gate at phasing level
only: keep phase/slice intent, goal-ID grouping, and outcome-level
demonstrability criteria; remove concrete file/module pathing and
stepwise task/test execution detail (delegate those specifics to
Structure/Plan).

**Re-raise note.** This finding is a re-raise of round-01's scope-codex
finding (score 55, dropped below correctness threshold) with sharper
evidence and a higher severity classification.
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 55
reason: Real boundary drift per phasing/owns-defers.md DEFERS (helper-function names `_extract_h4`/`_extract_routing_block` are clearly Structure-level); re-raise is invited by round-01 disposition and sharper on helper-function evidence, but the acceptance-gate file-path tension that drove the round-01 sub-threshold call still partially applies.
<!-- @@CLEAN: quality-claude.clean @@ -->
---
reviewer_tag: quality-claude
artifact: phasing
round: 2
status: clean
---

# Quality reviewer (Claude) — round 02 — no findings

All seven phasing-specific quality checks pass against the round-02 artifact.

## Checks evaluated

1. **Every goal in scope has at least one slice.** All 35 approved goals (G1–G35)
   from `goals.md` are covered. Union of slice rosters: 7 + 4 + 3 + 8 + 9 + 1 + 4
   = 36 slice-entries reflecting G24's split across slices 1.4 (F02, F04) and 1.7
   (F01, F03, F05) — 35 distinct goal IDs. Pass.

2. **Every slice has at least one phase.** All seven slices (1.1 through 1.7)
   are assigned to Phase 1. No orphaned slices. Pass.

3. **Iron Law 1 — vertical slices.** The "Why single phase" section explicitly
   addresses the vertical/horizontal axis: because every slice ships together in
   Phase 1, the release itself is the vertical slice (the full hardened qrspi-plus
   pipeline). Slice subdivision is named as Plan/Parallelize substructure for
   edit-surface coherence, not as horizontal layering. The justification cites
   that no "DB layer first, API layer second" failure mode applies to hardening
   an existing orchestration tool. Pass.

4. **Phase 1 PoC guideline.** Phase 1 = v0.7.2 release IS the end-to-end PoC, with
   the acceptance gate doubling as the PoC validation run. The PoC-justification
   block names the guideline explicitly and explains how every layer is touched
   in any complete `Goals → Test` pipeline run. Pass.

5. **Replan-gate / acceptance-gate criteria concrete and checkable.** All five
   acceptance criteria specify observable outcomes:
   - End-to-end pipeline exercise names specific G-IDs and failure modes to
     verify (G6, G7/G22/G23, G12, G13, G9).
   - Fail-loud trip-the-trap test names dispatch with missing model_routing,
     invalid change_type, malformed sidecar.
   - Instrumentation completeness names `.interaction-mode-audit.json` and
     design.md I.7 provenance.
   - Build pipeline names `scripts/build-plugin.sh`, the install location, and
     the canary smoke test.
   - Plugin-issue inbox closure enumerates issues #281–#285.
   The Replan-gate-skipped item explicitly states why (final phase). Pass.

6. **Four-artifact pruning procedure applied.** All four `future-*.md` files
   exist on disk (`future-goals.md`, `future-questions.md`,
   `future-research-summary.md`, `future-design.md`), each carrying
   `deferred_count: 0` and a no-deferred-content header. The four pruned files
   (`goals.md`, `questions.md`, `research/summary.md`, `design.md`) carry
   `status: approved`. No current-phase content in `future-*.md`; no future
   content in current-phase artifacts. Pass.

7. **Goal-ID consistency across nine files.** Phasing.md and roadmap.md slice
   rosters match verbatim, including the G24 sub-finding split:
   - Slice 1.4: "G24 (F02, F04)" — F02 (per-H4 prose redundancy), F04 (tier-regex
     consolidation) — both match goals.md G24's F02/F04 entries (dispatch-routing
     edit surface).
   - Slice 1.7: "G24 (F01, F03, F05)" — F01 (bats parameterization), F03 (helper
     deduplication into `test_helpers/extract.bash`), F05 (anti-pattern pin regex)
     — all match goals.md G24's F01/F03/F05 entries (test-helper-infrastructure
     edit surface).
   Round-01 fixes (R1-F01: G25 → slice 1.4; R1-F02: G24 split) correctly applied.
   No orphan IDs. Pass.

## Notes

- The diff vs base (`<base-branch>`) shows phasing.md as a new file with the
  entire round-02 content present; round-01 fixes are baked into the current
  artifact state.
- Boundary / scope concerns (e.g., naming concrete file paths inside acceptance
  criteria) are scope-reviewer territory and intentionally not flagged here per
  the artifact-specific-quality-only mandate.
