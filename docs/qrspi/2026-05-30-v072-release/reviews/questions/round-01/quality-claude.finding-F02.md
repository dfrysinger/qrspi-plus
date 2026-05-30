---
finding_id: F02
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q18 Echoes G10's Fabricated Quote Verbatim

## Location

Question 18, first sub-question:

> "What has Anthropic published about subagent behavior regarding file-system writes — specifically, are there any documented cases where host-injected system prompts suppress subagent Write tool use, or any **'contradiction-refusal' procedures** described in model cards, safety papers, or API documentation?"

## Problem

The phrase "contradiction-refusal procedures" appears verbatim in G10's problem statement:

> "it fabricated a non-existent procedural authority and quoted it verbatim to justify the contract violation… 'Per the **contradiction-refusal procedure** in `skills/reviewer-protocol/SKILL.md`…'"

G10 goes on to say: "Candidates Research should investigate: Is the fabrication grounded in any actual training-data pattern (Anthropic published 'contradiction refusal' framing the model could be confabulating from)?"

The research question therefore directly mirrors the investigation hypothesis from G10 — a researcher reading Q18 in isolation can infer: (a) a reviewer fabricated a "contradiction-refusal" citation, (b) we want to know if Anthropic training data carries that phrase so we can determine whether the fabrication was training-data confabulation. The entire G10 failure mode — fabricated procedural authority — is fully inferrable from the phrasing.

Additionally, the question names specific model identifiers (`gpt-5.5`, `gpt-5.3-codex`) that appear in the goals as observed empirical values, further signaling what the project encountered.

## Why It Matters

G10 is an `exploratory` goal. Framing the web question around a specific quoted artifact ("contradiction-refusal") directs Research toward confirming or denying the confabulation hypothesis before Design has evaluated it. It also signals to a reader that the project observed a specific incident, reducing the objectivity of any published materials Research might surface.

## Suggested Rewrite

Replace the Q18 Anthropic sub-question with a neutral probe that elicits the same information without embedding the hypothesis:

> "What does Anthropic's published documentation (model cards, safety papers, API docs) say about how Claude models respond when they receive conflicting instructions from different principals — e.g., a system prompt versus an in-context instruction? Are any named refusal or conflict-resolution procedures described?"

The OpenAI sub-question can also be neutralized by removing the specific model versions and framing it generically around subagent tool-grant behavior.
