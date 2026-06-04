---
finding: F01
severity: minor
reviewer: code-quality-claude
round: 3
files:
  - tests/unit/test-interactive-skill-prompts.bats
---

# F01 — Mixed presence + absence assertions in one `@test` block silently skip the absence check on presence failure

## Location

`tests/unit/test-interactive-skill-prompts.bats` lines 56–62

```bash
@test "goals/SKILL.md carries Rule 3 — Ground first, ask second (codebase then web; no research-summary tier)" {
  grep -F "Ground first, ask second" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "the codebase, then the web" "$REPO_ROOT/skills/goals/SKILL.md"
  # Goals runs before Research; the research-summary grounding tier is Design-only.
  run grep -F "research summary" "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}
```

## Problem

In BATS, a bare `grep` (not wrapped in `run`) that exits non-zero immediately terminates the test block with failure. The two presence checks on lines 57–58 are bare greps; the absence check on lines 60–61 is `run`-wrapped.

If either presence assertion fails first — for example, if a refactor removes or renames the "Ground first, ask second" heading — the `run grep` + `[ "$status" -eq 1 ]` lines are **never executed**. The absence contract (no "research summary" tier in Goals Rule 3) is silently bypassed. A developer who then restores the presence phrase and re-runs tests will see the test pass, unaware that the absence invariant was never evaluated in the failed run.

The three assertions pin **independent behavioral properties** of Goals Rule 3:
1. The rule heading exists.
2. The Goals-specific grounding phrase exists.
3. The research-summary tier is absent.

Property 3 is the unique correctness contract that distinguishes Goals Rule 3 from Design Rule 3. It is the one most at risk of regressing undetected.

## Recommendation

Split property 3 into its own `@test` block. This guarantees it is always evaluated regardless of whether the presence checks pass:

```bash
@test "goals/SKILL.md carries Rule 3 — Ground first, ask second (codebase then web)" {
  grep -F "Ground first, ask second" "$REPO_ROOT/skills/goals/SKILL.md"
  grep -F "the codebase, then the web" "$REPO_ROOT/skills/goals/SKILL.md"
}

@test "goals/SKILL.md Rule 3 does not carry the research-summary grounding tier (Goals-only contract)" {
  [ -f "$REPO_ROOT/skills/goals/SKILL.md" ]
  run grep -F "research summary" "$REPO_ROOT/skills/goals/SKILL.md"
  [ "$status" -eq 1 ]
}
```

The `[ -f ]` guard on the second test mirrors the pattern already used at lines 37–41 for the Rule 5 absence check, ensuring a missing file produces a clear failure rather than a confusing exit-code-2 mismatch.
