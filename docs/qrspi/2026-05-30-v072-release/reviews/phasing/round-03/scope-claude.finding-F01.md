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
