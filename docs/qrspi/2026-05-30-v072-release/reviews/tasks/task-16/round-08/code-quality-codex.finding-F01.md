---
finding_id: R8-F01
reviewer_tag: code-quality-codex
severity: low
change_type: style
referenced_files: [tests/unit/test-config-model-routing.bats]
---

# R8-F01 — Reviewer-finding-ID `R7-F01` embedded in a bats test name (ID-hygiene violation)

**Reviewer:** code-quality-codex (gpt-5.3-codex), T16 round-08 correctness fan-out
**Severity:** Low
**Change type:** style (ID hygiene)

## Finding

The fix-7 regression test at `tests/unit/test-config-model-routing.bats:506` carries the
literal reviewer-finding-ID `R7-F01` in its `@test` name:

```
@test "_resolve-lib.sh [exec]: resolve_model HALTS with the config-path diagnostic when CONFIG_MD points at a DIRECTORY (R7-F01 regular-file guard)" {
```

`R7-F01` matches the forbidden Reviewer-finding-ID family `R\d+-F\d+` enumerated in
`skills/implementer-protocol/SKILL.md:100`, and per `:83` QRSPI-internal IDs are
forbidden in **test names** everywhere outside `docs/qrspi/`. `tests/unit/` is outside
`docs/qrspi/`, so this is a genuine ID-hygiene violation — review-round inside-baseball
leaking into shipped test code.

## Adjudication

KEEP. Definitively correct per the explicit `R\d+-F\d+` forbidden-token regex
(implementer-protocol §ID Hygiene, line 100). The same-role Claude reviewer (cq-claude)
cleared this token in error — it checked only the single-letter G/R/D/T/Q family and the
F-N framework vocab, missing that `R\d+-F\d+` is its own separately-listed forbidden
Reviewer-finding-ID family.

## Recommended fix (test-string only; zero production code, zero behavior change)

Rename the `@test` to describe the BEHAVIOR without the review-finding ID, e.g.:
`"_resolve-lib.sh [exec]: resolve_model HALTS with the config-path diagnostic when CONFIG_MD points at a DIRECTORY (readable non-regular path)"`.
While here, reword the comment's RED/GREEN review-iteration narration
(`This FAILS against a [ -r ]-only guard ... PASSES once the [ -f ] ... is added`) to a
behavior-focused rationale (honors the established "no review-iteration narration in
shipped code" preference). Re-run the implementer ID-hygiene self-check before DONE.

## Process note (plugin)

fix-7's implementer authored this test name and should have caught the `R\d+-F\d+` token
in its pre-DONE ID-hygiene self-check (`implementer-protocol/SKILL.md:153`). The
self-check did not fire. Log as a plugin/process finding.
