---
status: approved
task: 26
phase: 1
pipeline: full
goal_ids: [G31]
task_type: lightweight
model: sonnet
---

# Task 26: G31 prompt-prose include sites across Design, Plan, and reviewer agents

- **Target files:** `skills/design/SKILL.md`, `skills/plan/SKILL.md`, `agents/qrspi-implementer-lightweight.md`, `agents/qrspi-design-reviewer.md`, `agents/qrspi-design-scope-reviewer.md`, `agents/qrspi-plan-test-coverage-reviewer.md`
- **Dependencies:** Task 25
- **LOC estimate:** ~140

**Overview**

Plumb the G31 prompt-prose primitives from T25 into the Design, Plan, lightweight-implementer, and reviewer surfaces that classify, author, or review prompt prose without copying the shared rule prose into each consumer. This task enforces the shared detection/writer/reviewer architecture at the listed include/preload sites while preserving prompt prose as a lightweight, non-TDD deliverable class. (Why: see goals.md ### G31. Approach: see design.md ## G31.)

**Scope**

- **In:**
  - Add the Design authoring-step includes in `skills/design/SKILL.md`: `!cat skills/_shared/prompt-prose-detection.md` followed by `!cat skills/_shared/prompt-prose-writer-addition.md` at the `<!-- prose-design: ... -->` prompt-prose authoring site.
  - Replace `skills/plan/SKILL.md` Per-Task Classification Step 1 with Addition A, including the canonical detection `!cat`, so prompt prose classifies as `task_type: lightweight` by content semantics rather than path-only heuristics.
  - Insert detection + writer-addition + Addition B at both `skills/plan/SKILL.md` writer-subagent dispatch payload sites before the standard Test-Expectations instructions, while leaving the post-approval-split sub-subagent outside this clause.
  - Append `prompt-prose-writer` to `agents/qrspi-implementer-lightweight.md` `skills:` frontmatter and avoid duplicate body prose for the shared writer rules.
  - Append `prompt-prose-reviewer` to `agents/qrspi-design-reviewer.md` `skills:` frontmatter and add Addition D in the review-procedure body as the design.md per-block refinement after preload-triggered shared reviewer context.
  - Keep `agents/qrspi-design-scope-reviewer.md` aligned with its structure-defined include behavior while not restating G31 prompt-prose rule prose verbatim.
  - Add Addition C at the top of `agents/qrspi-plan-test-coverage-reviewer.md` review procedure, keep `prompt-prose-reviewer` absent from its `skills:` frontmatter, and silently skip `task_type: lightweight` tasks.

- **Out:**
  - Creating or migrating the G31 primitive files (`prompt-prose-detection`, `prompt-prose-writer-addition`, `prompt-prose-reviewer-addition`, `prompt-design-rules`, and wrapper SKILLs) — T25 owns.
  - Refreshing the prompt-design rules file and deleting `docs/prompt-design-guide.md` — T25 owns.
  - Adding Evergreen-Output Rule include sites in overlapping Design/Plan skills — T27 owns.
  - Adding Multi-Actor Flow Check include sites in overlapping Plan surfaces — T28 owns.
  - Implementing the Design altitude-boundary primitive and scope-reviewer `!cat` insertion — T29 owns; this task only prevents duplicate G31 prompt-prose rule prose in `agents/qrspi-design-scope-reviewer.md`.
  - Adding prompt-prose reviewer preloads to reviewer agents not listed in this task's Target files.
  - Adding executable RED tests for prompt prose; prompt-prose verification is rules-application review, not TDD execution.

**Definition of done**

- `skills/design/SKILL.md` contains the two G31 authoring-step `!cat` directives in the required order: detection, then writer-addition.
- `skills/plan/SKILL.md` has Replacement-not-additive Addition A at Per-Task Classification Step 1 and both writer-subagent dispatch payload sites carry detection + writer-addition + Addition B before standard Test-Expectations instructions.
- `agents/qrspi-implementer-lightweight.md` frontmatter preloads `[implementer-protocol, prompt-prose-writer]` and does not duplicate the shared writer rules in its body.
- `agents/qrspi-design-reviewer.md` frontmatter preloads `prompt-prose-reviewer` and its body carries Addition D after the preload-triggered shared reviewer context.
- `agents/qrspi-design-scope-reviewer.md` does not restate G31 prompt-prose rule prose and remains compatible with its separately-owned structure-defined include behavior.
- `agents/qrspi-plan-test-coverage-reviewer.md` begins its review-procedure section with Addition C, has no `prompt-prose-reviewer` preload, and skips lightweight tasks instead of emitting missing-RED-test findings.
- Every consumer site uses canonical `!cat` directives or `skills:` preload of the appropriate wrapper SKILL; no consumer restates the shared prompt-prose rule prose verbatim.
- Each inline addition preserves the relevant anchor behavior from design.md ## G31: Plan Step 1 is replacement-not-additive, positive-substitute principle appears in inline additions, and agent files use `skills:` preload where `!cat` is not the mechanism.

**Test expectations**

- Grep `skills/design/SKILL.md` for `!cat skills/_shared/prompt-prose-detection.md` immediately followed by `!cat skills/_shared/prompt-prose-writer-addition.md` at the `<!-- prose-design: ... -->` authoring step.
- Grep/diff `skills/plan/SKILL.md` to verify the old path-glob-only Step 1 paragraph was replaced, not appended to, by Addition A including the canonical detection `!cat`.
- Grep both `skills/plan/SKILL.md` writer-subagent dispatch payload sites for detection + writer-addition + Addition B before the standard Test-Expectations instructions; verify the post-approval-split sub-subagent lacks Addition B.
- Inspect `agents/qrspi-implementer-lightweight.md` frontmatter for `skills: [implementer-protocol, prompt-prose-writer]` and grep the body to confirm it does not copy the shared writer-rule prose.
- Inspect `agents/qrspi-design-reviewer.md` frontmatter for `prompt-prose-reviewer`; grep the body for Addition D anchor phrases `one strong signal but not the only one` and `content semantics determine the call` after the preload context.
- Inspect `agents/qrspi-design-scope-reviewer.md` to confirm it has no verbatim G31 prompt-prose rule-prose copy while preserving its structure-defined include behavior.
- Inspect `agents/qrspi-plan-test-coverage-reviewer.md` to confirm Addition C's `Scope: only \`task_type: code\` tasks.` appears at the top of the review-procedure section and `prompt-prose-reviewer` is absent from `skills:` frontmatter.
- Run a grep audit across the six target files confirming shared prompt-prose bodies are consumed only by canonical `!cat` or `skills:` preload and not duplicated verbatim.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application, including R5 shared-spine/DRY, anchor-phrase usage for snippet/include paths, positive-substitute principle in inline additions, agent `skills:` preload use, and Plan Step 1 replacement-not-additive behavior per design.md ## G31.

**References**

- goals.md ### G31 — problem framing for prompt-prose review coverage gaps across SKILL.md files, agents, and `design.md` prose-design blocks.
- design.md ## G31 — shared prompt-prose architecture, Additions A-D, Distribution Table, explicit non-consumers, and TDD/lightweight boundary.
- structure.md ### `skills/design/SKILL.md` — Consumer #3 authoring-step detection + writer-addition include site.
- structure.md ### `skills/plan/SKILL.md` — Consumer #1 Addition A and Consumer #2 writer-subagent Addition B include sites.
- structure.md ### `agents/qrspi-implementer-lightweight.md` — Consumer #4 `prompt-prose-writer` frontmatter preload.
- structure.md ### `agents/qrspi-design-reviewer.md` — Consumer #6 `prompt-prose-reviewer` preload plus Addition D refinement.
- structure.md ### `agents/qrspi-design-scope-reviewer.md` — separately-owned scope-reviewer include behavior that must not be polluted with duplicated G31 rule prose.
- structure.md ### `agents/qrspi-plan-test-coverage-reviewer.md` — Consumer #9 Addition C standalone scope guard and no-wrapper-preload invariant.
- structure.md ## Hook-Point Cross-Slice Index → G31 prompt-prose `!cat` include sites — cross-file sweep point for prompt-prose include/preload drift detection.
