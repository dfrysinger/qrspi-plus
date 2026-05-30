---
finding_id: R1-F03
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/structure.md:L240-L242]
artifact: structure
round: 1
reviewer: scope-claude
---

The closing sentence of `## CI Pipeline` restates a replan-gate
criterion, which Structure DEFERS to Phasing.

L242 reads: "The replan gate for Phase 1 (per `phasing.md`) requires
this pipeline to pass with zero regressions against the hardening
branch baseline."

Per `skills/structure/owns-defers.md` → DEFERS: "**Phasing /
vertical slice authoring (Iron Law 1, the Phase 1 PoC guideline,
which slices belong in this phase, replan-gate criteria) →
Phasing.**"

"This pipeline must pass with zero regressions against the
hardening branch baseline" is replan-gate criteria phrasing — it
defines a pass/fail condition for the phase, which is exactly what
Phasing owns. Citing `phasing.md` does not make the restatement
in-scope; the restatement itself duplicates a Phasing commitment,
and the two locations can drift apart on future edits.

The preceding paragraph (L240) is correctly in-scope — it names
the workflow file path, declares no workflow changes, and identifies
which jobs cover this release's tests. That paragraph stays.

Resolution: delete L242 (the replan-gate sentence). If a pointer
to Phasing is needed for navigability, replace it with a structural
cross-reference ("Replan-gate criteria live in `phasing.md`.") that
does not restate the criterion itself.

Adjacent lexical signal worth a flag for the editor (not a separate
finding): L7's "Eight vertical slices land together in a single
hardening PR" makes a PR-shape / slice-count assertion. Slice
authoring is Phasing-owned per the same DEFERS bullet. If
`phasing.md` already commits to "eight slices, single PR," this
sentence is a duplicate restatement; if it does not, this sentence
is a Phasing decision being authored in Structure. Either way, the
safer shape is "The slices defined in `phasing.md` share the file
map below" — referencing the upstream commitment without
re-asserting it.
