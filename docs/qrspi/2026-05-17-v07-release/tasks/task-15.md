---
task: 15
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G7, G18]
dependencies: []
loc_estimate: 180
sizing_exception: reusable primitives
---

# Task 15: Combined G7+G18 hygiene contract in implementer-protocol with preload-only edits to both implementer agent bodies

- **Phase:** 1
- **Target files:**
  - `skills/implementer-protocol/SKILL.md` (Modify) — author the combined `## Hygiene contract` section that codifies the internal-ID forbidden-token list, the evergreen-markdown forbidden-token list, the path-shaped carve-outs, the inline carve-out comments, and the combined pre-DONE self-check.
  - `agents/qrspi-implementer.md` (Modify) — confirm the implementer's existing implementer-protocol preload pulls the new combined hygiene contract and that the pre-DONE step in the agent body invokes the combined self-check.
  - `agents/qrspi-implementer-lightweight.md` (Modify) — same preload-only treatment for the lightweight implementer so prose/doc/config tasks run the same combined self-check.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives
- **Description:** Authors the single combined hygiene contract that satisfies both the internal-ID forbidden-token requirement and the evergreen-markdown forbidden-token requirement in one section of `skills/implementer-protocol/SKILL.md`, with preload-only acknowledgment edits to both implementer agent bodies so the contract reaches the TDD and lightweight dispatch paths through the existing implementer-protocol preload. The new `## Hygiene contract` section in `skills/implementer-protocol/SKILL.md` carries five subsections: a forbidden-token subsection listing the internal-ID regex families (reviewer finding IDs of the form round-N finding-NN, task IDs of the form `T<NN>`, goal IDs of the form `G<N>`, question IDs of the form `Q<N>`, future-goal IDs of the form `F-<N>`, and design decision IDs of the form `D<N>`) that apply to every edited file; a forbidden-token subsection listing the evergreen-markdown regex families (release-version tokens such as `v\d+\.\d+`, milestone wording such as "in v0.7" or "after this release", and PR or issue references used as a justification for current behavior) that apply only to edited markdown; a path-shaped carve-out subsection that exempts `docs/qrspi/**` (the QRSPI artifact directory IS internal addressing), `agents/qrspi-*-reviewer.md` (reviewer agent bodies that document the finding-ID schema), runtime-assembled prompt parameters (in-memory dispatch payloads such as `wave_context:` are not git-tracked files), `docs/qrspi/YYYY-MM-DD-*/**` and `CHANGELOG.md` and `tests/fixtures/**` (dated pipeline artifacts and version-of-record files and version-tagged fixtures); an inline carve-out subsection documenting `<!-- id-hygiene-exempt -->` for the internal-ID rules and `<!-- evergreen-exempt -->` for the evergreen-markdown rules, both applying to the single line carrying the comment; and a pre-DONE self-check subsection that defines one combined scan over the implementer's commit diff added-lines, runs both regex passes, emits one combined report, and is advisory — the commit proceeds whether or not hits are present, but any retained hit must be explicitly acknowledged with reasoning in the DONE report so the reviewer dispatched against the artifact sees the acknowledgment. The `agents/qrspi-implementer.md` and `agents/qrspi-implementer-lightweight.md` edits change only the preload acknowledgment surface — confirming the existing `skills: [implementer-protocol]` preload pulls the new section and that the pre-DONE step the agent body already declares now references the combined self-check by name — without duplicating hygiene contract prose in either agent body, because the protocol is the single source of truth.
- **Test expectations:**
  - The `## Hygiene contract` section in `skills/implementer-protocol/SKILL.md` exists with the five named subsections (internal-ID forbidden tokens, evergreen-markdown forbidden tokens, path-shaped carve-outs, inline carve-outs, pre-DONE self-check).
  - The internal-ID forbidden-token subsection enumerates all six internal-ID families (reviewer finding ID, task ID, goal ID, question ID, future-goal ID, design decision ID) with the corresponding regex shapes.
  - The evergreen-markdown forbidden-token subsection enumerates release-version tokens, milestone wording, and PR or issue references with the corresponding regex shapes.
  - The path-shaped carve-out subsection names `docs/qrspi/**`, reviewer agent files, runtime-assembled prompt parameters, dated pipeline artifacts under `docs/qrspi/YYYY-MM-DD-*/**`, `CHANGELOG.md`, and `tests/fixtures/**` as exempt surfaces.
  - The inline carve-out subsection documents both `<!-- id-hygiene-exempt -->` and `<!-- evergreen-exempt -->` with their single-line scoping rule.
  - The pre-DONE self-check subsection states the scan is advisory, runs one combined pass, applies the internal-ID rules to all edited files and the evergreen-markdown rules to edited markdown only, and requires explicit DONE-report acknowledgment for any retained hit.
  - The pre-DONE self-check subsection specifies the concrete reviewer-visibility mechanism for unacknowledged hits: the DONE-report body is passed as a companion parameter on every per-task reviewer dispatch (so the reviewer's pre-flight reads the DONE-report alongside the artifact under review), AND the per-task reviewer dispatch site explicitly lists the DONE-report file path so reviewers can re-Read it directly — both channels carry the unacknowledged-hit data so reviewer visibility is structurally enforced rather than nominal.
  - `agents/qrspi-implementer.md` preloads `implementer-protocol` and its pre-DONE step references the combined self-check by name without duplicating the hygiene contract prose.
  - `agents/qrspi-implementer-lightweight.md` preloads `implementer-protocol` and its pre-DONE step references the combined self-check by name without duplicating the hygiene contract prose.
