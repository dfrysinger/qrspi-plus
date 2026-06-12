---
finding_id: R8-F01
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 8
reviewer: quality-claude
---

CD-2 Solution's new Plan-step entry attributes diff-narrowing to "G4's pipeline-mode rules" — but G4 does not define any diff-narrowing rules.

**Verbatim, the new Plan branch in CD-2 Solution (line 33):**

> Plan produces diff + absorption-map (consuming `scripts/design-absorption-markers.sh` against design.md so the plan-spec reviewer receives `absorption_map_path` per G3 change 3, plus a diff narrowed per G4's pipeline-mode rules)

**What G4 actually governs (lines 242–266):**

G4's "pipeline-mode rules" switch the *content of the `upstream_paths` array* for the Plan-step verifier dispatch:
- Plan (full pipeline): `goals.md, research/summary.md, design.md, phasing.md, structure.md`
- Plan (quick fix): `goals.md, research/summary.md`

That is, G4 selects *which prior-step artifacts appear in the verifier's lazy-Read window*. G4's Outcome, Solution, Why, Dependencies, and Acceptance sections never mention diff scope, diff base, narrow-vs-broaden semantics, or anything `review-prep.sh` would consume to vary diff content per pipeline mode.

**Where diff narrowing actually lives in this design:**

- G7 (lines 419–454) defines per-round narrowing: `HEAD~1` → anchor-file lookup from `reviews/<step>/round-NN-commit.txt`. Not pipeline-mode-aware.
- The convergence rule in `skills/using-qrspi/SKILL.md` § Standard Review Loop step 1 + step 12 (referenced throughout this design, e.g. line 60 of the diff context) governs narrow-vs-broaden across rounds based on finding state. Not pipeline-mode-aware.

Neither has a "pipeline-mode" branch.

**Why this matters at implementation time.** An implementer reading CD-2's Plan branch chases "G4's pipeline-mode rules" expecting a diff-narrowing specification, opens G4, and finds only upstream-paths content rules. They are then forced to either (a) invent a pipeline-mode-based diff-narrowing rule that the design never decided, or (b) drop the qualifier and use the existing G7 + convergence-rule narrowing (which is pipeline-mode-agnostic). Either path is a guess, and the two paths produce different review-prep behavior. CD-2 Solution should state the actual rule it wants `review-prep.sh` to apply for the Plan step, rather than delegating to a non-existent G4 ruleset.

**Recommendation.** Pick one:

- **(a) If Plan-step diff scope is intended to be pipeline-mode-aware** (e.g., quick-fix mode diffs against goals.md rather than design.md, or skips some narrowing step), add that decision to G4's Solution (it is genuinely a Plan-step scope decision and belongs near G4's other Plan-step pipeline-mode branching) or articulate it inline in CD-2's Plan-branch entry. State the rule explicitly: which ref does the script diff against in each mode.
- **(b) If the Plan diff just inherits the existing per-round narrowing from G7 + the convergence rule** (most consistent with how every other artifact-step in CD-2's generation table is described), drop the "per G4's pipeline-mode rules" phrase. The Plan-step entry then reads symmetrically with Goals, Research, Phasing, Structure, Parallelize — all of which CD-2 describes as "diff with appropriate narrowing" without citing G4. Suggested rewrite:

  > Plan produces diff + absorption-map (consuming `scripts/design-absorption-markers.sh` against design.md so the plan-spec reviewer receives `absorption_map_path` per G3 change 3); diff narrowing follows the same per-round + convergence-rule pattern as the other artifact-step entries above.

Option (b) is the lighter-touch fix if no pipeline-mode-specific diff narrowing was actually intended.
