---
round: 15
artifact: design
status: fixing
---

# Round 15 dispositions

## Findings inventory

- quality-claude: 4 findings (medium=2, low=2)
- scope-claude: 0 (clean — 13th consecutive)
- quality-codex: 1 finding (medium=1)
- scope-codex: 0 (clean — 12th consecutive)

Total: 5 findings. 0 HIGH. 0 intent. All correctness/clarity. All accept.

Trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3 → 6 → 7 → 5. Inflecting back down. Scope topology rock-stable.

## R15-F01 quality-claude (medium, correctness) — accept. G5 cell label vs prose mismatch

The round-14 fix wrote "Cheap-model eligible (Implement-phase mode)" in the G5 routing cell but the prose in the same cell says both modes are cheap-eligible. Reader building routing matrix from cell label alone would split modes the prose says are unified.

**Fix:** In the G5 dispatcher tolerance matrix row for `qrspi-test-writer`, change Initial-routing cell to "Cheap-model eligible (both modes)" and rewrite the Reasoning cell to: "Standalone test-writer dispatches are bounded enough to tolerate cheap models regardless of mode. Mode distinction is preserved in agent behavior but does not affect model routing."

## R15-F02 quality-claude (low, correctness) — accept. G3 N=2 citation wrong

The round-14 fix cited "Q3 token budgets" for G3's N=2 rationale; Q3 actually covers Codex wrapper call-shape, not token budgets. Q6/Q7 covers task-file template size.

**Fix:** In the G3 Recommendation rationale, change "based on Q3 token budgets" to "based on Q6/Q7 task-file template size". The threshold (N=2) and reasoning structure are unchanged; only the citation tag is corrected.

## R15-F03 quality-claude (medium, clarity) — accept. G12 invariant requires step-3 split

The round-13 G12 prose rewrite ("staging runs BEFORE the scratch file is written") implicitly requires splitting the current single-line compound `git add -A && git commit -F .qrspi-commit-msg.txt` into three separate steps. Without explicit acknowledgment, implementer reading design + existing protocol side-by-side sees contradiction.

**Fix:** Under the first G12 architectural invariant, add a clarifying note: "Realizing this invariant requires splitting the current single-step `git add -A && git commit -F .qrspi-commit-msg.txt` into three sequenced operations: (1) `git add -A` (BEFORE scratch file exists), (2) Write the scratch commit-message file, (3) `git commit -F .qrspi-commit-msg.txt` followed by removal of the scratch file. Plan/Implement own the literal step sequence in `skills/implementer-protocol/SKILL.md`; this design names only the invariant and the required reordering."

## R15-F04 quality-claude (low, clarity) — accept. Test summary table missing unit type

Multiple goals (G8, G9, G13, G14, G15, G17, G18) call for BATS unit tests in their design-level test strategy sections, but the per-goal summary table conflates these as "acceptance" or omits them. Implementer using table for test planning will miss unit-tier signal.

**Fix:** Update the per-goal test-expectations summary table — for G8, G9, G13, G14, G15, G17, G18, replace "acceptance" alone with "acceptance, unit" (or "unit" if no acceptance test for that goal). Add a sentence under the table heading: "Design-level unit BATS pins are a separate tier from phase-level acceptance tests; both appear in the table where applicable."

## R15-F01 quality-codex (medium, correctness) — accept. G18 declares G14 dependency but doesn't consume it

G18's evergreen-markdown BATS pin is a repo-wide regex scan, not a section-bounded extraction — so it doesn't actually consume G14's markdown-section helper. Stated dependency in G18/Decision 7 forces unnecessary sequencing.

**Fix:** Drop G14 from G18's dependency list. Update three locations:
- G18 "Dependency note" subsection — remove G14, keep G17 (CI surface).
- Decision 7's dependent enumeration — remove G18 from G14's dependent set. (Decision 7's G14 dependent set was already {G8, G9, G11, G15, G18} after round 9's G12 removal; this round trims G18 too. New canonical G14 dependent set: {G8, G9, G11, G15}.)
- G14 "What research found" markdown-inspection list — remove G18 from the consumers list.

## Fix dispatch plan

Single fix subagent. 5 accepts.

## Status

draft → fixing → re-review round 16.
