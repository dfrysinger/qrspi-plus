# Spec Review — Task 44, Round 3: CLEAN

reviewer: spec-claude
round: 3
scope_hint: C-3 regex-extraction harden (lines ~300-320 of test-phase1-acceptance.bats)
verdict: CLEAN

## Summary

The round-3 diff is entirely within the `@test "[Phase1 G24 negative-case C-3]"` block,
lines 303–320 of `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`.
No other test, file, or helper is touched.

## What changed

The old extraction used `head -1` (silently accepted the first match regardless of
how many sites existed or whether they had drifted):

```bash
REGEX_ADVERB=$(grep -oE 'silently\[.*\]\+\(.*\)' "$pin_file" | head -1)
REGEX_NOUN=$(grep -oE '\(.*\)silent\[.*\]\+fallback' "$pin_file" | head -1)
```

The new extraction:
1. Grabs all unique matches (`sort -u`) per regex family.
2. Counts total sites (`grep -cE`) per family.
3. Asserts **exactly 4** sites per family — consistent with the spec's "four existing literal pins".
4. Asserts **exactly 1 unique line** per family (`wc -l | tr -d ' '`) — guards against
   cross-site drift.
5. Assigns the verified uniform regex to `REGEX_ADVERB` / `REGEX_NOUN`; existing
   `[ -n "$REGEX_ADVERB" ]` and `[ -n "$REGEX_NOUN" ]` guards remain in place.

## Spec-alignment checklist

- Completeness: extraction hardening addresses the R2 finding. ✅
- Scope: only lines 303–320 changed; negative-case assertions (lines 322–327) untouched;
  no new files, helpers, or utilities. ✅
- Interpretation: "fail loudly rather than silently passing on the one un-drifted match"
  matches the DoD's "diff stays scoped to the four pin sites" and "semantic negative
  cases trip the pin". ✅
- Test coverage: all three negative cases (`silently degrades to the agent default`,
  `silently substitutes the bundled default`, `no silent fallback to a neighboring tier`)
  remain on lines 323–327, unchanged. ✅
- Technical correctness: `grep … | sort -u` strips trailing newline via command
  substitution; `printf '%s\n'` adds exactly one back; `wc -l` returns 1 for one
  unique result. The empty-string edge case is pre-empted by the count-eq-4 assertion
  that runs first. ✅
- Extra features: count and uniqueness assertions are directly traceable to the spec's
  "four existing literal pins" and "future drift immediately visible" — no speculative
  additions. ✅
- Target files: only `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` is
  modified; that file is explicitly in the task's Target files list. ✅

No findings. Implementation matches the spec for the narrowed C-3 surface.
