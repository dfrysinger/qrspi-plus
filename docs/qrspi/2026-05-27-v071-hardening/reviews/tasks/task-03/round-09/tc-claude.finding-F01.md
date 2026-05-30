---
finding: F01
round: 9
reviewer: tc-claude
severity: medium
change_type: missing_test
status: open
---

# F01 — Unreadable-file error path of `extract_section_fence_aware` is never tested

## Location

- **Production code:** `tests/helpers/skill-markdown.bash` lines 229-232
- **Test file:** `tests/unit/test-helpers-skill-markdown.bats` — no test present

## Description

`extract_section_fence_aware` has a documented error path that fires when the
file argument is not readable:

```bash
if [ ! -r "$file" ]; then
  printf 'extract_section_fence_aware: file unreadable: %s\n' "$file" >&2
  return 1
fi
```

This path has its own distinct message text (`file unreadable:`) that
differentiates it from the "not found" and "anchor located but no content"
paths.  Neither a nonexistent file nor a chmod-000 file is used as input in
any test.

The analogous path in the sibling function `extract_section` is also untested,
but the task scope covers `extract_section_fence_aware`.

## Why it matters

A caller that passes a stale or permission-denied path gets a silent failure
if this guard silently regresses to a `return 0` or falls through to awk.
No test would catch the regression.  The three error paths of
`extract_section_fence_aware` are supposed to be distinguishable; without a
test for the unreadable-file path that distinguishability claim is unverified.

## Suggested fix

Add a `@test` for each of the two observable sub-cases:

```bats
@test "[fence-aware-extractor] non-existent file exits non-zero with 'file unreadable' diagnostic" {
  run extract_section_fence_aware "$FIXTURE_DIR/does-not-exist.md" "### Any Anchor"
  [ "$status" -ne 0 ]
  [[ "$output" == *"extract_section_fence_aware:"* ]]
  [[ "$output" == *"file unreadable"* ]]
}

@test "[fence-aware-extractor] chmod-000 file exits non-zero with 'file unreadable' diagnostic" {
  local f="$FIXTURE_DIR/noperm.md"
  printf '### Section\ncontent\n' > "$f"
  chmod 000 "$f"
  run extract_section_fence_aware "$f" "### Section"
  chmod 644 "$f"           # restore before teardown tries to remove it
  [ "$status" -ne 0 ]
  [[ "$output" == *"file unreadable"* ]]
}
```
