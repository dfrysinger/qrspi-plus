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
