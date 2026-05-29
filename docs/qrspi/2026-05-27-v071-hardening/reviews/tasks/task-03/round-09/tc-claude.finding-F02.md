---
finding: F02
round: 9
reviewer: tc-claude
severity: low
change_type: missing_test
status: open
---

# F02 — Arity guard of `extract_section_fence_aware` is never tested

## Location

- **Production code:** `tests/helpers/skill-markdown.bash` lines 222-225
- **Test file:** `tests/unit/test-helpers-skill-markdown.bats` — no test present

## Description

`extract_section_fence_aware` checks its argument count and returns 1 with a
diagnostic when called incorrectly:

```bash
if [ "$#" -ne 2 ]; then
  printf 'extract_section_fence_aware: expected 2 args (file, anchor-heading); got %d\n' \
    "$#" >&2
  return 1
fi
```

No test in the suite calls the function with 0, 1, or 3 arguments to verify
this guard fires and the diagnostic text is correct.

Contrast with `extract_section`, whose arity guard is also untested — but the
task spec for task-03 explicitly promises coverage for `extract_section_fence_aware`'s
behavioral contract.

## Why it matters

A future refactor that removes the guard (or changes the argument names) would
silently pass all 24 tests.  The arity guard is one of the few lines in the
function that is never reached by any test.  This is a low-risk omission
(incorrect arity is caught at the call site) but the gap means the published
diagnostic text is unverified.

## Suggested fix

One test is sufficient:

```bats
@test "[fence-aware-extractor] wrong argument count exits non-zero with 'expected 2 args' diagnostic" {
  run extract_section_fence_aware "$FIXTURE_DIR/x.md"   # only 1 arg
  [ "$status" -ne 0 ]
  [[ "$output" == *"extract_section_fence_aware:"* ]]
  [[ "$output" == *"expected 2 args"* ]]
}
```
