---
artifact: structure
reviewer: qrspi-structure-reviewer
reviewer_tag: quality-claude
round: 3
severity: medium
change_type: correctness
status: open
---

# Slice 4 File Map cell asserts removal of `## Execution Order` top-level section, contradicting the new R3 Section Contracts claim that top-level structure is preserved

## Location

`structure.md`:

- File Map row at line 39 (Slice 4, `skills/parallelize/SKILL.md` Responsibility cell): "...remove the now-redundant `## Execution Order` prose section..."
- Section Contracts § Modified files at line 150 (new R3 prose): "...this artifact does not re-assert heading-level shape for those files (the existing top-level section structure is preserved by all Phase 1 edits)..."

## What I observed

R3 replaced the R2 Section Contracts heading-level assertions with a deferral paragraph that adds one new load-bearing factual claim: *the existing top-level section structure is preserved by all Phase 1 edits*. That paragraph is correct for Slice 6 / 7 / 8 / Slice 4-agent rows (their File Map cells already speak in content-block terms — "Codex-detection section", "providers block", "model_routing", "Branch Map structural-rule assertions" — without any `##` notation, matching the round-2 quality-claude.001 enumeration of the actual files).

But the Slice 4 row for `skills/parallelize/SKILL.md` still carries the H2 notation `## Execution Order`:

> Replace the flat three-column Branch Map with `### Wave N` sub-sections (each sub-section contains a Task/Branch/Base mini-table); **remove the now-redundant `## Execution Order` prose section**; update the inline "Good" and "Bad" worked-example pairs to the new Wave-grouped shape

The round-2 quality-claude.001 finding established (with a full enumeration of the file's actual `##` sections) that **`## Execution Order` does not exist as a top-level section** in `skills/parallelize/SKILL.md`. "Execution Order" appears only:

- as a bullet inside `## Artifact` (documenting `parallelization.md`'s required output sub-sections), and
- inside the worked-example markdown blocks (which are fenced content under `## Worked Example — Good` etc.).

Design.md DKR4 likewise phrases the removal as *"the 'Execution Order' prose section is removed as redundant"* — with no `##` notation. The author chose the loose phrasing precisely because the actual edit target is the embedded artifact-spec bullet (and the worked-example block), not a top-level section.

The R3 Section Contracts paragraph and the Slice 4 File Map cell therefore disagree about whether a top-level H2 section is being removed:

- Section Contracts (R3): top-level structure preserved → no `##` removal.
- File Map Slice 4 (unchanged since R1): `## Execution Order` removed → top-level removal claimed.

Both can't be true; exactly one of them is wrong about what Phase 1 does to `skills/parallelize/SKILL.md`'s heading structure.

## Why it matters

The structure-quality contract for "Interfaces well-defined" requires that boundary responsibilities be concrete and complete. An internal contradiction about whether a top-level section is being removed is exactly the kind of ambiguity Plan needs resolved before producing line-level edit locators. Two failure modes:

1. **Plan trusts the File Map cell literally.** Then Plan looks for `## Execution Order` as a top-level H2 in `skills/parallelize/SKILL.md`, finds none, and either fabricates a removal that does nothing or stops to escalate. Worst case: Plan removes a different `Execution Order` heading (e.g. the one inside a worked-example fenced block) and silently violates the Section Contracts "top-level structure preserved" promise that Implement and downstream reviewers will hold them to.

2. **Plan trusts the Section Contracts paragraph.** Then Plan reads the File Map cell as imprecise and substitutes its own interpretation (probably: remove the "Execution Order" bullet from the `## Artifact` artifact-spec list, since that's what design DKR4 reads cleanly as). That works, but the structure.md handoff has tolerated a precision/accuracy mismatch that a future R-cycle reviewer or downstream agent would re-flag.

Either way, structure.md fails to give Plan an unambiguous answer on a question structure.md just newly committed itself (via the R3 Section Contracts paragraph) to answering definitively.

This is fundamentally a "no conflicts with existing codebase patterns" issue (the existing file's top-level structure doesn't contain `## Execution Order`) compounded by an internal-consistency issue (the artifact contradicts itself within one round). The fix is small and isolated.

## Suggested resolution

Two options, in decreasing order of preference. Either fully resolves the contradiction.

**Option A — Strip the `##` notation from the Slice 4 File Map cell** (smallest patch; preserves the cell's intent without claiming a top-level removal). Edit line 39's responsibility cell to read:

> Replace the flat three-column Branch Map with `### Wave N` sub-sections (each sub-section contains a Task/Branch/Base mini-table); remove the now-redundant **Execution Order prose** (the bullet in the `## Artifact` artifact-spec list and the corresponding heading inside the worked-example markdown blocks) as subsumed by the Wave sub-section ordering; update the inline "Good" and "Bad" worked-example pairs to the new Wave-grouped shape

This matches design.md DKR4's phrasing (which omits `##`) and the round-2 quality-claude.001 enumeration. The Section Contracts paragraph then remains accurate.

**Option B — Name the touched container in the cell, drop `##`, defer specifics to Plan.** Edit line 39's responsibility cell to read:

> Replace the flat three-column Branch Map with `### Wave N` sub-sections (each sub-section contains a Task/Branch/Base mini-table); within the `## Artifact` artifact-spec list and the worked-example blocks, remove the now-redundant Execution Order prose (subsumed by Wave sub-section ordering); update the inline "Good" and "Bad" worked-example pairs to the new Wave-grouped shape

Either option preserves the Section Contracts paragraph as-is and resolves the contradiction. Per-line locators inside `## Artifact` and inside the worked-example fenced blocks remain Plan's territory and are out of scope for this finding.
