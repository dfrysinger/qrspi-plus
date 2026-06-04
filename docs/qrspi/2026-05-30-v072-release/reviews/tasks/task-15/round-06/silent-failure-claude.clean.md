# Silent Failure Hunter — Task 15, Round 6 — CLEAN

Reviewed the round-06 diff: three additive grep assertions in
`tests/integration/test-reference-gate-pause.bats` plus one tightened
`extract_and_grep` pattern. No silent-failure defects found.

## Verification notes

- **Worked-example-A "public-symbol rename" assertion (lines 509–510):**
  operates on `$section` set via the two-line exit-code-preserving idiom
  (`local section` declared separately, then `section="$(...)" || return 1`
  at 495–497). `grep -qiE` paired with `|| { echo ... >&2; return 1; }` —
  fail-loud, diagnostic to stderr, return code propagates to the `@test`.

- **Tightened `--` argument-separator pin (line 586):** the `\`` escapes
  yield literal backticks (no command substitution); backtick is literal in
  ERE. Direct `extract_and_grep` call (no `run`) returns 1 with a loud
  `skill-markdown:` diagnostic on miss. Strictly more specific than the prior
  pattern.

- **False-`none` failure-mode assertion (lines 630–631):** operates on the
  already-validated non-empty `$section` (set 621–623 via the same idiom);
  `grep -qE ... || { echo ... >&2; return 1; }` — fail-loud.

All three reuse a `$section` already guarded against empty extract by
`extract_section`'s silent-pass guard, pair every quiet/helper miss with
`return 1` + stderr diagnostic (no swallow, no log-and-continue, no silent
fallback), and assert against real repo files (non-tautological). Pipeline
exit codes resolve to the trailing `grep`, so no masking.
