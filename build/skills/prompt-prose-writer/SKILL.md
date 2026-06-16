---
description: Apply prompt-design rules when authoring or planning prompt-prose deliverables. Detects whether a deliverable IS prompt prose, and only then Reads the rules and applies every R-rule defined in `skills/_shared/prompt-design-rules.md` before drafting. Preloaded by agent files that may author prompt prose.
---

# Prompt Prose Writer

<!-- INCLUDE-BEGIN: prompt-prose-detection -->
**Prompt prose** is text authored to be loaded into an LLM's context as instructions, system prompts, agent definitions, skill definitions, reviewer rubrics, MCP tool descriptions, RAG instructions, or any equivalent LLM-consumable directive content.

**Detection rule (universal).** Use content semantics, not just file path or extension, as the determining signal. Ask: is the text intended to be loaded into an LLM's context at runtime as instructions? If yes, it is prompt prose, regardless of where it lives in the repo.

**Path and extension as secondary signals (fast-path shortcut for qrspi-plus-internal authoring).** When ALL target files match one of these globs, classify as prompt prose without further inspection:

- `skills/**/SKILL.md`
- `skills/**/*.md` (snippet files under a skill directory)
- `agents/*.md`
- `AGENTS.md`
- `CLAUDE.md`

Files outside these globs require the content-semantic test above. Other projects may carry prompts in `prompts/`, `src/llm-instructions/`, or custom layouts — the content-semantic test is universal; the glob list is qrspi-plus-internal convenience only.

**Examples of prompt prose:**

- A SKILL.md body that instructs an orchestrator.
- An `agents/*.md` file defining a subagent (role, task, constraints, tools).
- A `.md` file under a project's `prompts/` directory whose frontmatter `description:` indicates LLM consumption.
- A verbatim system prompt embedded in any markdown file (e.g., "You are...", "Your role is...", `<HARD-GATE>` blocks).
- A `.txt` or `.json` file whose content is plainly an LLM instruction payload.

**Examples of NOT prompt prose:**

- Code documentation, README files describing features.
- Design decisions in prose form (unless a `<!-- prose-design: ... -->` marker indicates a verbatim prompt-prose block within).
- Research notes ABOUT prompts (this file itself is a meta-document — it IS subject to the rules per meta-acceptance, but ordinary research/explanatory content about prompts is not).
- Configuration files, test fixtures, shell scripts.

**Rules file.** When prompt-prose authoring or review applies, the rules live at `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention).
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-writer-addition -->
**Writer-side application.** When authoring or planning a deliverable, apply the detection above to the planned target content (or sub-block, for blocks within larger documents like `design.md`). If the target IS prompt prose, Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply every R-rule defined in that file + cross-cutting principles BEFORE drafting, not as post-write polish. The rules shape what to write; patching after the fact is a known anti-pattern. If the Read fails, do NOT proceed with authoring. Surface the error and stop.

**If the target is NOT prompt prose** (ordinary documentation, configuration, code, non-prompt prose), do NOT Read the rules file. Reading-without-applying is the verbosity-bias anti-pattern the rules themselves warn against — loading them into context for a deliverable they don't apply to wastes context and risks misapplication.
<!-- INCLUDE-END: prompt-prose-writer-addition -->

<!-- Guard: if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above,
do NOT apply this skill. Surface a load error naming the missing block and stop —
partial context is worse than no skill. -->
