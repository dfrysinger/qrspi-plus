---
artifact: design
reviewer: quality-claude
round: 2
finding_id: quality-claude-F01
severity: medium
---

# F01 — DKR7 cites `research/q11-codebase.md` for `gpt-5.3-codex`, but Q11 contains no such information

## Check

Approach rationale grounded in research — citations to `research/q*.md` are accurate (Citation-verification Read exception applied; Q11 read directly).

## Location

`## Key Decisions` → `### DKR7 -- Codex dispatch transport branches per detected host (G6)`, **Reasoning** paragraph, final sentence:

> "The concrete model name `gpt-5.3-codex` comes from the `model_routing:` table per `research/q11-codebase.md`."

## Description

This citation is factually incorrect. `research/q11-codebase.md` documents the routing chain for Claude agent `model:` fields (the four values `haiku`, `sonnet`, `opus`, `inherit` in `agents/*.md` frontmatter) and the existing `model_routing:` table entries (mapping `research-collator`, `lightweight-implementer`, `research-specialist` roles to DeepSeek V3 tiers). The file contains zero occurrences of `gpt-5.3-codex`, `gpt-5.2-codex`, or any Codex/OpenAI model identifier.

The model name `gpt-5.3-codex` (and the alternative `gpt-5.2-codex`) appears in:
- `goals.md` G6 "What we know so far": "Codex reviewer slot must dispatch via the `task` tool with `agent_type: code-review` and `model: gpt-5.3-codex` (or `gpt-5.2-codex`)."
- `research/q12-web.md`: `GPT-5.3-Codex` is listed among observed values in the `github/awesome-copilot` agent sample, confirming it is a real routable Copilot CLI model name.

An implementer following DKR7's reasoning chain and opening Q11 to confirm the source will find the model name nowhere in that file, which breaks traceability for the decision.

## Fix

Replace the trailing sentence in DKR7's Reasoning with a corrected citation:

> "The concrete model name `gpt-5.3-codex` is the Codex model routable via the Copilot CLI `task` tool, per `goals.md` G6 "What we know so far" (specifies `gpt-5.3-codex` or `gpt-5.2-codex`) and confirmed as an observed Copilot agent model in `research/q12-web.md`."
