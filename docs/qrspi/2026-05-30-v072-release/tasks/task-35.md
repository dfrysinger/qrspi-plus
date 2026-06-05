---
status: approved
task: 35
phase: 1
pipeline: full
goal_ids: [G10]
task_type: code
model: opus
---

# Task 35: G10 reviewer-protocol anti-fabrication hardening

- **Target files:** skills/reviewer-protocol/SKILL.md (modify), tests/acceptance/test-review-pause.bats (modify)
- **Dependencies:** Task 03
- **LOC estimate:** ~100
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Add the reviewer-protocol anti-fabrication rule and acceptance coverage that prevent reviewers from inventing procedural authority when a loaded contract is hard to satisfy. The rule bounds the existing contradiction-refusal procedure to its documented dispatch malformation and gives genuine contract conflicts one explicit fail-loud exit. (Why: see goals.md ### G10. Approach: see design.md ## G10.)

**Scope**

- **In:**
  - Insert a new `### Anti-Fabrication Rule (FAIL-LOUD)` section in `skills/reviewer-protocol/SKILL.md` immediately after the existing refusal procedure and before `## Per-Finding Disk-Write Contract`, using the verbatim G10 callout content from design.md ## G10 D1.
  - State in that section that the contradiction-refusal procedure applies only to the documented malformed dispatch with `task_definition` present and a test-phase `output` path, and does not generalize to other contract conflicts.
  - Forbid inventing, paraphrasing, or attributing any reviewer-protocol escape hatch that is not literally present in the file; fabricated citations to absent procedures are contract violations, not approved exits.
  - Require genuine contract conflicts to avoid the Write tool, avoid findings and clean sentinels, return exactly one single-line response beginning with `CONTRACT-CONFLICT:`, and end the turn.
  - Update `tests/acceptance/test-review-pause.bats` to cover the `CONTRACT-CONFLICT:` prefix path, operator-intervention routing, fabricated-procedure rejection, and the valid-exit boundary.

- **Out:**
  - No sibling task shares G10; this task owns the G10 surface in the two target files only.
  - Rewriting or deleting the existing `### Contradiction Refusal (FAIL-LOUD)` or `### Refusal Procedure` sections — this task bounds them by adjacent callout rather than changing them.
  - Retroactively editing reviewer agent bodies — design.md ## G10 states the callout is consumed through the existing reviewer-protocol preload.
  - v0.7.3 follow-up investigation into training-data origin, context-size correlation, or round-number correlation — design.md ## G10 tracks that separately in issue dfrysinger/qrspi-plus#264.
  - Broad G6 transport fallback hardening — T03 owns the disk-write contract and transport-level chat-only fallback surface.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains `### Anti-Fabrication Rule (FAIL-LOUD)` immediately after `### Refusal Procedure` and before `## Per-Finding Disk-Write Contract`.
- The new section body matches the verbatim design.md ## G10 D1 callout, including the bounding clause, the prohibition on invented or paraphrased escape hatches, the three-step `CONTRACT-CONFLICT:` exit procedure, and the closing fabrication-as-rule clause.
- The new section preserves the existing contradiction-refusal and refusal-procedure sections unchanged.
- A reviewer that sees a real contract conflict is instructed not to call `Write`, not to emit findings or clean sentinels, to return exactly one line beginning with `CONTRACT-CONFLICT:`, and to end the turn.
- `tests/acceptance/test-review-pause.bats` verifies a reviewer chat output whose first non-blank line begins with `CONTRACT-CONFLICT:` routes to operator intervention rather than normal review-round handling.
- The conflict-prefix path does not parse findings, synthesize a clean sentinel, fire the schema-violation guard, auto-repair, consume a tag emission budget, or advance the round counter.
- The pause-flow coverage surfaces the single-line conflict statement verbatim to the operator with an intervention menu.
- Regression coverage rejects fabricated citations to reviewer-protocol procedures not literally present in the file and verifies the only valid conflict exits are normal finding emission under the loaded contract or the `CONTRACT-CONFLICT:` single-line response.

**Test expectations**

- Grep audit confirms `skills/reviewer-protocol/SKILL.md` contains `### Anti-Fabrication Rule (FAIL-LOUD)` between `### Refusal Procedure` and `## Per-Finding Disk-Write Contract`.
- Text comparison or anchored grep audit confirms the new section carries the exact D1 callout requirements from design.md ## G10: one-specific-dispatch-malformation bounding clause, no invented/paraphrased escape hatches, no `Write`, no findings/sentinels, literal `CONTRACT-CONFLICT:` prefix, single-line return, and end-turn requirement.
- Acceptance fixture covers a reviewer chat output whose first non-blank line begins with `CONTRACT-CONFLICT:` and asserts it routes to operator intervention rather than the normal review-round path.
- Conflict-prefix fixture asserts no findings are parsed, no clean sentinel is synthesized, no schema-violation guard fires, no auto-repair occurs, no tag emission budget is consumed, and the round counter does not advance.
- Pause-flow fixture asserts the single-line conflict statement is surfaced verbatim to the operator with an intervention menu.
- Regression fixture asserts a fabricated citation to a reviewer-protocol procedure not literally present does not satisfy the contract and is not treated as an approved escape hatch.
- Regression fixture asserts the only valid exits for a contract conflict are normal finding emission under the loaded contract or the `CONTRACT-CONFLICT:` single-line response.

**References**

- goals.md ### G10 — problem framing for reviewer procedural-authority fabrication and why it weakens SKILL-as-contract enforcement.
- design.md ## G10 — D1 anti-fabrication callout content, placement, `CONTRACT-CONFLICT:` handling, acceptance criteria, and explicit non-goals.
- structure.md ### `skills/reviewer-protocol/SKILL.md` → G10 block — insertion site, verbatim section body, preserve-existing-sections constraint, and reviewer-agent non-retrofit boundary.
- structure.md ### `tests/acceptance/test-review-pause.bats` — acceptance coverage for conflict-prefix routing, no normal review-round side effects, fabricated-citation rejection, and valid conflict exits.
