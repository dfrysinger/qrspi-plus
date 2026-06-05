# Code Quality Review — Task 44, Round 2 — clean

No code-quality findings.

## Summary of changes reviewed

- `skills/using-qrspi/SKILL.md`: one-phrase rewrite ("does not silently
  substitute defaults" → "uses no implicit default substitution") to
  remove the false-positive surface for the extended regex. Minimal and
  semantically equivalent, as explicitly allowed by the task target-files
  clause.
- `tests/unit/test-using-qrspi-vocab.bats`: extends the adverb regex
  alternation from `(fall|degrad)` to `(fall|degrad|substitut)` at all
  four pin sites; comments updated to explain the now-safe `substitut`
  branch.
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`: replaces
  hardcoded synthetic regexes with regexes extracted from the deployed
  unit-pin file via `grep -oE`, then validates semantic-equivalent
  strings via `printf | grep -qE`. Both extractions are guarded by
  `[ -n ... ]` so empty-extraction failure modes trip loudly.

## Quality assessment

- **Single responsibility / decomposition:** each `@test` does one
  thing; extraction logic is local and inline.
- **Naming:** `REGEX_ADVERB`, `REGEX_NOUN`, `pin_file` accurate.
- **Cleanliness:** new comments carry genuine non-obvious WHY content
  (why `substitut` is now safe to add; why `printf | grep -qE` rather
  than `[[ =~ ]]` — bash-3.2 `set -e` exemption on compound commands).
  Legitimate WHY rather than restatement.
- **Self-consistent defenses (§12):** `[ -f "$pin_file" ]`,
  `[ -n "$REGEX_ADVERB" ]`, `[ -n "$REGEX_NOUN" ]` precede the
  semantic-equivalent assertions. Empty/missing extraction fails loudly
  rather than silently passing.
- **DRY:** four near-identical pin blocks remain in the unit test, but
  consolidation is explicitly out-of-scope per the task's Out-clause
  (G24-F01/F02/F03/F04 are moot in v0.7.2). Not flaggable.
- **YAGNI:** regex-extraction-from-deployed-file is more complex than a
  duplicated literal, but the drift-detection rationale is documented
  and aligns with the hardening intent of G24-F05.
- **ID hygiene (§11):** `G24-F05`, `G21`, `C-3` tokens in test names and
  comments are pre-existing in the surrounding file context; the diff
  does not introduce new QRSPI-internal IDs into previously-clean code.
- **Test quality:** assertions verify behavior (regex must trip on
  semantic-equivalent anti-pattern strings); drift-detection via
  extraction is a measurable behavioral check.
- **Mock discipline / file size / structure compliance:** no concerns.
