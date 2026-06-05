---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-verifier-agent-file.bats:81
  - agents/qrspi-finding-verifier.md:47
artifact: task-06
round: 2
reviewer: spec-codex
---

# F01 — Residual vacuous regex alternative in `score:`-requirement test (medium · correctness)

**Title:** `score:`-requirement test is still partially vacuous and can pass without asserting a `score:` field

**Why:** Task 06 requires tests to pin a required `score:` frontmatter field (tasks/task-06.md:28, :43). In `tests/unit/test-verifier-agent-file.bats:81`, the regex for that check includes a loose alternative `integer 0.{0,3}100` that does not require `score` at all — so the test can pass from unrelated text matching the alternative alone.

**Evidence:**
- `tests/unit/test-verifier-agent-file.bats:81` uses: `score.*integer.*0.*100|score.*int.*0.*100|integer 0.{0,3}100|score:.*<int.*0.{0,3}100>`
- `agents/qrspi-finding-verifier.md:47` contains `Emit any integer in \`0..100\``, which can satisfy the loose `integer 0.{0,3}100` branch even if a required `score:` frontmatter assertion were removed.

**Spec reference:**
- `tasks/task-06.md:28` — tests must pin required `score:` field
- `tasks/task-06.md:43` — test file must assert required `score:` field

**Recommended fix:** Tighten the test to require both `score` and range/type signals in the same match — remove the standalone `integer 0.{0,3}100` alternative from the disjunction.

**Context:** This is a residual from R2's vacuous-regex sweep (sf-codex R1 F01/F02/F03). R2 tightened three of the regexes but missed this fourth alternative which still leaks the integer-range signal as a standalone match. Small surgical R3 fix.
