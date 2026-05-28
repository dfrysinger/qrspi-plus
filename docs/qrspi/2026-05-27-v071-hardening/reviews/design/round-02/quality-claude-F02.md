---
artifact: design
reviewer: quality-claude
round: 2
finding_id: quality-claude-F02
severity: low
---

# F02 — DKR9 states specific concrete model IDs without a research citation; one is inconsistent with Q12

## Check

Approach rationale grounded in research — architectural choices trace back to concrete research findings (not to unresearched assumptions).

## Location

`## Key Decisions` → `### DKR9 -- Delete \`model:\` from all 41 agents; retain \`haiku\`/\`sonnet\`/\`opus\` as canonical tier names (G7b)`, **Reasoning** paragraph, final three sentences:

> "Plugin ships defaults for both hosts: Claude Code uses `claude-haiku-4.5` / `claude-sonnet-4.6` / `claude-opus-4.7`; Copilot CLI uses equivalent concrete IDs. Operators can override per-tier or per-role."

## Description

Two sub-problems:

**1 — `claude-opus-4.7` is inconsistent with the cited research and unattributed.**  
DKR9 cites `research/q12-web.md` for the `gentle-ai` precedent, and Q12 documents that `gentle-ai` currently maps the `opus` tier to `claude-opus-4.6` (not `claude-opus-4.7`). `claude-opus-4.7` appears in `goals.md` as the Copilot CLI session fallback model at probe time (`claude-opus-4.7-high`), but goals.md is describing what the probe session happened to run on, not establishing a "Claude Code plugin default." The design does not cite any source that identifies `claude-opus-4.7` specifically as the Claude Code default for the `opus` tier. Whether `4.6` or `4.7` is correct matters for an implementer authoring the `config.md` defaults shipped with the plugin.

**2 — "Copilot CLI uses equivalent concrete IDs" is too vague.**  
The Copilot CLI concrete model IDs for each tier are not named anywhere in the design, leaving implementers unable to verify or populate the Copilot CLI column of the `model_routing:` table from the design document alone.

Note: the architectural decision itself (delete `model:`, retain tier names, put per-host concrete IDs in `model_routing:`) is sound. This finding concerns the unattributed and partially inconsistent version-ID examples appended to the reasoning.

## Fix

Either of two equivalent fixes:

**Option A — Remove specific version IDs from the reasoning; defer to Plan.**  
Replace the final sentences with: "The plugin ships a `model_routing:` table with per-host concrete model IDs for each tier; exact IDs are verified against current Claude Code and Copilot CLI defaults at Plan time."  
This removes the risk of encoding stale or incorrect version numbers in the design.

**Option B — Add citations and fill in the Copilot CLI IDs.**  
Attribute the Claude Code IDs to a specific source (e.g., current Anthropic documentation or the `claude-opus-4.7` probe evidence in `goals.md`), acknowledge that `claude-opus-4.6` is what Q12/gentle-ai documents, and state the specific Copilot CLI model IDs (e.g., from `research/q12-web.md`'s list of observed Copilot agent model values).
