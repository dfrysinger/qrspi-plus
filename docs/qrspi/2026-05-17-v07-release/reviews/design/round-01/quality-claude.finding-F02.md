---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L650-L676]
artifact: design
round: 1
reviewer: quality-claude
---

G15's Replan boundary contract has an internal contradiction between its definition of "Formal goal" and its enforcement check.

The two-state schema is defined at L656–L660:

> **Formal goal.** Has `id:`, `type:`, and acceptance criteria. Replan-promotable.
> **Idea.** Prose paragraph only. No `id:`, no `type:`. Replan-skippable.

This definition requires three properties to qualify as Formal: `id:`, `type:`, and acceptance criteria.

But the Replan enforcement check defined six lines later at L662–L663 reads:

> **Schema check on Replan side.** A goal lacking `id:` is automatically classified as an Idea. Absence of `id:` is the load-bearing signal. No new explicit field needed.

The check tests only one of the three properties. A `future-goals.md` entry that has `id: F-42` but no `type:` field and no acceptance criteria would be classified by the definition as malformed-Formal (not Idea, but not fully Formal either), and would be classified by the check as Formal-and-promotable. Replan would then promote a partially-formed entry into the next phase's `goals.md`, which is exactly the silent-scope-expansion outcome the boundary contract exists to prevent.

The BATS pin at L676 (`test-replan-skips-ideas.bats`) is described as testing a fixture with "one Formal entry and one Idea" — it does not appear to test the partial-Formal case the inconsistency creates.

Resolutions to consider in the design:
1. Tighten the check to require all three properties (id, type, acceptance criteria) before promotion, matching the definition.
2. Loosen the definition to "id-bearing entries are Formal" and drop `type:` and acceptance criteria from the Formal/Idea distinction (move them to a separate well-formedness check Goals enforces).
3. Add an explicit "malformed-Formal" third state with defined Replan handling (block? error? defer to Goals?).

Currently the design splits the difference and lets a real partial-Formal entry through silently. Resolving the inconsistency belongs in design.md so Plan and the BATS pin can be written against a single definition.
