---
status: approved
---

# Phasing: qrspi-plus v0.7 release

## Slices

Vertical, end-to-end demonstrable delivery units. Iron Law 1 applies: each slice must be demonstrable on its own across every layer it touches.

### Slice 1: Cost-opt routing end-to-end (goal IDs: G1, G2, G5)

End-to-end cost-opt path: a user adds a third-party provider entry to project configuration, a reviewer dispatch site consults a routing block, and a universal dispatcher routes the call to the cheap provider with a measurable cost-reduction artifact. The slice touches the config schema layer (G1 provider-routing schema), the dispatcher script layer (G2 universal shim with transport branching across OpenAI-chat-completions and codex-broker transports), and the policy-consumer layer (G5 populated tolerance matrix instrumented at dispatch sites). It is a vertical slice rather than a horizontal layer because none of the three pieces is independently demonstrable: G1 without G2 is a schema with no caller; G2 without G1 is a script with nothing to consume the routing decision; G5 without both is a matrix that cannot be applied. Together they prove the entire cheap-model routing system works against a real provider on a real prompt.

### Slice 2: TDD test-writer split (goal IDs: G6, G14)

End-to-end TDD split: a code task dispatches a dual-mode test-writer first, the orchestrator verifies a non-vacuous RED state via per-framework adapters, then an implementer dispatches to make tests green. The slice touches the agent layer (G6 dual-mode test-writer contract), the orchestrator layer (Implement-skill pre-implementer RED-verification gate plus per-framework adapters across BATS, Vitest, Jest, and pytest), the plan layer (Plan emits the per-task dispatch order), and the test-infra layer (G14 shared markdown helper authored here for the BATS adapter and its assertion fixtures, with broader consumer migration spanning Slice 4). G14 ships here because the test-writer adapter is one of its first consumers and writing the helper alongside its first real adapter validates the helper's section-extraction contract. Demonstrable end-to-end on a single TDD task: dispatch order is visible, RED verification pauses on vacuous-RED, and the per-framework adapter classifies infrastructure vs. assertion failures.

### Slice 3: Hygiene + CI foundation (goal IDs: G7, G17, G18)

End-to-end hygiene + CI: a push to a qrspi feature branch triggers CI which runs a lint job (shellcheck + Option B ban-list) and a bash-3.2 job (BATS suites under a bash:3.2 runtime), the implementer's pre-DONE self-check reports added-line ID and version-token hits, and the G18 evergreen-markdown pin runs as part of the unit BATS surface to block evergreen drift. The slice touches the CI layer (G17 workflow), the implementer-protocol layer (combined G7+G18 hygiene contract per Decision 4), the test layer (BATS evergreen scan), and the shipped agent layer (both implementers preload implementer-protocol). G18 ships here because Decision 8 makes it dependent on G17's workflow existing. Demonstrable on its own: a single push exercises lint + bash-3.2 runtime + evergreen scan + implementer self-check end-to-end.

### Slice 4: Parallelize hygiene + G14 consumers (goal IDs: G8, G9, G14)

End-to-end Parallelize hygiene: a parallelization artifact that uses canonical vocabulary and follows the worktree-aware validation process runs through both Parallelize reviewers (scope and quality) without false-positive findings, and BATS pins for the OWNS list (G8) and canonical vocabulary tokens (G9) catch future drift on either side. The slice touches the skill layer (G8 OWNS addition and G9 Branch Model multi-stage suffix grammar), the agent layer (Parallelize reviewer vocabulary alignment for G9), and the test-infra layer (G14 consumer migration across the affected BATS files plus the new G8/G9/G11/G15 pins). G14 appears in both Slice 2 and Slice 4 because Iron Law 1 forbids a helper-only horizontal layer — the helper must demonstrate end-to-end use in each slice that consumes it. Demonstrable: a seeded parallelization fixture exercises both reviewers without spurious findings; the BATS pins fire against an introduced drift.

### Slice 5: Visual-fidelity + human-gate references (goal IDs: G10, G11)

Slice 5 delivers visual-fidelity reviewing for UI-producing work and reference-rendering at human gates. Demonstrates: a UI-producing task surfaces its visual reference at the human gate in a renderable form (not just a path); the visual-fidelity reviewer participates in review cycles for UI tasks with awareness of sibling reviews in the same wave. Reference-gated tasks pause downstream dispatches at the human gate until explicit approval is recorded. Layers touched: skill layer (human-gate path), reviewer agent layer (visual-fidelity reviewer), and orchestrator layer (gate sequencing across dependents).

### Slice 6: Plan post-approval split (goal IDs: G3)

End-to-end Plan post-approval split: an approved Plan with N≥3 tasks delegates per-task spec authoring such that the split mechanism produces independent per-task spec files without exhausting main-chat context, with an N≤2 carve-out that keeps the split inline. The slice touches the plan skill layer (post-approval split orchestration and N-threshold carve-out), the sub-subagent layer (per-task spec authoring contract), and the artifact layer (the overview/per-task split shape after approval). It is a vertical slice because the cost-optimization motive only materializes when the orchestration, the sub-subagent contract, and the resulting artifact shape land together. Demonstrable end-to-end on a single approved Plan: parallel dispatches complete, per-task spec artifacts exist, and the overview artifact records phase-start state.

### Slice 7: Caching spike + verify (goal IDs: G4)

Slice 7 delivers a measurement-grounded decision about whether the platform's existing caching behavior covers the high-token-cost dispatch surface, and a follow-up implementation if it does not. Demonstrates: a written deliverable records the hit-rate behavior of representative dispatches on stable prefixes; downstream implementation work is either green-lit-by-measurement or scoped against the gap the measurement surfaced. Iron Law 1 departure (named): this slice's deliverable is a measurement-and-decision spike, not a working cross-layer feature. The departure is intentional — the design names G4 as a Plan-time spike that gates downstream cache enablement work on measurement results. The slice is included in Phase 1 because the measurement must precede phase-2 work; the departure is bounded by the design's spike contract.

### Slice 8: Commit-message scratch staging (goal IDs: G12)

End-to-end commit-hygiene fix: the implementer scratch file used to compose commit messages never appears in any committed tree, the worktree-local exclude list carries the entry, and the three architectural invariants for commit hygiene hold across an implementer commit cycle. The slice touches the implementer-protocol layer (three-invariant commit hygiene contract), the worktree-setup layer (per-worktree exclude entry), and the test layer (BATS pin against the commit cycle). Demonstrable end-to-end on a single implementer commit cycle: a pin observes a clean committed tree and a populated worktree exclude.

### Slice 9: u14-lint worktree (goal IDs: G13)

End-to-end u14-lint worktree fix: the skill-slug extractor used by the u14-lint check correctly identifies skills regardless of worktree path prefix, so a worktree path that contains `integrate` as a directory segment elsewhere in the prefix does not produce a false positive on a goals skill — and a genuine integrate skill still does. The slice touches the test-helper layer (slug-extraction logic) and the test layer (positive and negative fixtures). Demonstrable end-to-end: a single u14-lint run distinguishes a confusable-prefix worktree from a genuine integrate-skill path.

### Slice 10: Replan ↔ Goals coordination (goal IDs: G15)

End-to-end Replan-Goals boundary: a Replan run consults a future-goals artifact, promotes only entries that satisfy the Formal schema, skips prose-only Ideas, and emits a hand-off report listing both promoted Formal goals and skipped Ideas. The slice touches the Replan skill layer (Boundary-with-Goals section and Formal-vs-Idea schema check), the artifact layer (hand-off report shape), and the test layer (a pin that exercises a fixture with mixed Formal, Idea, and partial-Formal entries). Demonstrable end-to-end on a single Replan invocation against a mixed-shape future-goals fixture: promotion is correct and the hand-off report reflects the decision.

## Phases

Phase grouping with replan-gate criteria. The Phase 1 PoC guideline applies: Phase 1 should prove the full stack end-to-end whenever possible, with any departure named explicitly.

### Phase 1: v0.7 release — PoC (slices: Slice 1, Slice 2, Slice 3, Slice 4, Slice 5, Slice 6, Slice 7, Slice 8, Slice 9, Slice 10)

**Phase 1 PoC justification.** v0.7 ships as a single phase because the entire release IS the PoC for the qrspi-plus meta-stack. The 10 slices together exercise every layer the project touches: skills (multiple slices modify skill content), agents (multiple slices modify agent content), scripts (Slice 1 introduces the universal dispatcher), tests (multiple slices add BATS pins and unit tests), CI (Slice 3 introduces the CI workflow), and config (Slice 1 extends the config schema). Combined the release proves end-to-end that a user can (a) extend config with new providers and route reviewers to cheap models, (b) run TDD-mode implementer dispatches with pre-implementation RED verification, (c) get hygiene + bash-3.2 + evergreen CI signal on every push, (d) see binary references at human gates, (e) trust the parallelize reviewer's vocabulary and owns-defers checks, (f) get parallel per-task spec authoring after Plan approval, (g) make an evidence-based caching decision, (h) trust that the implementer scratch file never lands in a commit, (i) trust that u14-lint distinguishes worktree-prefix confusables from genuine integrate skills, and (j) rely on the Replan boundary with Goals. Backend-only Phase 1 was not considered — there is no backend in qrspi-plus; the meta-stack IS the stack.

**Replan gate criteria.**

Slice 1 — Cost-opt routing end-to-end:
- A configured non-Anthropic routing site dispatches through the universal dispatcher to the cheap provider and records enough telemetry to compare cost against the Anthropic baseline.

Slice 2 — TDD test-writer split:
- A code task triggers a pre-implementation test-writer dispatch followed by an implementer dispatch after a RED-verification gate, observable in the per-task dispatch order.
- The RED-verification gate distinguishes assertion failures, infrastructure failures, vacuous-RED, and pass states, with the gate pausing on vacuous-RED and infrastructure failures.
- One agent body serves both the Implement-phase per-task mode and the Test-phase plan-level mode, with the dispatch context selecting the mode — observable in the artifacts produced by each mode against the same agent body.

Slice 3 — Hygiene + CI foundation:
- A push to a qrspi feature branch triggers CI with both a lint job and a bash-3.2 runtime job, both succeeding on the merge commit.
- Shellcheck runs against the project's shell surface and is clean.
- CI's bash-3.2 docker job is the load-bearing backstop. The grep ban-list catches known bash-4 constructs early; the docker job validates the ban-list remains current by execution test, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate.
- The evergreen-markdown scan runs under the unit BATS surface and is green.
- The implementer pre-DONE self-check reports added-line hits for internal-ID tokens and version tokens, the advisory commit still proceeds, and reviewer visibility covers unacknowledged hits.

Slice 4 — Parallelize hygiene + G14 consumers:
- The shared markdown test-helper exists and the migrated BATS consumers use it and remain green.
- The Parallelize scope reviewer dispatched against a worktree-aware parallelization artifact produces no scope-drift finding.
- The Parallelize quality reviewer dispatched against an artifact using canonical multi-stage vocabulary produces no style finding, and an artificially-introduced unconventional form does produce a style finding.
- The OWNS-list pin asserts the worktree-aware validation responsibility is present in Parallelize's OWNS surface.

Slice 5 — Visual-fidelity + human-gate references:
- A human gate for a UI-producing task surfaces its visual reference to the user in a renderable form, not merely as a path.
- A reference-gated UI task can be observed pausing dependents from dispatching until approval is recorded; the approval record persists so subsequent re-runs and audits can verify the gate fired and was cleared.
- The visual-fidelity reviewer's output for a UI task dispatched alongside sibling UI tasks contains either (a) at least one explicit reference to a sibling task's findings, or (b) an explicit statement that no relevant sibling visual context was found — observable in the reviewer's emitted finding files.

Slice 6 — Plan post-approval split:
- An approved Plan with N≥3 tasks dispatches per-task spec authoring in parallel and produces N separate per-task spec artifacts, with the overview artifact recording phase-start state and approved status.
- An approved Plan with N≤2 tasks performs the split inline in main chat (carve-out exercised).

Slice 7 — Caching spike + verify:
- A written deliverable records the hit-rate behavior of representative high-token-cost dispatches against stable prefixes, observable as a release artifact.
- A recorded decision determines whether the platform's existing caching behavior is sufficient or whether follow-up implementation is required; downstream implementation work is either green-lit by the measurement or scoped against the gap the measurement surfaced.

Slice 8 — Commit-message scratch staging:
- Across an implementer commit cycle, the implementer scratch file used to compose commit messages does not appear in the committed tree, and the worktree-local exclude carries the corresponding entry.
- The three architectural invariants for commit hygiene hold and are observable in test output.

Slice 9 — u14-lint worktree:
- The u14-lint check passes for a worktree path whose prefix contains `integrate` as a non-skill directory segment while still failing on a genuine integrate-skill path — both fixtures exercised in the same run.

Slice 10 — Replan ↔ Goals coordination:
- A Replan invocation against a mixed-shape future-goals fixture (one fully Formal entry, one prose-only Idea, one partial-Formal entry) promotes only the fully Formal entry.
- The hand-off report lists both promoted Formal goals and skipped Ideas, observable as a Replan output artifact.

## Goal-ID Consistency

Every current-phase goal ID listed in `roadmap.md` (G1–G15, G17–G18) is accounted for in the slices above. G16 carries `phase: future` and is deferred to a later release; its full context spans `future-goals.md`, `future-questions.md`, `future-research-summary.md`, and `future-design.md`. The Q21 research-summary entry stays in current `research/summary.md` (research/q*.md files are not split per the Phasing skill contract); `future-research-summary.md` carries pointers to the in-place Q21 finding. No orphan IDs.

## Pruning Summary

- `goals.md` — current-phase: G1–G15, G17, G18. Deferred to `future-goals.md`: G16.
- `questions.md` — current-phase: Q1–Q20, Q22–Q31. Deferred to `future-questions.md`: Q21.
- `research/summary.md` — kept intact as full corpus by intentional corpus-retention (research/q*.md files are not split per Phasing skill contract). The Q21/G16 deferred finding therefore remains physically inside current `research/summary.md`; `future-research-summary.md` carries pointers to that in-place finding location. This is the documented exception to the "no future content in current artifacts" rule for the research surface — corpus retention takes precedence over per-finding pruning here.
- `design.md` — current-phase: G1–G15, G17, G18 + Decisions 1–10. Deferred to `future-design.md`: G16 (future-release deferral) and FD-01..FD-04 (v0.7 known issues accepted at round-18 gate).

## Orphan IDs

No orphan IDs.
