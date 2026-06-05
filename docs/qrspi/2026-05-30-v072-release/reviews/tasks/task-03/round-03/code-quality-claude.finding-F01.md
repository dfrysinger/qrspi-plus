---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [skills/reviewer-protocol/first-party-emission.md:L29, skills/reviewer-protocol/third-party-emission.md:L38, skills/reviewer-protocol/SKILL.md:L53-L61]
artifact: task-03
round: 3
reviewer: code-quality-claude
---

The R3 "schema cross-ref" compression (Fix 2) deletes three normative paragraphs from both `first-party-emission.md` and `third-party-emission.md` and replaces them with a single sentence pointing readers to `skills/reviewer-protocol/SKILL.md ## Finding Schema` as the authoritative source — but two of the three deleted paragraphs were never migrated into `SKILL.md`, so the cross-reference is dangling.

**What was deleted from both siblings (diff lines 191-195 and 216-220):**

1. The 5-field schema enumeration — `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files`, `message`. ✓ This one is in fact covered by `SKILL.md ## Finding Schema` (lines 55-61). The deletion was sound.
2. The audit-fields rule — "**Audit fields** (frontmatter only): `artifact`, `round`, `reviewer` (must equal `<reviewer_tag>` and the filename prefix)." ✗ **Not present anywhere in `SKILL.md`.** A reader following the cross-reference to find the audit fields' names and the load-bearing constraint "`reviewer` must equal `<reviewer_tag>`" will not find them. The constraint survives only as a single trailing sentence in `first-party-emission.md` line 72 ("The `reviewer:` audit-field value MUST equal that prefix") — and as a worked example in the YAML snippets — neither of which is in `SKILL.md` and neither of which lists the three audit-field names together as a normative set.
3. The `finding_id` uniqueness rule — "unique per `(round, reviewer_tag)`. Canonical form `R{NN}-F{NN}`. Schema-guard regex: `^R\d+-F\d+$`." ✗ **Not present anywhere in `SKILL.md`.** `SKILL.md` line 57 mentions `R3-F02` only by example ("e.g. `R3-F02` for round 3 finding 02"); the canonical form is no longer pinned anywhere, and the schema-guard regex `^R\d+-F\d+$` (a normative pattern that downstream consumers can validate against) is now undocumented entirely. The third-party variant also dropped the malformed-output behavioral note ("Malformed output now produces zero finding files for the tag, caught at apply-fix step 2 as 'expected tag produced no output'"), which is real wrong-channel diagnostic content with no equivalent in `SKILL.md`.

The new Fix-2 test (`@test "emission sibling files do not reproduce verbatim schema paragraphs from SKILL.md"`, lines 188-208) passes vacuously w.r.t. this regression — it asserts the magic phrase "canonical 5-field finding schema" is absent from siblings and the literal string "skills/reviewer-protocol/SKILL.md" is present in siblings, but it does not assert that `SKILL.md` actually contains the content the cross-reference claims is there. The dangling pointer therefore slips past CI.

**Suggested fix.** Either (a) migrate the two missing paragraphs into `SKILL.md ## Finding Schema` (add an "Audit fields" sub-paragraph naming `artifact`, `round`, `reviewer` and the `reviewer = <reviewer_tag>` rule; add a "`finding_id` uniqueness" sub-paragraph with the `R{NN}-F{NN}` canonical form and the `^R\d+-F\d+$` schema-guard regex) and then add a CI test that pins those tokens in `SKILL.md` so the cross-reference and its target cannot drift apart again; OR (b) restore the deleted paragraphs in the siblings and narrow the Fix-2 deletion to only the (legitimately duplicated) 5-field schema enumeration. Option (a) is the cleaner end-state because it actually realizes the "SKILL.md is authoritative" property the cross-reference advertises.
