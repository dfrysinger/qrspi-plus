# Spec Review — Task 40 Round 3 — CLEAN

R2/F01 fix verified: the regex in `tests/unit/test-ci-workflow-shape.bats` line 393 now
includes `\.pre-commit-config|\.pre-commit-hooks` alongside the existing
`scripts|\.husky|\.githooks|lefthook` alternation, extending the "no body-guard
references in hook configs" scan to cover pre-commit hook configuration files.

This aligns with task-40.md spec constraints:
- L33 (Out): "Shellcheck rules and pre-commit hooks — explicitly not part of G21"
- L43 (DoD): "no shellcheck rule and no pre-commit hook are added"
- L53 (Test exp.): "confirm no pre-commit hook ... is introduced"

The change is the minimum needed to close R2/F01 and is fully scoped to the existing
target file. No other files modified. No scope creep.
