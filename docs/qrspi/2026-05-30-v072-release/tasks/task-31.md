---
status: approved
task: 31
phase: 1
pipeline: full
goal_ids: [G33]
task_type: lightweight
model: sonnet
---

# Task 31: G33 Design skill interactive dialog clarity

- **Target files:** skills/design/SKILL.md (modify), tests/unit/test-interactive-skill-prompts.bats (modify)
- **Dependencies:** Task 30. **Blocks:** T32 (Goals/Design dialogue authoring quality and compaction-resilient incremental persistence).
- **LOC estimate:** ~90

**Overview**

Make the Design skill's interactive discussion prose require simple language and grounding context when presenting candidate approaches, especially trade-off lists and newly introduced technical terms. This is a narrow Design-only follow-on to Task 30's Dialogue Conduct scaffold: it preserves G33's literal clarity rule and keeps broader interactive-skill scoping out of v0.7.2. (Why: see goals.md ### G33. Approach: see design.md ## G33 and design.md ## G1 → Dialogue Conduct Rule 5.)

**Scope**

- **In:**
  - Preserve the literal Rule 5 anchor phrase *"Use simple language and provide context when presenting ideas"* in `skills/design/SKILL.md`.
  - Make Rule 5 operational in the Design dialogue hot path: ground concrete scenarios before abstract names, provide one sentence of context for newly introduced project/domain terms not present in recent turns, and explain A/B/C trade-offs in plain prose before naming architectural shapes.
  - Keep the rule Design-only by ensuring the literal phrase does not appear in `skills/goals/SKILL.md` or other interactive skill prose.
  - Update `tests/unit/test-interactive-skill-prompts.bats` only to pin the Design presence / Goals absence contract for the Rule 5 phrase.

- **Out:**
  - Creating the CD-3 multi-actor-flow-check shared snippet and include sites for Structure / Plan / Parallelize / Implement — T28 owns.
  - Authoring the broader Design Dialogue Conduct scaffold and other G1 Design-skill sections — T30 owns; T31 only sharpens G33 / Rule 5 behavior.
  - Adding Goals dialogue-conduct subset coverage, direct incremental writes, compaction-resume diagnostics, or finalize-pass behavior — T32 owns.
  - Broadening the simple-language/context rule to Goals, Replan, Phasing, or Structure in v0.7.2 — explicitly out of scope per G33.

**Definition of done**

- `skills/design/SKILL.md` contains the literal phrase *"Use simple language and provide context when presenting ideas"* in the Design Dialogue Conduct Rule 5 surface.
- Rule 5 includes concrete hot-path imperatives for scenario grounding before abstract names, one-sentence context for newly introduced technical terms not present in recent turns, and plain-prose trade-off explanations before architectural labels.
- The prose applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention): no self-host-history bloat, no maintainer commentary, no redundant restatement of Dialogue Conduct, rationale only for the opaque-framing failure mode, examples only if contrastive and observed-failure-based, and lexical anchors around `presenting ideas`, `technical term`, `recent turns`, and `trade-off framings` remain intact.
- `skills/goals/SKILL.md` and other interactive skill prose do not contain the literal Rule 5 phrase.
- `tests/unit/test-interactive-skill-prompts.bats` pins the Design presence / Goals absence contract without adding unrelated dialog-conduct assertions.

**Test expectations**

- Grep audit confirms `skills/design/SKILL.md` contains the literal phrase *"Use simple language and provide context when presenting ideas"*.
- Grep audit confirms `skills/goals/SKILL.md` does not contain that literal phrase; if other interactive skill prose is touched, audit it for the same absence contract.
- Test inspection confirms `tests/unit/test-interactive-skill-prompts.bats` only adds/updates assertions for Design presence and Goals absence of the Rule 5 phrase.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) to the changed prose and verifies the specific DoD anchors and anti-bloat constraints.

**References**

- goals.md ### G33 — problem framing and user directive for simple-language/context Design dialogue.
- design.md ## G33 — G33 traceability, Design-only scope, and acceptance folded into G1 Rule 5.
- design.md ## G1 → Dialogue Conduct Rule 5 — verbatim operational rule text and Goals mirror exclusion.
- structure.md ### `skills/design/SKILL.md` — Slice 1.5 Design SKILL responsibilities for G1/G30/G31/G33, including Rule 5.
- structure.md ### `tests/unit/test-interactive-skill-prompts.bats` — tests pin Design Rule 5 presence and Goals absence.
