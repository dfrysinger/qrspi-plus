# Spec Reviewer (claude) — Task 31, Round 02 — CLEAN

Round-02 diff is scoped to `tests/unit/test-interactive-skill-prompts.bats` only,
matching the scope hint. Three small edits, all consistent with task-31 DoD:

1. Test name and comment header dropped the `(G33)` tag — cosmetic; the
   `Design-only scope` annotation and the literal-phrase pin still encode the
   G33 contract. No DoD anchor lost.
2. Added `[ -f "$REPO_ROOT/skills/goals/SKILL.md" ]` precondition on the Goals
   absence test — prevents a false pass if the file is missing (in which case
   `grep -F` would also exit non-zero and the prior `-ne 0` check would have
   silently approved).
3. Tightened the absence assertion from `[ "$status" -ne 0 ]` to
   `[ "$status" -eq 1 ]` — distinguishes "no match" (grep exit 1) from "grep
   error" (exit 2), making the absence contract stricter.

Verified:
- Design presence test still asserts the literal Rule 5 phrase
  (`Use simple language and provide context when presenting ideas`) in
  `skills/design/SKILL.md` (line 32–33).
- Goals absence test still asserts the same phrase is absent from
  `skills/goals/SKILL.md` (line 38–40).
- No unrelated dialog-conduct assertions were added — DoD constraint
  ("without adding unrelated dialog-conduct assertions") satisfied.
- Target files honored: only `tests/unit/test-interactive-skill-prompts.bats`
  changed in this round, which is in the task's Target files list.
- Nothing observed outside the scope hint that warrants broadening.

No findings.
