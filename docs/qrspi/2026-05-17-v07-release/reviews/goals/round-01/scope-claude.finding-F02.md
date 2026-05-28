---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L35]
artifact: goals
round: 1
reviewer: scope-claude
---

G1's "What we know so far" first bullet (L35) commits the deliverable shape rather than framing solution candidates for Design to weigh.

Per `skills/goals/owns-defers.md` DEFERS line 17: "Detailed solution definitions → Design." Per OWNS line 12: "Solution candidates as possibilities. Solution IDEAS may appear under 'What we know so far' framed as candidates Design should weigh — never as commitments."

The bullet reads: "This goal produces a *framework*, not the populated routing table. G1's deliverable is the schema definition — what fields exist, what values are legal, how overrides compose — with placeholder defaults or one or two example entries to validate the shape."

The phrasing "G1's deliverable is the schema definition" and "with placeholder defaults or one or two example entries" commits the artifact shape (a schema definition with example entries) before Design has weighed alternatives. This is detailed solution definition territory — Design should decide whether the framework deliverable is a schema, a vocabulary spec, a precedence table, or some other shape. The accompanying division-of-labor framing with G5 is fine (that is goal-scoping, an OWNS responsibility), but the "deliverable shape = schema with placeholder entries" commitment is the part that crosses into Design.

Resolution: reframe the bullet to say what problem G1 owns (defining how dispatch sites declare cheap-model eligibility) and what G5 owns (the populated tolerance matrix), without committing the artifact shape. Move the "schema with placeholder defaults / example entries" language into "What we know so far" as a candidate ("one candidate framework shape is a schema with placeholder defaults that Design should weigh"), not as G1's deliverable.

This pattern repeats more mildly in G3's "candidate output contract is mechanical: write the `tasks/task-NN.md` files, rewrite `plan.md` to overview-only content, and return a summary of files written" (L72) — framed as "candidate output contract," so it stays inside the OWNS line-12 carve-out, but it sits at the boundary. Flagging G1 as the load-bearing instance.
