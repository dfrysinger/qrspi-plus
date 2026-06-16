---
description: Apply prompt-design rules when reviewing prompt-prose subjects in a diff. Detects which files (or sub-blocks) are prompt prose, applies every R-rule defined in `skills/_shared/prompt-design-rules.md` + cross-cutting principles + finding-type gate, and emits findings with proper change_type tagging. Preloaded by reviewer agents that may encounter prompt prose in their review subject.
---

# Prompt Prose Reviewer

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

<!-- INCLUDE-BEGIN: prompt-prose-reviewer-addition -->
**Reviewer-side application.** For each file (or sub-block, for blocks within larger documents like `design.md`) in the diff, apply the detection above. Apply liberally — when content semantics indicate prompt prose, treat as in-scope regardless of file path or extension.

For each file or block determined to be prompt prose: Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply every R-rule defined in that file + cross-cutting principles + finding-type gate. If the Read fails, do NOT emit findings. Surface the error and stop the review entirely — do not proceed with any further files. Emit findings using the standard reviewer schema, tagged:

- `change_type: clarity` for verbosity / anchor-phrase / structure-quality findings.
- `change_type: correctness` for finding-type-gate violations (e.g., load-bearing rule placed at start instead of end, examples exceeding the 2-cap, missing Iron-Law markers on override-critical content).
<!-- INCLUDE-END: prompt-prose-reviewer-addition -->

<!-- Guard: if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above,
do NOT apply this skill. Surface a load error naming the missing block and stop —
partial context is worse than no skill. -->
