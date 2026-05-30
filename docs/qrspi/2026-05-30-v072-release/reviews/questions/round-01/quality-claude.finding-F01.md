---
finding_id: F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q16 Embeds the G19 Solution (Cite-Check)

## Location

Question 16, second sentence:

> "Does the verifier include any step that checks whether content cited at a specific file and line **actually exists at that location**?"

## Problem

This question does not ask how the verifier rubric works — it asks whether the verifier performs a specific operation that is precisely the leading design candidate proposed in G19 (#236): "Expanding the rubric to include a cite-check branch (`if cited file:line does not contain cited content → score 0 / HALLUCINATED, halt scoring`)." A researcher reading Q16 in isolation immediately knows the project is concerned about hallucinated citations and is evaluating whether cite-checking belongs in the verifier. The goal being pursued — G19's wholesale-hallucination defense — is fully inferable.

The first sentence of Q16 is neutral ("How does `agents/qrspi-finding-verifier.md` define its scoring rubric?"), as is the second ("Does the rubric distinguish between [false positive / informational / acknowledged]?", covering G14). The leakage is isolated to the third sentence.

## Why It Matters

A researcher who knows the answer is "no, the verifier does not cite-check" will frame their research differently than one exploring the space without that hint. In particular, they may search specifically for how cite-checking could be added rather than characterizing the current rubric objectively and identifying which failure modes it leaves open. This skews Research toward a predetermined solution rather than evidence-based design input.

## Suggested Rewrite

Replace:

> "Does the verifier include any step that checks whether content cited at a specific file and line actually exists at that location?"

With a neutral probe such as:

> "For each of the five rubric tiers (0/25/50/75/100), what specific conditions does the verifier evaluate, and does any condition involve reading the content at a file:line cited in the finding?"

This asks the same structural question without presupposing the answer or naming the operation we are evaluating adding.
