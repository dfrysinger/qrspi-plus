---
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files: [tests/unit/test-per-finding-file-emission.bats:L258-L279, skills/reviewer-protocol/SKILL.md:L53-L75, skills/reviewer-protocol/first-party-emission.md:L29, skills/reviewer-protocol/third-party-emission.md:L38]
artifact: code
round: 4
reviewer: silent-failure-claude
---

# Round-4 regression-pin tests are not section-scoped — their names promise an enforcement they do not deliver

## Summary

R4 closes R3-F01 (dangling sibling cross-reference to `SKILL.md ## Finding Schema`) by adding `### finding_id Uniqueness Rule` and `### Audit Fields` subsections under `## Finding Schema` in `skills/reviewer-protocol/SKILL.md`, and adds two regression-pin tests in `tests/unit/test-per-finding-file-emission.bats` (the new tests at lines 258–267 and 269–279). The content addition is complete and the cross-reference resolves correctly today. However, both new pin tests are titled "**SKILL.md `## Finding Schema` documents …**" but their `grep` patterns are run against the **whole file** with no section-extraction step. The siblings' cross-reference is explicitly anchored at `SKILL.md ## Finding Schema — that file is authoritative` (first-party-emission.md:L29, third-party-emission.md:L38), so if a future edit hoists the audit-fields or finding_id-uniqueness content into some other H2 (e.g., a future `## Audit Fields` top-level section, or a merge into `## Reviewer Dispatch Contract` which already mentions both `reviewer:` and `reviewer_tag` on adjacent bullets) the pin tests will silently pass while the sibling cross-reference becomes dangling again — i.e., the exact failure mode R3-F01 raised.

This is a silent-failure surface in the test infrastructure: the test names assert a section-scoped contract, but the implementation only checks file-level presence. The reviewer reading the test output will believe the cross-reference is verified end-to-end when it is only verified at the file granularity. That is the canonical "log-and-continue / silent fallback" pattern transposed into a test pin — the pin appears to enforce the contract but actually enforces a weaker one.

## Concrete failure modes that today's pins do not catch

1. **Hoisting `### Audit Fields` out of `## Finding Schema` into a new top-level H2.** The line at SKILL.md:L75 ("the orchestrator validates `reviewer == <reviewer_tag>` before threading") would still satisfy `grep -qE 'reviewer.*reviewer_tag'` because the grep is unanchored. The sibling cross-reference ("Schema fields, audit fields, and `finding_id` uniqueness rules are as defined in `SKILL.md ## Finding Schema`") would then be dangling for the "audit fields" component — a regression of exactly R3-F01's class.

2. **Hoisting `### finding_id Uniqueness Rule` similarly.** The schema-guard regex `` `^R\d+-F\d+$` `` would still match anywhere in the file, and the canonical-form alternation `R\{NN\}-F\{NN\}|R[0-9]+-F[0-9]+` already matches the pre-existing `R3-F02` example on the schema-field bullet at SKILL.md:L57 (this alternation is effectively a no-op against the round-3 baseline — it would pass even if the entire new subsection were removed, as long as the L57 example survives). Only the schema-guard regex branch does load-bearing work, and even it is not section-scoped.

3. **Audit-field test's substring-overlap fragility.** The audit-fields constraint check `grep -qE 'reviewer.*reviewer_tag'` is single-line and requires "reviewer" *then* "reviewer_tag" left-to-right. Today only L75 matches (L45 in `## Reviewer Dispatch Contract` writes the bullet as `` **`reviewer_tag`** … `reviewer:` audit field `` so the order is reversed and it does not match). But this is a coincidental property of present wording; a rewrite of L45 to "the `reviewer` audit field is set equal to the dispatcher-supplied `reviewer_tag`" would cause that line to match, allowing removal of the audit-fields content from `## Finding Schema` to go undetected.

## Suggested fix

Make both pins section-scoped by extracting the `## Finding Schema` block before grepping. A simple `awk` slice keeps it portable across BSD/GNU:

```bash
local section
section=$(awk '/^## Finding Schema$/{p=1; next} /^## /{p=0} p' "$f")
echo "$section" | grep -qE 'reviewer.*reviewer_tag' \
  || { echo "SKILL.md ## Finding Schema missing 'reviewer = <reviewer_tag>' audit-field constraint"; return 1; }
```

Apply the same slice to the finding_id pin. Optionally tighten the audit-field grep itself to something closer to the actual normative wording (e.g., `MUST equal.*reviewer_tag` or a direct match against `` `reviewer == <reviewer_tag>` ``) so the pin captures the load-bearing claim ("equality is required") rather than just lexical co-occurrence.

While editing, consider dropping the now-redundant canonical-form alternation branch in the finding_id test (or scoping it to the new subsection only) so the test's success condition reflects only what's load-bearing.

## Why this is silent-failure-class and not "nice-to-have"

R3-F01 was exactly a dangling cross-reference into a named SKILL.md section. The R4 fix added the content. The R4 regression pins are the only mechanism preventing R3-F01 from recurring under refactoring. A pin whose name promises section-scoping but whose implementation does not enforce it will *silently* let the regression re-emerge — and the bats output will read "all tests pass" while the sibling files point at a section that no longer carries the referenced content. That is the diagnostic-suppression pattern this reviewer is specifically chartered to surface. Severity is `low` because the immediate-state cross-references all resolve and the current SKILL.md structure is sound; the finding is `correctness` because the test's titled contract does not match its enforced contract, which is the contract-vs-implementation skew the test exists to prevent.
