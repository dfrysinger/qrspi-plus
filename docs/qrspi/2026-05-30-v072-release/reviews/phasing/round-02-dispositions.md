---
step: phasing
round: 02
verifier_enabled: true
scope_tagger_enabled: true
scored: 2
kept: 1
dropped: 2
failed: 0
clean: 1
---

# Round 02 Dispositions

## Kept findings (1)

### scope-claude.R2-F01 — phasing boundary drift (scope, medium)

**Finding.** phasing.md crosses the Phasing → Structure DEFERS line by
enumerating concrete file paths AND function/helper signatures inside slice
Surface prose (Slices 1.3, 1.4, 1.7) and the Phase 1 acceptance gate
(items 3 and 4). Per `skills/phasing/owns-defers.md` L15, file paths,
module boundaries, interface contracts, and file maps are Structure-owned;
phasing names slices and phases, not files or function signatures.
Re-raised from round-01 scope-codex finding (R1-F01, dropped at 55) with
stronger framing — the function-signature enumeration in particular
(`_extract_h4`, `_extract_routing_block`, `_assert_host_block_has_routing`)
is a bright DEFERS line that R1 did not isolate.

**Disposition.** Applied (scope/intent change_types bypass verifier filter
per the apply-fix protocol; the convergent re-raise across both scope
reviewers confirms this is load-bearing).

**Edits applied (phasing.md):**

- Slice 1.3 Surface: `round-NN.diff and round-NN-commit.txt creation` →
  `per-round diff and commit-anchor artifacts`.
- Slice 1.4 Surface: `path-filter exfil surface in \`run-codex-review.sh\`` →
  `path-filter exfil surface in the Codex review dispatch wrapper`;
  `unified \`model_routing\` schema` → `unified dispatch-routing config
  schema`; `the same H4-paragraph edit surface in \`using-qrspi/SKILL.md\``
  → `the same H4-paragraph edit surface in the pipeline-orchestration
  skill prose`.
- Slice 1.7 Surface: `bats parameterization across the
  \`_assert_host_block_has_routing\` callers` → `test parameterization
  across the dispatch-routing assertion callers`;
  `\`_extract_h4\` / \`_extract_routing_block\` helper deduplication into
  \`test_helpers/extract.bash\`` → `shared bats helper deduplication for
  the H4 extraction routines`;
  `expand \`!cat\` includes` → `expand inline-include directives`.
- Slice 1.7 Demonstrable by: `expands all \`!cat skills/.../*.md\`
  includes inline` → `expands all inline-include directives`.
- Phase 1 acceptance gate item 3: `\`.interaction-mode-audit.json\`` →
  `interaction-mode audit artifact`; `verifier-fan-in script` →
  `verifier-fan-in`.
- Phase 1 acceptance gate item 4: `\`scripts/build-plugin.sh\`` → `The
  plugin build pipeline`; `expand \`!cat\` includes expanded inline` →
  `expand inline-include directives`; `installs cleanly into a fresh
  \`~/.copilot/installed-plugins/qrspi-plus/\` location` → `installs
  cleanly into a fresh installed-plugins location`.

**Roadmap.md.** Surface-prose drift lived only in phasing.md; roadmap.md
mirror was not affected by this fix.

## Dropped findings (2)

### quality-codex.R2-F01 — score 20 (correctness)

Asserted that phasing.md's `deferred_to_future: 0` is inconsistent with
design.md's "Open Questions for v0.7.3+" sections. Verifier scored 20:
the finding conflates "future PHASE" (intra-release deferred goals, what
phasing's `deferred_to_future` tracks per goal-ID-based pruning) with
"future RELEASE" (v0.7.3+ follow-up notes attached to current-phase goals
G10/G13/G14 in design.md). All 35 goals are correctly current-phase;
future-design.md is legitimately empty.

### scope-codex.R2-F01 — score 55 (correctness)

Same boundary-drift concern raised at change_type=correctness. Dropped
below the 70 correctness threshold. Verifier acknowledged real drift on
the helper-function evidence but noted the acceptance-gate file-path
tension from R1's sub-threshold call still partially applies. The
companion scope-claude.R2-F01 (change_type=scope) covered the same
surface and was applied — so the boundary fix landed despite this
finding's drop.

## Sub-Threshold Observations

The scope-codex finding (correctness, score 55) was dropped per the
verifier threshold, but the same concern was kept and applied via the
scope-claude finding (change_type=scope, bypasses verifier). The apply
contract is therefore satisfied; the dropped finding remains documented
here for trace continuity from R1 (where scope-codex.R1-F01 also scored
55 and was the seed for both R2 re-raises).
