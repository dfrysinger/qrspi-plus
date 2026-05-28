---
status: approved
---

# Research Questions

1. [codebase] How do the existing subagent dispatch sites across `skills/**/SKILL.md` and `agents/qrspi-*.md` currently express model choice (frontmatter, inline override, env var, or hardcoded default), and which surfaces are read at dispatch time vs. at session start?
2. [web] How do open-source plugin and agent frameworks (Claude Code plugins, OpenDevin, AutoGen, LangGraph, Aider) express per-component model-routing policies in configuration, and what schema shapes are common in their published configs?
3. [codebase] What is the call shape, error handling, and stdout/stderr contract of `scripts/run-codex-review.sh` and `scripts/codex-companion-bg.sh`, and how does main chat or a dispatching skill consume their output?
4. [web] What OpenAI Chat Completions compatibility surfaces do current third-party LLM endpoints expose, including request/response shape, streaming semantics, and error-code conventions, as of 2026-05?
5. [web] What patterns do public developer writeups describe for invoking third-party LLM endpoints from CLI-driven or agent harnesses, and what concerns recur across those writeups?
6. [codebase] How does `skills/plan/SKILL.md` currently structure its generation-side sub-subagent dispatch, and where in the SKILL flow does the post-approval split-into-task-files step live today?
7. [codebase] What are the canonical task-file templates under `templates/` or referenced by `skills/plan/SKILL.md` for `tasks/task-NN.md`, and what frontmatter and section contracts do those templates currently document?
8. [codebase] How is prompt composition currently assembled at dispatch sites across `skills/` and `agents/`, and what inputs are typically composed at each site?
9. [web] What mechanisms or patterns do agent frameworks use to manage large, stable inputs that recur across dispatches?
10. [codebase] How does the TDD cycle inside `skills/implement/SKILL.md` and `agents/qrspi-implementer.md` currently sequence test-writing and production-code writing within a single dispatch, and where does `agents/qrspi-test-writer.md` already plug in (per `test-test-writer-tool-grant.bats`)?
11. [web] What does published research and developer-tooling literature say about quality and failure-mode differences when test authoring is split from production-code authoring in LLM coding agents?
12. [codebase] How does `skills/implementer-protocol/SKILL.md` thread reviewer-finding and task identifiers into fix-cycle implementer prompts?
13. [codebase] What worktree-related pre-flight checks does `skills/parallelize/SKILL.md` mandate in its process steps, and how does `skills/parallelize/owns-defers.md` partition responsibilities between Parallelize and downstream skills around worktree concerns?
14. [codebase] What Branch Map vocabulary is canonical in `skills/parallelize/SKILL.md` Branch Model and Worked Example, and what Branch Map vocabulary, if any, is defined or assumed in `agents/qrspi-parallelize-reviewer.md` and `skills/reviewer-protocol/SKILL.md`?
15. [codebase] Where in the QRSPI pipeline (Plan, Parallelize, Implement, reviewer agents) do dispatch prompts treat a reference artifact as ground truth, and what kinds of reference artifacts appear today?
16. [codebase] How does `agents/qrspi-visual-fidelity-reviewer.md` (if present in the repo) handle the relationship between task specs and the reference source they cite, and how do current task-spec templates surface intentional deviations from a referenced source?
17. [codebase] How does `skills/implementer-protocol/SKILL.md` sequence the steps of its commit procedure, and what does the qrspi-plus repo's `.gitignore` currently exclude from staging?
18. [codebase] How does `tests/unit/test-u14-lint.bats` construct its file-path scan and excluded-skill substring check, and how do other BATS tests in `tests/unit/` derive skill identity from file paths?
19. [codebase] What awk/grep section-extraction patterns recur across `tests/unit/test-skill-md-content-patterns.bats`, `test-cross-skill-contracts.bats`, and similar SKILL-body assertion tests, and what conventions, if any, do those tests share?
20. [codebase] What scope or responsibility does `skills/replan/SKILL.md` currently describe for itself relative to `skills/goals/SKILL.md`, and how does `skills/replan/SKILL.md` describe handling new items surfaced during phase completion that are not already formal goals?
22. [web] What current GitHub Actions patterns (2025–2026) exist for running BATS test suites and shell linting on `ubuntu-latest`, including dependency installation, matrix strategies, and caching?
23. [codebase] What branch-naming conventions are documented in `AGENTS.md` and `skills/implement/SKILL.md` Branch Model, and how do those namespaces appear in current scripts or templates?
24. [codebase] Which `skills/**/SKILL.md` and `agents/qrspi-*.md` files in the current `main` branch contain release-version strings or milestone references, and which dated or version-tagged file paths exist today that are intentionally release-bound?
25. [web] What lint or CI patterns do other markdown-driven prompt or skill libraries use to detect or prevent version strings, milestone references, or other dated language from accumulating in files intended to be stable across releases?
26. [codebase] What dispatcher classes exist today across `skills/` and `agents/`, and what is the input/output shape of each?
27. [web] What methodologies does published research describe for A/B-comparing outputs of LLM coding agents — replay harnesses, golden-output comparison, blind grading rubrics — and what failure modes do those methodologies surface?
28. [web] What freshness and accuracy contracts are published for derived or condensed prompt inputs used in agent frameworks?
29. [codebase] What in-file token or identifier conventions, if any, do existing QRSPI implementer agents and protocols document?
30. [codebase] How does the QRSPI pipeline today validate or version reference artifacts that downstream reviewers compare against?
31. [codebase] How does the QRSPI pipeline currently parse `config.md`, apply defaults for fields that did not exist when an older resumed run was created, and warn or migrate older configurations?
