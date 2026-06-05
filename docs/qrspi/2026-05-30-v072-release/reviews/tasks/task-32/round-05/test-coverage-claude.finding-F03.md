---
reviewer: test-coverage-claude
task: 32
round: 5
finding_id: F03
severity: low
category: missing-scenarios
files:
  - tests/unit/test-interactive-skill-prompts.bats
---

# F03 — "Optionally appends Purpose if absent" finalize behavior is not pinned for Goals

## What the spec requires

Task-32 Test Expectations (line 57) and DoD (line 46) both call out a
specific finalize behavior unique to Goals:

> "Goals validates locked goal completeness, **optionally appends
> Purpose if absent**, and flips `status: draft` to `approved`."

The production code at `skills/goals/SKILL.md` implements this as:

```
- Optionally append a Purpose section if absent.
```

## What the tests actually pin

Nothing. There is no assertion in
`tests/unit/test-interactive-skill-prompts.bats` that mentions
`Purpose`, `append`, or any variant of the optional-purpose behavior.

This is the only finalize-pass bullet item from the Goals DoD that has
no corresponding test anchor.

## Why this matters (and why this is Low not Medium)

This is a relatively soft contract (`optionally` — the finalize pass
does not fail if Purpose is absent), so it does not gate the status
flip. However, it is the only sentence in the finalize pass that gives
Goals a distinct end-of-phase semantic from Design, and Test
Expectations explicitly enumerates it. If a future edit removed the
bullet, the suite would not catch it.

## Suggested fix

Add a one-line anchor to the existing Goals finalize test:

```bash
grep -F "Optionally append a Purpose section if absent" \
  "$REPO_ROOT/skills/goals/SKILL.md"
```

The phrase is unique to the finalize block in `goals/SKILL.md`.
