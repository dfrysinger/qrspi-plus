---
reviewer: code-quality-claude
task: 1
round: 2
finding: F01
severity: minor
change_type: cleanliness
status: pending
referenced_files:
  - tests/unit/test-run-third-party-llm.bats
---

## Stale RED-phase annotations left in test additions

### Summary

The test section added by this task was written in the RED phase (before the
implementation existed) and contains several comments that are now
factually incorrect in the GREEN state. A reader of the test file today
encounters claims that the `_control_char_check` function "does not yet
exist" and that the tests are "genuinely failing against the un-implemented
source" — both false since commit f38344d.

### Affected locations (all in the new test section, `tests/unit/test-run-third-party-llm.bats`)

**Block-level section header (introduced at diff hunk `@@ -341,3 +341,342 @@`, lines ~102–106 of the diff):**

```
# RED rationale: the current code uses `grep -qP '[\x00-\x1f\x7f]' 2>/dev/null`
# which is silently suppressed on macOS system grep (no PCRE support), making
# header-validation a no-op.  On GNU grep, LF is missed because it is grep's
# own record delimiter.  The _control_char_check helper does not yet exist.
# All tests below are genuinely failing against the un-implemented source.
```

The first three lines are good historical WHY context and should be kept.
The last two sentences (`does not yet exist` / `genuinely failing`) are
false after GREEN and should be removed or replaced with a note that these
are now implemented.

**Bullet 5 section comment (diff ~line 252):**
```
# RED: function is absent from current source (not yet implemented).
```

**Bullet 5 inline assertion comment (diff ~line 261):**
```
# RED: _control_char_check is not yet implemented in the dispatcher.
```

**Bullet 6 section comment (diff ~line 290):**
```
# RED: current grep -P loop cannot see NUL (bash strips it from variables).
```
This one is more ambiguous — it describes the old buggy mechanism that made NUL
invisible, which is still useful context. The `RED:` label is nonetheless
misleading post-implementation.

**Bullet 7 section comment (diff ~line 319) and inline test comment (diff ~line 327):**
```
# RED: function absent from current source.
...
# RED: function not yet implemented.
```

**Bullet 8 section comment (diff ~line 337) and inline test comment (diff ~line 346):**
```
# RED: function absent from current source.
...
# RED: function not yet implemented.
```

**Bullet 11 section comment (diff ~line 393) and inline test comment (diff ~line 401):**
```
# RED: function is absent from current source.
...
# RED: function not yet defined in the current source.
```

### Why this matters

Comments that assert a false state ("not yet implemented", "genuinely
failing") mislead future maintainers and create confusion for anyone
reading the test file. The `[ -s "$fn_file" ]` guards remain correct
and useful as presence checks — they just no longer require the `# RED:`
framing to explain why they exist.

### Suggested resolution

1. Remove the last two sentences from the block-level section header
   (`does not yet exist` and `genuinely failing`), preserving the
   historical bug description (grep -P / macOS suppression).
2. Remove all `# RED:` inline and section-level annotations, or replace
   them with neutral phrasing that describes the guard's ongoing purpose
   (e.g., `# Guard: function must be extractable — fails loud if accidentally removed.`).

### What is clean

Everything else in the added code is in good shape:

- `_control_char_check` production implementation: single-responsibility,
  POSIX-portable, well-documented with substantive WHY comments (byte-range
  math, LF-in-command-substitution problem, macOS grep caveat). No `grep -P`.
- NUL raw-byte pre-flight scan: correct mechanism for the bash-strips-NUL
  constraint; clearly commented.
- Per-header loop: clean delegation to `_control_char_check`.
- Test fixture helpers (`_write_ctrl_config`, `_run_ctrl_check`,
  `_extract_ctrl_check_fn`): well-scoped, correct cleanup discipline,
  stub curl is properly placed at the network boundary.
- No ID hygiene issues, no YAGNI, no DRY violations in the new code.
