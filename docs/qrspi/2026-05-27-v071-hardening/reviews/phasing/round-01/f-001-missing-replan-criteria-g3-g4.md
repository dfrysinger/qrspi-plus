---
artifact: phasing
severity: minor
check: replan-gate-criteria-concrete-and-checkable
location: "phasing.md § Phases / Phase 1 / Replan gate criteria (criteria 1–6)"
change_type: add
---

# Finding: No dedicated replan-gate criteria for G3 or G4

## What is wrong

The six replan-gate criteria listed for Phase 1 map to goals as follows:

| Criterion | Goal covered |
|-----------|-------------|
| 1 — CI suite passes, no regressions | G7a (CI green after deletions) — and implicit regression backstop for all goals |
| 2 — zero "model not available" warnings | G7b |
| 3 — Codex dispatches succeed on both hosts | G6 |
| 4 — evergreen scan zero violations | G5 |
| 5 — control-char detection triggers on raw LF | G1 |
| 6 — scratch file absent from staged index | G2 |

**G3** (fence-aware extract helper extracted into shared library) and **G4** (Wave sub-sections in Branch Map presentation) each have no dedicated criterion. The only gate that could catch a failure in either goal is criterion 1 — "CI suite passes with no regressions" — which is a regression backstop, not a forward acceptance criterion.

This creates two specific gaps:

- For **G3**: An implementer could satisfy criterion 1 by deleting both the inline helper and the two call-sites that use it, removing the inline test expectations alongside. CI stays green (nothing new fails), but the goal's actual requirement — a new `extract_section_fence_aware` function in `tests/helpers/skill-markdown.bash` with unit coverage — is unverified by any named gate condition.

- For **G4**: An implementer could restructure the flat Branch Map text informally without updating the parallelize-reviewer lint rule or the Worked Example pair. Criterion 1 (CI) only catches failures if the new structural lint test exists and runs; no gate names that new test as a required observable outcome.

## Protocol requirement

The reviewer-protocol check is: *"each phase's replan-gate criteria specify observable outcomes, not vague states; criteria must be checkable without ambiguity."* Per the protocol, every in-scope goal should be traceable to at least one concrete, directly checkable criterion.

## Recommended fix

Add two criteria to the replan-gate list (placement after criterion 4 to keep acceptance ordering by goal number):

> **5a.** The new `extract_section_fence_aware` function is present in `tests/helpers/skill-markdown.bash`, its BATS unit tests pass (fence-toggle correctness, exit-on-fence, exit-on-section, empty-extract guard), and the inline duplicate is absent from `tests/unit/test-skill-md-content-patterns.bats` (G3 acceptance, per `design.md` DKR3).
>
> **5b.** The parallelize-reviewer agent structural lint test for Wave sub-sections passes, the Worked Example "Good"/"Bad" pair in `skills/parallelize/SKILL.md` is rendered in the new Wave sub-section shape, and the flat Branch Map is no longer present in that file (G4 acceptance, per `design.md` DKR4).

The existing acceptance patterns in design.md Test Strategy (G3 and G4 paragraphs) provide the exact language; these criteria would surface that content at the gate rather than leaving it implicit.
