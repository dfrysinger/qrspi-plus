# F02 — Missing tests: Goals existing-structure preservation not pinned

**Severity:** medium
**Category:** Spec test expectation explicitly unmet (3 items)
**File:** `tests/unit/test-interactive-skill-prompts.bats`

Spec test expectations item 3 requires tests pinning that goals/SKILL.md preserves: existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step. Sections survive on disk but no test asserts so.

**Required fix:** Add three tests:
```bash
@test "goals/SKILL.md preserves the Interactive Dialogue question-topic checklist" {
  grep -F "Questions to cover" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md preserves the Pipeline Mode Selection step" {
  grep -F "Pipeline Mode Selection" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md preserves the existing per-goal template fields" {
  grep -F "Problem" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "Why we care" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "What we know so far" "$REPO_ROOT/skills/goals/SKILL.md"
}
```
