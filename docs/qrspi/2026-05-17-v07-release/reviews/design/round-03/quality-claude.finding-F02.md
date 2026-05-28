---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L628, docs/qrspi/2026-05-17-v07-release/design.md:L920-L933, docs/qrspi/2026-05-17-v07-release/design.md:L340-L345, docs/qrspi/2026-05-17-v07-release/design.md:L900-L908]
artifact: design
round: 3
reviewer: quality-claude
---

The design has a three-way inconsistency about which goals depend on G14's BATS helper. Three locations disagree:

1. G14 § Dependency note (line 628):
   > "G14 is depended on by G7/G8/G9/G11/G12/G15/G18 BATS pins."

2. Decision 7 (lines 922–933):
   > "G7 hygiene contract check. G8 owns-defers check. G9 vocabulary check. G12 commit-procedure check. G15 Replan boundary check. G18 evergreen check."
   (Omits G11.)

3. Decision 4 (lines 902–906) and G7's own test strategy (lines 340–345) collectively assert G7 has NO CI BATS backstop:
   > "A CI BATS test as a backstop (G18 only — G7 is enforced by the implementer self-check plus reviewer visibility, since G7 carve-outs are too path-shaped to mechanize cheaply)."
   And G7's "Test strategy at the design level" lists only runtime self-check tests, carve-out tests, acknowledgment tests, and reviewer-visibility tests — none of which is a markdown-inspection BATS pin that would consume G14's helper.

Two contradictions visible to Phasing:
- G14's list includes G11; Decision 7 excludes G11. G11's own test strategy lists "Quick-tier wording test" which could plausibly be a markdown-inspection BATS pin on `skills/reviewer-protocol/SKILL.md`, but it is not labeled as such in G11's section. Downstream Phasing cannot determine whether G11 actually depends on G14.
- G14's list includes G7 and Decision 7 includes G7, yet Decision 4 and G7's own section say G7 has no BATS backstop. If G7 has no BATS pin that inspects markdown, it cannot depend on G14's helper.

These dependency facts are load-bearing: Phasing uses them to decide which phase/wave G14 ships in relative to its consumers. A wrong dependency list either over-sequences (G14 ships earlier than necessary, blocking parallelism) or under-sequences (G14 ships in the same wave as a goal that needs it, breaking the wave).

Fix: pick one canonical dependency list and propagate it. Options:
- If G7 has a BATS pin (e.g., asserting `skills/implementer-protocol/SKILL.md` contains a "Hygiene contract" section), add that test explicitly to G7's "Test strategy at the design level" and reconcile Decision 4's "G18 only" carve-out wording.
- If G7 has no markdown-inspection BATS pin, remove G7 from both G14's dependency note and Decision 7's list.
- Resolve G11's inclusion/exclusion the same way: either add an explicit BATS-pin item to G11's test strategy and keep it in G14's list, or drop it from G14's list.
