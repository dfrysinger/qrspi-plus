---
finding_id: F03
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q3 "How Many Distinct Paraphrases or Restatements" Signals G7's DRY Concern

## Location

Question 3, second clause of the first sentence:

> "…and how many distinct paraphrases or restatements of that rule exist in the file?"

## Problem

G7's core problem is that the verifier filter rule is "restated 5 times in `using-qrspi/SKILL.md` in different paraphrases" and that "adding a sixth restatement… without DRYing the values creates a third drift target." The question asks the researcher to count restatements — the precise diagnostic G7 already performed and documented.

A neutral research question about the filter rule would ask what the rule says and where it appears. Asking specifically "how many distinct paraphrases or restatements" signals that restatement count is a quality dimension we are tracking, making the DRY concern underlying G7 directly inferable. A researcher who knows we are counting restatements will look for the five existing paraphrases rather than characterizing the filter rule structure as they find it.

This is a mild but clear leakage: the concern is subtle enough that many researchers might not draw the inference, but the signal is present and directional.

## Why It Matters

The information the researcher needs to supply for G7 is: where exactly does the filter rule appear in each file, in what form (literal threshold values, narrative summary, reference-only), and how do the two files' presentations compare? The "count of paraphrases" framing narrows that open-ended characterization to a count-and-compare task, pre-framing the finding as "there are too many restatements" before research has confirmed it empirically.

## Suggested Rewrite

Replace:

> "…and how many distinct paraphrases or restatements of that rule exist in the file?"

With:

> "…and in what form does `using-qrspi/SKILL.md` state that rule — as a literal threshold value, a narrative summary, or a cross-reference to another location? Identify each location in the file where the rule appears."

This asks the researcher to characterize the form and location of each occurrence empirically, without presupposing that multiple paraphrases are the concern.
