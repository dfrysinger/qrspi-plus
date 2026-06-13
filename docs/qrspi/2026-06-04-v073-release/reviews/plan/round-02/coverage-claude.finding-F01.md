---
reviewer: coverage-claude
finding_id: F01
artifact: plan.md
round: 2
severity: major
change_type: behavioral
category: Test Expectation Quality
task_refs: [T37]
---

## Finding

T37 (`scripts/measure-active-footprint.sh`) test expectations name two
fail-loud failure modes — "unresolvable `!cat` reference" and "circular
`!cat` reference (A→B→A)" — but specify only "surfaces a named
diagnostic" for each, without pinning down the literal diagnostic token.

Compare with how every other code task that uses named-diagnostic
discipline pins the literal string:

- T01: `upstream-paths-unknown-step:`
- T03 / T26 / T27: `sha-format-invalid:` (anchor-file site)
- T17 / T19 (design-reviewer / OBC): `dispatch-defect:`
- T19: `obc-author-name-malformed:`, `sha-format-invalid:`
- T25: `stage-commit-parent-mismatch:`, `sha-format-invalid:`
- T26 / T27: `narrow-round-empty-diff:`
- T28: `version-source-missing-or-malformed:`

The Test skill writes assertions of the form `grep -q '<diagnostic>:'
"$stderr"`. Without a literal token, the test author has to invent one,
and the test no longer locks the script's contract. Two diagnostics that
this task can never observe behaviorally are not testable.

## Tests that cannot be written deterministically

1. "Unresolvable `!cat` reference exits non-zero with diagnostic
   `<X>:`" — `<X>` is not specified, so the grep target is undefined.
2. "Circular `!cat` reference (A `!cat`s B which `!cat`s A) exits
   non-zero with diagnostic `<Y>:`" — `<Y>` is not specified.

Both bullets currently degrade to "exits non-zero with *some* error on
stderr," which is too loose: a future regression that silently swallowed
the cycle and emitted a different-class diagnostic would not be caught.

## Recommended fix

Pin the literal diagnostic tokens in T37's Test expectations the same
way T01/T19/T25/T28 pin theirs. Suggested names following the existing
convention:

- `cat-reference-unresolvable:` for the missing-target case
- `cat-reference-cycle:` for the cycle-detection case

(Names are illustrative; what matters is that whatever tokens land are
literal substrings the Test skill can grep for.)
