---
task: 29
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G10, G11]
dependencies: []
loc_estimate: 100
---

# Task 29: Add reviewer-protocol quick-tier finding-disposition guidance and design-skill reference-reviewer checklist

- **Phase:** 1
- **Target files:**
  - `skills/reviewer-protocol/SKILL.md` (Modify) — add quick-tier finding-disposition guidance that distinguishes high and correctness-medium inline patching from low-finding acceptance and prohibits blanket quick-tier merges.
  - `skills/design/SKILL.md` (Modify) — add checklist item: when a design introduces a reviewer whose verdict depends on an external reference artifact, the producing task is flagged `reference_gate: true` in Plan; record lift-verbatim vs. re-derive decision in `design.md`.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Ships the two reviewer-side supporting edits Slice 5 depends on. Edit one (G11 quick-tier wording in `skills/reviewer-protocol/SKILL.md`): adds a quick-tier finding-disposition section that codifies the Keeplii observed-useful pattern — inline-patch high-severity and correctness-medium findings during the quick tier, accept low-severity findings without inline patches, and explicitly prohibit blanket quick-tier merges (a quick-tier batch that accepts every finding without patching the highs and correctness-mediums is a process violation surfaced via a named diagnostic). The wording is owned by the reviewer-protocol body — the section names the disposition rule, the high/correctness-medium inline-patch requirement, the low-finding acceptance carve-out, and the no-blanket-merge prohibition, and is reachable via the protocol's standard section-anchor convention so T30's quick-tier-wording pin can extract it via the shared markdown helper. This edit is independent of UI work but ships in Slice 5 per the design's Decision 6 grouping (G10 and G11 are sibling reference-driven goals; the quick-tier wording is the G11 reviewer-protocol contribution). Edit two (G10/G11 design-skill checklist in `skills/design/SKILL.md`): adds a checklist item to the Design skill's process-step body asserting that when a design introduces a reviewer whose verdict depends on an external reference artifact (prototype screenshot, golden output file, contract fixture, lifted prototype), the producing task MUST be flagged `reference_gate: true` in Plan (the T24 frontmatter contract), AND the design.md MUST record the lift-verbatim-vs-re-derive decision so downstream Structure (T25) and the visual-fidelity reviewer (T28) can ground their decisions in the recorded judgment. Both edits are markdown body only in two skill files; lightweight/sonnet classification holds.
- **Test expectations:**
  - `skills/reviewer-protocol/SKILL.md` contains a quick-tier finding-disposition section codifying inline-patch for high-severity and correctness-medium findings, acceptance for low-severity findings, and prohibition of blanket quick-tier merges.
  - The quick-tier section is reachable via the standard section-anchor convention so the shared markdown helper can extract it.
  - `skills/design/SKILL.md` contains a checklist item asserting that designs introducing reference-dependent reviewers flag the producing task `reference_gate: true` in Plan.
  - The Design-skill checklist item asserts that `design.md` records the lift-verbatim-vs-re-derive decision.
