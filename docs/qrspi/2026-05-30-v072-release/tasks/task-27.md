---
status: approved
task: 27
phase: 1
pipeline: full
goal_ids: [G3, G4, G22, G27]
task_type: lightweight
model: sonnet
---

# Task 27: CD-2 evergreen-output-rule shared snippet and include sites

- **Target files:** `skills/_shared/evergreen-output-rule.md` (create), `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/structure/SKILL.md`, `skills/phasing/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, `skills/using-qrspi/SKILL.md`
- **Dependencies:** none
- **LOC estimate:** ~120

**Overview**

Create the canonical Evergreen-Output Rule snippet and include it in every artifact-producing skill so approved run artifacts describe current decision state rather than dialogue exhaust, drafting history, or rationale-about-the-rationale. The shared snippet keeps this artifact-output quality rule DRY across the highest-volume authoring surfaces and prevents divergent paraphrases as prompt prose evolves. (Why and locked prose: see design.md ### CD-2. Related drift surfaces: see goals.md ### G3, goals.md ### G4, goals.md ### G22, goals.md ### G27.)

**Scope**

- **In:**
  - Create `skills/_shared/evergreen-output-rule.md` as the single source of truth for the Evergreen-Output Rule, using the locked prose from design.md ### CD-2 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
  - Add `!cat skills/_shared/evergreen-output-rule.md` to each artifact-producing consumer in the Target files list: goals, questions, research, design, structure, phasing, plan, parallelize, and replan.
  - Place each include at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location) per structure.md ## Hook-Point Cross-Slice Index → CD-2 evergreen-output-rule `!cat` include sites.
  - Preserve the load-bearing anchor phrases and rule shape: `Litmus test (apply to every paragraph before write)`, `dialogue exhaust`, `Named antagonist patterns — strip on sight, substitute as shown`, the two ordered filters, and the exclusions parenthetical.
  - Keep consumer SKILL.md files DRY: the rule text is included with `!cat`, not copied or paraphrased inline.
  - Author a one-line by-reference pointer to `skills/_shared/evergreen-output-rule.md` from the artifact-quality section of `skills/using-qrspi/SKILL.md` (pointer-only, NOT a `!cat` include, since `using-qrspi` is not an artifact-producing skill — per design.md ### CD-2 acceptance #5 and structure.md ### `skills/using-qrspi/SKILL.md` per-file block).
  - Author the reviewer-protocol enforcement clause in `skills/reviewer-protocol/SKILL.md` so reviewer subagents surface a finding when an artifact carries any of the CD-2 named antagonist patterns (session/drafting notes, version-history narration, inside baseball, compaction-loss recovery, failure-modes-prevented lists, and any other pattern named in the locked `evergreen-output-rule.md` snippet). The clause is inserted alongside (NOT replacing) existing finding-schema/`change_type` requirements and uses the canonical `change_type: style` or `change_type: clarity` enum value per the locked snippet's filter taxonomy.

- **Out:**
  - Canonical cumulative diff helpers, round preparation, and G4 anchor-manifest refreshes — T12 owns.
  - Unified `model_routing:` schema, agent `tier:` migration, and Plan/Test `model:` → `tier:` prose migration — T16 owns.
  - Host-aware second-reviewer availability helper and `second_reviewer:` consumer migration — T19 owns.
  - Dispatch script renames, shared reviewer-dispatch prose, and review-producing skill dispatch include migration — T20 owns.

**Definition of done**

- `skills/_shared/evergreen-output-rule.md` exists at the canonical path and contains the locked Evergreen-Output Rule prose from design.md ### CD-2 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
- The snippet preserves the required anchor phrases, the two ordered litmus-test filters, the exclusions parenthetical, and the named antagonist-pattern table.
- Every artifact-producing consumer in the Target files list contains a `!cat skills/_shared/evergreen-output-rule.md` include at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location).
- No consumer SKILL.md in scope embeds a copied or paraphrased version of the Evergreen-Output Rule; the shared snippet is the only inclusion path.
- The snippet states the rule positively as current-state artifact writing, not only as a ban on history narration.
- The implementation satisfies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), including R5 DRY and positive-substitute guidance.
- `skills/using-qrspi/SKILL.md` carries exactly one by-reference pointer line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality section, with no `!cat` include of the snippet body (per CD-2 acceptance #5).
- `skills/reviewer-protocol/SKILL.md` requires reviewer subagents to surface a finding when an artifact carries any CD-2 named antagonist pattern, alongside (NOT replacing) the existing finding-schema/`change_type` requirements.

**Test expectations**

- File-existence check confirms `skills/_shared/evergreen-output-rule.md` exists.
- Verbatim content check compares `skills/_shared/evergreen-output-rule.md` against the locked prose in design.md ### CD-2 component 3 / structure.md ### `skills/_shared/evergreen-output-rule.md`.
- Grep audit confirms each target consumer contains exactly the shared include line `!cat skills/_shared/evergreen-output-rule.md` at the artifact-output contract section before the artifact template (or equivalent artifact-quality contract location).
- Grep audit confirms the in-scope consumer SKILL.md files do not inline-copy the rule's anchor phrases (`Litmus test (apply to every paragraph before write)`, `dialogue exhaust`, `Named antagonist patterns — strip on sight, substitute as shown`) outside the shared snippet include path.
- Anchor-phrase audit confirms the snippet preserves the required phrases, the two ordered filters, and the exclusions parenthetical.
- Content-semantic review applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` to verify R5 DRY, positive-substitute framing, anchor-phrase preservation, and load-bearing clarity for the ordered filters and exclusions parenthetical.
- Grep audit of `skills/using-qrspi/SKILL.md` confirms exactly one pointer line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality section and zero occurrences of `!cat skills/_shared/evergreen-output-rule.md` (pointer-only contract per CD-2 acceptance #5).
- Grep audit of `skills/reviewer-protocol/SKILL.md` confirms the antagonist-pattern enforcement clause is present and references the CD-2 named patterns vocabulary from the locked `skills/_shared/evergreen-output-rule.md` snippet (no duplicated antagonist-pattern list — the reviewer clause cites the snippet rather than copying it).

**References**

- goals.md ### G3 — shell-pipeline splitter collapse drift surface that motivates shared, vendor-neutral skill prose instead of repeated inline rituals.
- goals.md ### G4 — canonical diff-helper drift surface that motivates replacing repeated orchestrator prose with reusable primitives.
- goals.md ### G22 — model-routing schema drift surface that motivates single-source prose across multiple consumers.
- goals.md ### G27 — Goals-side consumer drift surface that motivates canonical helper/prose reuse.
- design.md ### CD-2 — Evergreen-Output Rule scope, locked snippet prose, consumer list, and acceptance criteria.
- design.md ## G3 / design.md ## G4 / design.md ## G22 / design.md ## G27 — related design context for the Goal IDs carried by this cross-cutting task.
- structure.md ### `skills/_shared/evergreen-output-rule.md` — source file block and full-file-body lift from design.md ### CD-2.
- structure.md ## Hook-Point Cross-Slice Index → CD-2 evergreen-output-rule `!cat` include sites — consumer placement table for the nine artifact-producing SKILL.md files.
