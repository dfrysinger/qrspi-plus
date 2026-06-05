# Finding F02

**change_type:** removal (incomplete — stale example after agent-model: sweep)
**severity:** p1
**location:** `skills/plan/SKILL.md:159`

## Description

The Step 1 edge-case bullet for `task_type` classification reads:

> Frontmatter-only edits to `agents/*.md` (e.g. flipping a `model:` value) → `lightweight` per the glob — that change has no runtime behavior to TDD against.

After the G22 migration, no `agents/qrspi-*.md` file carries a `model:` frontmatter field (all four legacy `model_role:` declarations were removed; every agent now carries `tier:` instead). The example "flipping a `model:` value" references a field that no longer exists in agent frontmatter, making the example misleading to future plan authors.

This line was not touched in the diff (the only hunk in `skills/plan/SKILL.md` begins at line 159 in the *context* surrounding the Step 2 change, and this bullet is at line 159 in the file but appears unchanged in the context lines, not as a `+`/`-` diff line).

**Why P1 (not P0):** The underlying rule (frontmatter-only agent edits are `lightweight`) is still correct; only the concrete example name is stale. An operator following the rule won't go wrong; they'll just be confused when they look for a `model:` field to flip and find `tier:` instead.

## Suggested fix

Update line 159 in `skills/plan/SKILL.md`:

```diff
-- Frontmatter-only edits to `agents/*.md` (e.g. flipping a `model:` value) → `lightweight` per the glob — that change has no runtime behavior to TDD against.
+- Frontmatter-only edits to `agents/*.md` (e.g. flipping a `tier:` value) → `lightweight` per the glob — that change has no runtime behavior to TDD against.
```
