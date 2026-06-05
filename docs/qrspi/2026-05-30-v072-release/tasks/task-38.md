---
status: approved
task: 38
phase: 1
pipeline: full
goal_ids: [G35]
task_type: lightweight
model: sonnet
---

# Task 38: G35 Structure reviewers (artifact + scope) enforce architecture-only-in-structure boundary

- **Target files:** modify `agents/qrspi-structure-reviewer.md`; modify `agents/qrspi-structure-scope-reviewer.md`
- **Dependencies:** Task 37
- **LOC estimate:** ~120

**Overview**

Update the Structure artifact-quality and scope-reviewer prompts so they enforce the new Structure ownership boundary for unified system architecture and unified test architecture without flagging valid structure.md content as drift. This is the reviewer-enforcement half of the G35 migration after T37 creates the Structure authoring/shared-boundary surface. (Why: see goals.md ### G35. Approach: see design.md ## G35.)

**Scope**

- **In:**
  - Update `agents/qrspi-structure-reviewer.md` so the artifact-quality reviewer treats a unified system architecture diagram and a top-level `## Test Architecture` section as expected Structure content, not anomalous or out-of-scope content.
  - Update `agents/qrspi-structure-scope-reviewer.md` so the introducer prose appears immediately after the Step 1 Read citation, followed on the next line by `!cat skills/_shared/structure-altitude-boundary.md`.
  - Preserve the Structure altitude boundary: Structure stitches locked Design solutions into architecture/test architecture, but does not re-litigate Design decisions or descend into per-task assertions/unit-test code.
  - Preserve stable audit anchors: `unified system architecture`, `## Test Architecture`, `structure-altitude-boundary`, `Structure OWNS`, `Structure DEFERS`, `per-solution Acceptance`, and `cross-cutting test invariants`.

- **Out:**
  - Creating `skills/_shared/structure-altitude-boundary.md` and updating `skills/structure/SKILL.md` — T37 owns.
  - Authoring or changing the unified system architecture / `## Test Architecture` procedure itself — T37 owns the Structure authoring surface.
  - Adding lint tests or test-code files — existing task text explicitly keeps this reviewer-prompt task to prompt-prose surfaces.
  - Editing other artifact reviewers, other scope reviewers, Design, Plan, or implementation/test-code surfaces.

**Definition of done**

- `agents/qrspi-structure-reviewer.md` no longer carries stale pre-G35 assumptions that architecture diagrams or unified test architecture are anomalous in Structure.
- `agents/qrspi-structure-reviewer.md` positively instructs the reviewer to recognize a unified system architecture diagram and a top-level `## Test Architecture` section as expected Structure content while preserving minimal artifact-quality reviewer duties.
- `agents/qrspi-structure-scope-reviewer.md` contains the required introducer prose immediately after the Step 1 Read citation, followed by the `!cat skills/_shared/structure-altitude-boundary.md` directive on the next line.
- The scope-reviewer update keeps the shared Structure OWNS/DEFERS vocabulary in the reviewer's immediate reasoning context and does not delegate the boundary to optional memory or broad reviewer discretion.
- The prompts preserve the distinction between artifact-quality review and scope/boundary review, with no re-litigation of Design choices and no ownership of per-task assertions or unit-test code in Structure.
- Prompt prose applies R1-R7 plus the cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), including imperative hot-path boundary instructions, rationale only where it explains false-positive drift risk, no generic examples beyond the v0.7.2 mental-replay anchor, no decorative diagrams in prompt prose, and no TODOs/placeholders/stale line-number references.
- No unrelated reviewer-agent or artifact-surface edits are made.

**Test expectations**

- Inspect `agents/qrspi-structure-reviewer.md` for positive obligations that treat `unified system architecture` and `## Test Architecture` as expected Structure content; confirm stale pre-G35 anomaly/drift framing is absent.
- Inspect `agents/qrspi-structure-scope-reviewer.md` to confirm the introducer sentence lands immediately after the Step 1 Read citation and the next line is exactly `!cat skills/_shared/structure-altitude-boundary.md`.
- Grep for the stable audit anchors named in the Definition of done across the two target files, as applicable to each reviewer surface.
- Apply R1-R7 and the cross-cutting principles from `skills/_shared/prompt-design-rules.md` to the prompt prose changes; verify positive reviewer obligations, byte-identical shared-boundary vocabulary for scope reasoning, and separation between artifact-quality review and scope/boundary review.
- Mental-replay check: a v0.7.2 `structure.md` containing a unified system architecture Mermaid diagram plus a top-level `## Test Architecture` section stitching per-goal/per-CD acceptance criteria by test type would not trigger a Structure scope finding under these reviewer prompts.
- Verify no other artifact scope-reviewers, no test-code files, no unrelated Structure procedure text, and no stale line-number references are changed.

**References**

- goals.md ### G35 — problem framing for the Structure-side migration destination and reviewer false-positive failure mode.
- design.md ## G35 — locked OWNS/DEFERS boundary, reviewer edit surfaces, mental-replay acceptance criterion, and non-goals.
- structure.md ### `agents/qrspi-structure-reviewer.md` — artifact-quality reviewer responsibility and mental-replay anchor.
- structure.md ### `agents/qrspi-structure-scope-reviewer.md` — scope-reviewer insertion site, introducer prose, and `!cat` include hook.
