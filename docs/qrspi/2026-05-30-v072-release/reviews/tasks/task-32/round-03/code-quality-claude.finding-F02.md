---
finding: F02
severity: minor
reviewer: code-quality-claude
round: 3
files:
  - tests/unit/test-interactive-skill-prompts.bats
---

# F02 — Test names say "prohibits X" but the tests are presence checks, not absence checks

## Location

`tests/unit/test-interactive-skill-prompts.bats` lines 111–121

```bash
@test "design/SKILL.md prohibits placeholder/TODO/to-be-filled bodies in the draft artifact" {
  grep -F "to be filled" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "TODO" "$REPO_ROOT/skills/design/SKILL.md"
  grep -F "placeholder" "$REPO_ROOT/skills/design/SKILL.md"
}

@test "goals/SKILL.md prohibits placeholder/TODO/to-be-filled bodies in the draft artifact" {
  grep -F "to be filled" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "TODO" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "placeholder" "$REPO_ROOT/skills/goals/SKILL.md"
}
```

## Problem

The test names read as absence assertions: "X prohibits Y" implies Y must not appear in X. In fact, the bodies are **presence checks** — they verify that the SKILL.md documents its prohibition by *naming* the forbidden terms. The tests pass when "TODO", "placeholder", and "to be filled" are found in the file; they fail when those strings are absent.

This is the correct test intent: the SKILL.md must explicitly call out these banned patterns so the AI agent knows to avoid them. But the mismatch between the name (sounds like absence) and the body (presence check) violates the single most basic naming obligation for tests: the test name must describe what the test actually asserts. A future maintainer scanning a failing build will read the name, assume the strings are being asserted absent, look for unwanted content in the SKILL.md, and be confused when the failure is in fact the opposite — the strings were removed from the prohibition language.

## Recommendation

Rename both tests to reflect what is actually being checked:

```
"design/SKILL.md explicitly documents the placeholder/TODO/to-be-filled prohibition by name"
"goals/SKILL.md explicitly documents the placeholder/TODO/to-be-filled prohibition by name"
```

Or, using the pattern of the presence-≡-locked section header tests nearby:

```
"design/SKILL.md names the forbidden incomplete-body patterns (to be filled / TODO / placeholder)"
"goals/SKILL.md names the forbidden incomplete-body patterns (to be filled / TODO / placeholder)"
```

Either form makes the assertion direction unambiguous from the name alone.
