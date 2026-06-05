# Finding F01 — Stale `### Per-Task Routing` section in `skills/implement/SKILL.md` not migrated

**Reviewer:** spec-claude  
**Round:** 2  
**Severity:** correctness  
**Change-type:** correctness

---

## Location

`skills/implement/SKILL.md` lines 499–519

---

## Problem

The `### Per-Task Routing` section was **not updated** by the Task 16 fix. The new
`#### Tier Resolution Chain` section was inserted immediately below it (line 525+), but
the old section was left intact, creating direct contradictions in active skill prose.

Specific stale references:

| Line | Stale text | Violation |
|------|-----------|-----------|
| 499 | `### Per-Task Routing (\`task_type\` and \`model\`)` | Heading still advertises old `model` field |
| 501 | "main chat reads `task_type` and `model` from the task's `tasks/task-NN.md` frontmatter" | Still instructs reading superseded `model:` field |
| 505 | `model ∈ {sonnet, opus}` | Old per-model-name language (G22-retired) |
| 516 | `dispatch: Agent({ subagent_type: implementer_subagent, model: <model> })` | Still passes old `model:` argument to Agent dispatch |
| 519 | "Tasks that omit `task_type:` and `model_role:` default to `code` / `sonnet`" | References superseded `model_role:` key and hardcoded `sonnet` default |

---

## Spec Requirements Violated

From task-16.md:

> "Rewrite the G22 surfaces in `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md`: remove the old per-host `haiku`/`sonnet`/`opus`/`inherit` schema … emit per-task `tier:` instead of `model:`"

> Definition of done: "`skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md` no longer document or consume the superseded schema fields"

> Definition of done: "…no dispatch prose instructs authors to use `model_role:` for routing."

---

## What Was Done (Correct but Incomplete)

The fix correctly added `#### Tier Resolution Chain` at line 525, documenting the new
precedence logic (`--tier-override → agent tier: → default_tier: → hardcoded medium`).
However the preceding `### Per-Task Routing` block (lines 499–519) was left verbatim from
the pre-G22 state. Both sections now co-exist and contradict each other: the old section
says dispatch uses `model ∈ {sonnet, opus}` and `model_role:`, while the new section says
dispatch resolves through the tier chain.

---

## Test Coverage Gap

The existing tests do not catch this stale block:

- `"implement: role-keyed G5 routing matrix (model_role: column) is gone"` — searches for
  `"model_role:.*Default route\|model_role.*Tier\|Initial Routing Matrix"`, which does NOT
  match the bare `model_role:` usage at line 519.
- `"implement: hardcoded Agent model: sonnet dispatch arguments are gone"` — searches for
  `model: "sonnet"` (quoted), which does NOT match `model: <model>` at line 516 or the
  unquoted `sonnet` at line 519.

A new test should check that the `### Per-Task Routing` section heading no longer references
`model` (e.g., `grep -c "Per-Task Routing.*model\b" "$IMPLEMENT"` → 0) and that `model_role:`
does not appear in active dispatch guidance prose.

---

## Required Fix

Replace `### Per-Task Routing (`task_type` and `model`)` (lines 499–519) with an updated
section that:
1. Renames the heading to `### Per-Task Routing (\`task_type\` and \`tier\`)`
2. Replaces `model ∈ {sonnet, opus}` pseudocode with `tier ∈ {low, medium, high}` (or
   removes the pseudocode if the `#### Tier Resolution Chain` section below now fully covers it)
3. Removes `model: <model>` from the dispatch pseudocode (tier-based resolution is
   described in the section immediately below)
4. Rewrites line 519 to remove `model_role:` and `sonnet` references
