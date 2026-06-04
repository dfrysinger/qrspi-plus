# F01 — Finalize-pass "Validate ..." steps have no failure path; status can flip despite invariant violations

**Severity:** medium
**Category:** Missing error paths / silent fallback (status flip on validation failure)
**Files:**
- `skills/design/SKILL.md` — `## Incremental Persistence (Direct-to-Artifact Drafting)` → "End-of-phase finalize pass" bullets
- `skills/goals/SKILL.md` — `### Incremental Persistence ...` → "End-of-phase finalize pass" bullets

## What's wrong

Both skills define an end-of-phase finalize pass with this shape (Goals version):

> - Validate that every locked goal carries the three required subsections (Problem, Why we care, What we know so far) and a concrete `type` value.
> - Optionally append a Purpose section if absent.
> - Flip frontmatter `status: draft` to `status: approved`.

…and the Design version:

> - Validate that every goal in `goals.md` has a corresponding per-goal block in `design.md` with all five fields populated …
> - Validate the `## Cross-Goal Decisions` section is well-formed …
> - Optionally append a top-level summary if absent.
> - Flip frontmatter `status: draft` to `status: approved-pending-review`.

The bullets are written as a flat sequence with no conditional / no "stop on failure" clause. There is no instruction for what the finalize pass MUST do when validation fails (a goal is missing a subsection, a per-goal block is missing one of the five fields, Cross-Goal Decisions is malformed, etc.):

- Abort the finalize pass and surface the defect to the user?
- Re-enter dialogue (mirroring the Iron Rule fix in `goals.md` line 141)?
- Refuse to flip the status?

Because the rules are a flat list and the status-flip bullet is unconditioned, the natural reading is "run the validation, then flip the status" — which is exactly the silent-failure pattern: a validator that reports nothing on failure and lets the pipeline advance the gate anyway. The whole point of presence-≡-locked and the Evergreen-Output Rule is that downstream gates can trust `status: approved` / `status: approved-pending-review` to mean "invariants hold." A finalize pass that flips the status without a defined failure path silently breaks that contract.

This is the same class of bug F02 (last round) caught in the Iron Rule (placeholder bodies sneaking in past synthesis). F02's fix was "re-enter dialogue rather than write a placeholder." The finalize pass needs the parallel fix on the validation side: name the failure path so the gate does not silently advance over invariant violations.

## Required fix

In both finalize-pass blocks, add an explicit failure clause, e.g.:

> If any validation fails, do NOT flip the status. Surface the specific defect (goal ID + missing field) to the user and re-enter dialogue for that decision; re-run the finalize pass only when all validations pass.

…and reorder so the status flip is clearly gated on "all validations passed."

## Why this matters

Without a named failure path:
- A subagent merge that drops a field can produce a `status: approved` artifact whose body violates the three-subsection / five-field invariant.
- Reviewer rounds (Design's `approved-pending-review`) and downstream skills (Plan, Research) consume the malformed artifact as authoritative.
- The defect surfaces far downstream — exactly the "wrong results without indication something went wrong" failure mode this review hunts for.
