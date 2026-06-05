# Finding F01

**change_type:** removal (incomplete — retired schema residue)
**severity:** p0
**location:** `skills/plan/SKILL.md:134–136`

## Description

The section heading and introductory paragraph of `### Per-Task Classification` were **not updated** by the G22 migration. The heading still reads:

```
### Per-Task Classification (`task_type` and `model`)
```

And line 136 states:

> Every task spec — whether emitted by the merged-plan subagent or by a per-task sub-subagent — must set `task_type` and `model` in its frontmatter. Assign them in this order, per task. These flags drive Implement-skill routing: `task_type` selects between the TDD implementer and the lightweight implementer; **`model` is forwarded as the per-invocation override on the implementer Agent dispatch.**

This is direct retired-schema residue: any operator reading the heading and first paragraph is instructed to put `model: sonnet` (or `model: opus`) in task frontmatter and to expect Implement to forward it as a per-invocation dispatch argument. The retirement of `model:` and the introduction of `tier:` was correctly implemented in **Step 2** (starting at line 162), but the heading and the intro paragraph that precede it were untouched.

The diff shows a single hunk for `skills/plan/SKILL.md` beginning at line 159 (`@@ -159,19 +159,19 @@`), confirming that lines 134–137 were never touched in this round.

**Why this is blocking (P0):** Plan is the step that emits task frontmatter. Any operator following the heading-level and intro-paragraph guidance will write `model: sonnet/opus` in every task spec. The Implement skill's `### Per-Task Routing` pseudo-code (now correctly updated) reads `task_type` only — but the contradiction between Plan's intro prose ("set model") and Implement's updated routing ("tier-chain, no model:") means the two skills disagree on what the task frontmatter must contain.

## Suggested fix

Update lines 134–136 in `skills/plan/SKILL.md`:

**Heading (line 134):**
```diff
-### Per-Task Classification (`task_type` and `model`)
+### Per-Task Classification (`task_type` and `tier`)
```

**Intro paragraph (line 136):**
```diff
-Every task spec — whether emitted by the merged-plan subagent or by a per-task sub-subagent — must set `task_type` and `model` in its frontmatter. Assign them in this order, per task. These flags drive Implement-skill routing: `task_type` selects between the TDD implementer and the lightweight implementer; `model` is forwarded as the per-invocation override on the implementer Agent dispatch.
+Every task spec — whether emitted by the merged-plan subagent or by a per-task sub-subagent — must set `task_type` and `tier` in its frontmatter. Assign them in this order, per task. `task_type` selects between the TDD implementer and the lightweight implementer. `tier` is the per-task routing signal co-escalated to both the implementer dispatch and the TDD test-writer dispatch (via `--tier-override` through `scripts/_resolve-lib.sh`); it supersedes the retired per-task `model:` field (G22 / design.md CD-1).
```
