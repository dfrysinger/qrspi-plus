# F01 — Missing test: five-field per-goal template not pinned in design/SKILL.md

**Severity:** medium
**Category:** Spec test expectation explicitly unmet
**File:** `tests/unit/test-interactive-skill-prompts.bats`

Spec test expectations item 2 requires that tests pin design/SKILL.md's reference to the five-field per-goal template (Outcome, Solution, Why this approach, Dependencies + edge cases, Acceptance). Implementation prose at design/SKILL.md line 257 lists them, but no test grep pins the field names.

**Required fix:** Add a test:
```bash
@test "design/SKILL.md references the five-field per-goal template fields" {
  grep -F "Outcome" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Why this approach" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Dependencies + edge cases" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "Acceptance" "$REPO_ROOT/skills/design/SKILL.md"
}
```
