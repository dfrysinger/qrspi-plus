# F01 — Goals-absence bats test silently passes if `skills/goals/SKILL.md` is missing/renamed

**Category:** Missing Error Path / Silent Fallback (test-as-contract)
**Severity:** Low–Medium
**File:** `tests/unit/test-interactive-skill-prompts.bats` lines 19–23

## What the diff adds

```bats
@test "goals/SKILL.md does not carry the Rule 5 simple-language-and-context phrase (Design-only scope)" {
  run grep -F "Use simple language and provide context when presenting ideas" \
    "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -ne 0 ]
}
```

## Silent-failure mode

`grep` returns:

- `0` — pattern found (assertion fails — correct)
- `1` — pattern not found (assertion passes — intended)
- `2` — file unreadable / missing / permission error (assertion **also** passes — silent failure)

`[ "$status" -ne 0 ]` accepts both 1 and 2 indistinguishably, so the absence
contract this test is meant to enforce passes vacuously if
`skills/goals/SKILL.md` is renamed, moved, deleted, or temporarily unreadable.
The Design presence test on lines 14–17 does not have this issue because bare
`grep` (no `run`) propagates the non-zero exit and bats fails the test — but
absence tests inherently require `run`, which inverts that safety property.

## Why it matters for T31 / T32

The task definition explicitly defers Goals dialogue-conduct subset coverage to
T32 (`Out:` bullet 3). If T32 or any later task relocates or splits
`skills/goals/SKILL.md`, this Design-only-scope guard will continue to "enforce"
absence while actually testing nothing, allowing the Rule 5 phrase to leak into
the new Goals prose location undetected. The same pattern is likely to be
templated for additional absence contracts (Replan, Phasing, Structure per the
G33 explicit-out list), compounding the silent-failure surface.

## Suggested fix

Distinguish "phrase absent" (status 1) from "couldn't read file" (status 2),
and pin file existence:

```bats
@test "goals/SKILL.md does not carry the Rule 5 simple-language-and-context phrase (Design-only scope)" {
  [ -f "$REPO_ROOT/skills/goals/SKILL.md" ]
  run grep -F "Use simple language and provide context when presenting ideas" \
    "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}
```

The `-eq 1` form directly rejects the IO-error path; the `-f` precondition
makes the intended file an explicit dependency rather than an implicit one
swallowed by grep's exit code.

## Other categories

No other silent-failure categories apply to the diff: it contains no error
handling, no async / external calls, no state mutation, no error transformation,
no log-and-continue paths, and no partial-state surfaces. Categories §1, §4, §5,
§6 are N/A for a docs+bats-grep change of this shape.
