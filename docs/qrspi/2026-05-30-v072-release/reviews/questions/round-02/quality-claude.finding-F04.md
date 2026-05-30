---
finding_id: F04
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q19 "Could Call Instead" Telegraphs G4's Consolidation Direction

## Location

Question 19, final clause:

> "…and note whether a shared helper script or function exists in `scripts/` that any of those sites could call instead."

## Problem

G4 is explicitly a "canonical helper consolidation" goal: it calls for creating `scripts/round-diff.sh` and updating `implement/SKILL.md` to call the script rather than inlining the `git merge-base` computation in prose. The question's closing clause asks the researcher to check for an existing helper "that any of those sites could call instead" — phrasing that directly encodes the consolidation direction. The word "instead" signals: (a) the current situation is inline implementations, and (b) we want a shared helper to replace them.

A neutral research question would ask the researcher to inventory how the diff-anchor construction is currently described and where, leaving open whether the answer implies consolidation opportunity, documentation drift, ambiguity, or adequate separation. The "could call instead" framing pre-answers that design question.

The first part of Q19 is neutral and well-formed: "How do skill prompts and orchestrator-facing documentation currently describe the construction of cumulative-diff anchors… Inventory every place in `skills/` and `agents/` where such a diff-anchor construction is described inline" is an objective characterization request. The leakage is isolated to the appended final clause.

## Why It Matters

The design decision G4 describes is whether to create a dedicated helper script and update the skill prose to reference it. That decision should be informed by Research characterizing the current state empirically. If Research arrives already knowing "we want a helper that sites call instead," the output will describe the lack of a helper as a gap rather than as a current-state description, subtly biasing Design toward confirming a predetermined solution.

## Suggested Rewrite

Remove the solution-direction clause and replace with a neutral inventory completion:

> "…and note whether any script or function in `scripts/` currently implements a related computation that those sites reference."

This asks whether existing helpers are being used, without presupposing that a helper should exist or that it is the target of a future consolidation.
