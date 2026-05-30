---
finding_id: F01
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q26 Embeds G29 Problem Framing ("escape rules", "size thresholds")

## Location

Question 26, closing sentence:

> "Are there any prescribed size thresholds, escape rules, or selection guidance between the two forms?"

## Problem

The phrase "escape rules" is a direct echo of G29's problem statement: "The skill contract has no formal escape hatch." The phrase "prescribed size thresholds" anticipates the leading candidate design from G29: "Threshold rule — amend `skills/reviewer-protocol/SKILL.md` § Reviewer Dispatch Contract to add: artifacts ≤ N KB use wrapped `artifact_body` inline; artifacts > N KB use `artifact_path`."

A researcher reading Q26 in isolation sees two specific terms — *escape* mechanism and *size threshold* — that jointly reveal:

1. The project believes a "no-escape" gap exists in the current dispatch contract (the problem G29 is solving), and  
2. A size-based threshold is a candidate mechanism for closing that gap (the first and most specific of G29's three design candidates).

This is a narrower but structurally identical leak to the Q16/G19 finding from Round 1: the question's closing clause names the mechanism the goal is evaluating adding, rather than asking neutrally what selection mechanism (if any) the current docs describe.

The first two-thirds of Q26 are neutral and appropriately observational (inventory `artifact_body:` occurrences, inventory `artifact_path:` occurrences). The leakage is isolated to the final clause.

## Why It Matters

A researcher primed with "is there a size threshold or escape rule?" will frame their investigation around the absence of that specific mechanism — confirming a gap the question already implies — rather than characterizing the full selection-guidance surface and identifying failure modes from evidence. This skews Research toward corroborating a predetermined problem framing rather than discovering it independently. It also reveals that one of the three G29 candidate solutions (threshold rule vs. unconditional path-based vs. reviewer-side parser) is in play at all, partially constraining Design input.

## Suggested Rewrite

Replace:

> "Are there any prescribed size thresholds, escape rules, or selection guidance between the two forms?"

With a neutral probe such as:

> "Does the dispatch contract currently describe any conditions or criteria for choosing between the two artifact-passing forms, or is one form specified unconditionally?"

This asks the same structural question (does guidance exist?) without naming the specific mechanism type (size threshold / escape hatch) or telegraphing which direction the goal is interested in.
