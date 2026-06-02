---
status: approved
task: 30
phase: 1
pipeline: full
goal_ids: [G1]
task_type: lightweight
model: sonnet
---

# Task 30: G1 Design phase decision-completeness template

- **Target files:** modify `skills/design/SKILL.md`
- **Dependencies:** Task 29. **Blocks:** T31 (Design dialog-clarity follow-on), T32 (Goals/Design incremental persistence).
- **LOC estimate:** ~160

**Overview**

Replace the Design skill's under-specified artifact template with a decision-complete per-goal template so downstream Structure and Plan receive outcome, solution, rationale, dependency, edge-case, and acceptance detail instead of filling gaps themselves. The edit installs the G1 Design prompt-prose content in `skills/design/SKILL.md` and removes Design-owned top-level strategy/flow sections whose responsibilities move downstream. (Why: see goals.md ### G1. Approach: see design.md ## G1.)

**Scope**

- **In:**
  - Replace the Design skill's artifact-output prose with G1's `What Design produces` contract: outcome altitude, inline per-goal acceptance, optional per-solution diagrams, and explicit deferral of unified architecture, file maps, unified test architecture, and per-test specification to downstream artifacts.
  - Install the per-goal block template with the required `Outcome`, `Solution`, `Why this approach`, `Dependencies + edge cases`, and `Acceptance` fields, plus the optional per-goal Mermaid diagram rule and top-level `Cross-Goal Decisions` section.
  - Install the Design Dialogue Conduct section and Altitude Sub-Rules A-D content at prompt-prose altitude, preserving the required anchor phrases and the named failure-mode examples from design.md ## G1.
  - Remove the existing Design SKILL.md top-level `## Test Strategy` and `## System Flow` sections so those concepts no longer live in Design's template.
  - Apply R1-R7 and the cross-cutting prompt-prose principles from `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)` to the edited prompt prose.

- **Out:**
  - Multi-actor flow shared snippet creation and downstream include sites in Structure, Plan, Parallelize, and Implement — T28 owns.
  - Design scope-reviewer and `skills/design/owns-defers.md` boundary alignment — T29 owns.
  - Additional Design dialog-clarity tests and narrow G33 follow-on refinements — T31 owns.
  - Goals mirroring and compaction-resilient incremental persistence across Goals and Design — T32 owns.
  - Structure-side absorption of unified architecture and unified test architecture after Design removes those sections — T37 owns Structure authoring; T38 owns Structure reviewer enforcement.
  - Reviewer-agent enforcement changes for the G1 template are out of scope; this task changes Design skill prompt prose only.

**Definition of done**

- `skills/design/SKILL.md` contains a `What Design produces` section matching design.md ## G1's outcome-altitude contract and downstream deferrals.
- `skills/design/SKILL.md` contains the five-field per-goal block template and a `Cross-Goal Decisions` section above per-goal blocks.
- Design Dialogue Conduct is present in the Design skill, including the eight-rule structure from design.md ## G1.
- Altitude Sub-Rules A-D are present with their load-bearing anchors: `Altitude Sub-Rule A — Naming-vs-Layout`, `Altitude Sub-Rule B — Prose-as-Decision`, `Altitude Sub-Rule C — End-to-End Flow`, and `Sub-Rule D — External-Knowledge Completeness`.
- The old Design top-level `## Test Strategy` and `## System Flow` sections are absent from `skills/design/SKILL.md`.
- The edited prompt prose preserves the stable audit phrases `Outcome`, `Solution`, `Why this approach`, `Dependencies + edge cases`, `Acceptance`, `Cross-Goal Decisions`, `Altitude Sub-Rule C — End-to-End Flow`, and `Sub-Rule D — External-Knowledge Completeness`.
- The Design skill prompt contains no TODO/TBD placeholders, stale line-number references, decorative Mermaid instructions, or non-actionable template commentary introduced by this edit.
- The edit does not modify reviewer agents, Goals skill prose, Structure ownership, tests, dispatch parameters, or unrelated Design skill behavior.

**Test expectations**

- Grep audit of `skills/design/SKILL.md` confirms all required anchor phrases from the Definition of done are present exactly where the new Design template/altitude-rule prose lives.
- Grep audit confirms `## Test Strategy` and `## System Flow` no longer appear as top-level sections in `skills/design/SKILL.md`.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)` to the Design prompt-prose edit.
- R1 verification confirms the edit removes non-actionable template commentary while preserving load-bearing decision-completeness rules.
- R2 verification confirms hot-path authoring instructions are imperative, with rationale only for non-obvious downstream-drift risks.
- R3 verification confirms override-critical altitude, no-placeholder, and last-research-bearing-phase rules appear where recency or hard-gate placement makes them visible.
- R4 verification confirms worked examples are limited to the observed failure modes for naming-vs-layout, prose-as-decision, multi-actor flow, and external-knowledge deferral.
- R5 verification confirms required template content is not sharded into optional references.
- R6 verification confirms the skill prompt avoids decorative Mermaid while still allowing generated design artifacts to include per-goal diagrams when useful.
- R7 verification confirms the stable audit phrases listed in the Definition of done are preserved verbatim.
- Cross-cutting prompt-prose review confirms the minimal complete behavior set is present; prohibitions have positive substitutes and named failure modes where needed; and the prose is evergreen, with no dialogue exhaust, TODOs, placeholders, or stale line-number references.

**References**

- goals.md ### G1 — problem framing for decision-under-specified Design artifacts and downstream context loss.
- design.md ## G1 — Design skill outcome/template/dialogue/sub-rule content and implementation deliverables.
- structure.md ### `skills/design/SKILL.md` → Slice 1.5 — target-file block naming the G1 Design SKILL.md outline sections and removals.
