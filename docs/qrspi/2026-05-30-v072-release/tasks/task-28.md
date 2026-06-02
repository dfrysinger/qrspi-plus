---
status: approved
task: 28
phase: 1
pipeline: full
goal_ids: [G1, G30, G33]
task_type: lightweight
model: sonnet
---

# Task 28: CD-3 multi-actor-flow-check shared snippet and include sites

- **Target files:** create `skills/_shared/multi-actor-flow-check.md`; modify `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/implement/SKILL.md`
- **Dependencies:** none
- **LOC estimate:** ~110

**Overview**

Create the shared Multi-Actor Flow Check snippet and include it in the four downstream skills that turn design decisions into file maps, task specs, parallelization plans, or implementation dispatches. The task makes missing multi-actor choreography a hard stop instead of letting downstream consumers invent hand-offs. (Why: see goals.md ### G1 and design.md ## G1 → Altitude Sub-Rule C. Contract: see design.md ### CD-3.)

**Scope**

- **In:**
  - Author `skills/_shared/multi-actor-flow-check.md` as the canonical shared snippet, with the locked body from design.md ### CD-3 / structure.md ### `skills/_shared/multi-actor-flow-check.md`.
  - Preserve the snippet's self-contained actor definition, six choreography elements, STOP diagnostic, Backward Loops / documented-assumption alternatives, and Iron law.
  - Add exactly one `!cat skills/_shared/multi-actor-flow-check.md` include to each consumer: `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, and `skills/implement/SKILL.md`.
  - Place each include at that skill's `## Multi-Actor Flow Check` / per-decision authoring gate so Structure, Plan, Parallelize, and Implement each run the check independently.

- **Out:**
  - Replacing the Design skill template, including G1's per-goal block shape and Altitude Sub-Rules A-D — T30 owns.
  - Adding the Design simple-language dialogue rule and its unit-test assertions — T31 owns.
  - Adding Goals/Design incremental persistence, resume-after-compaction behavior, and finalize semantics — T32 owns.
  - Refactoring G1 Sub-Rule C itself to `!cat` this snippet — explicitly optional follow-up in design.md ### CD-3, not required for v0.7.2.
  - Editing unrelated sections in the consumer SKILL.md files, including reviewer-dispatch, evergreen-output, schema/tier, and per-task review-cycle surfaces owned by other tasks.

**Definition of done**

- `skills/_shared/multi-actor-flow-check.md` exists and contains the locked CD-3 snippet content, including the anchor phrases `Multi-Actor Flow Check`, `where "actor" means anything that performs an operation and hands off to another`, `STOP`, and `Iron law: silently inventing a missing hand-off is a contract violation`.
- The snippet enumerates all six required choreography elements with their bolded labels: `Actor inventory`, `Sequence of operations`, `Per-step inputs and outputs`, `Consumer identification`, `Loud-failure paths`, and `Context-cost call-out`.
- Each of the four consumer SKILL.md files carries exactly one `!cat skills/_shared/multi-actor-flow-check.md` line at the multi-actor-flow checking gate.
- Consumer SKILL.md files do not embed copied versions of the six-element list or diagnostic template; `!cat` is the only inclusion path.
- The snippet is self-contained and does not reference `Sub-Rule C`, `G1`, or any `GNN` identifier.
- Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), and reviewer verifies the same content-semantic rules: R1 cuts non-actionable history and metadata from the snippet; R2 preserves the non-obvious rationale for stopping instead of guessing; R3 keeps the load-bearing STOP and Iron law visible; R4 limits examples to the single diagnostic template; R5 uses the shared snippet as the reusable spine instead of duplicating six-element prose in consumers; R6 introduces no Mermaid or diagram-only content; R7 preserves lexical anchors such as `actor`, `Actor inventory`, `Consumer identification`, `Loud-failure paths`, `Context-cost call-out`, `STOP`, and `Backward Loops`.

**Test expectations**

- File-existence check confirms `skills/_shared/multi-actor-flow-check.md` is present.
- Verbatim diff confirms `skills/_shared/multi-actor-flow-check.md` matches the locked snippet in design.md ### CD-3 / structure.md ### `skills/_shared/multi-actor-flow-check.md`.
- Grep audit confirms all four consumers contain exactly one `!cat skills/_shared/multi-actor-flow-check.md` line each: `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, and `skills/implement/SKILL.md`.
- Repo-level grep audit for `multi-actor-flow-check.md` under `skills/` returns exactly the four consumer SKILL.md files plus the source snippet file.
- Snippet self-containment lint `grep -E "Sub-Rule C|G1|G\\d+" skills/_shared/multi-actor-flow-check.md` returns zero matches.
- Consumer duplication audit searches the four consumer files for the snippet-only anchor phrases and confirms they appear only via the `!cat` include, not as embedded prose copies.
- Prompt-prose rules-application pass verifies the R1-R7 findings named in Definition of done.

**References**

- goals.md ### G1 — problem framing for downstream agents guessing under-described design decisions.
- goals.md ### G30 — related Goals/Design dialogue and persistence context; implementation deferred to sibling T32.
- goals.md ### G33 — related Design dialog-clarity context; implementation deferred to sibling T31.
- design.md ## G1 → Altitude Sub-Rule C — six required choreography elements and the no-invented-hand-offs acceptance bar.
- design.md ## G30 — incremental-persistence context for Goals/Design; not implemented by this task.
- design.md ## G33 — Design-only simple-language rule folded into G1; not implemented by this task.
- design.md ### CD-3 — locked snippet body, four consumer include sites, layered-defense semantics, and acceptance criteria.
- structure.md ### `skills/_shared/multi-actor-flow-check.md` — source file body and source-file hook-point responsibility.
- structure.md ## Hook-Point Cross-Slice Index → CD-3 multi-actor-flow-check `!cat` include sites — four consumer SKILL.md include targets.
