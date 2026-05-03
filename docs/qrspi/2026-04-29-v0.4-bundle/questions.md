---
status: approved
---

# Research Questions

1. [codebase] How is subagent dispatch structured today across the Implement skill — what dispatch levels exist, what tool grants each level receives, and where in the prompts/templates is the dispatch shape declared?
2. [web] What does the Claude Code subagent / Agent-tool documentation say about which tools subagents can use, how a subagent's tool grants are configured, and whether subagents can themselves dispatch further subagents?
3. [codebase] What feature-branch and worktree-branch naming conventions appear across the qrspi-plus skill prompts and templates today, and where in those prompts are branch strings referenced?
4. [web] What rules and conventions does git apply to ref hierarchies — how are refs nested under shared prefixes, what constraints govern simultaneous existence of refs that share path components, and what idioms exist for organizing related branches under a common namespace?
5. [codebase] What is the current shape and behavior of `scripts/codex-companion-bg.sh` — its externally visible interface (subcommands, exit codes), its dependency surface (what it invokes and what it reads from those invocations), and the test seams that exercise it?
6. [codebase] How is the `codex-companion` external dependency wired into qrspi-plus — where is `CODEX_COMPANION` referenced, how is its value resolved at call sites, and what assumptions do callers make about its availability?
7. [web] What is the documented behavior and JSON response shape of the upstream `codex-companion.mjs` for its `status --json` and `result --json` subcommands, and what fields are present in each response payload?
8. [web] What portable patterns exist for resolving the path to an external helper binary or script when distributing shell tooling as a Claude Code plugin, and what tradeoffs do those patterns carry across operator setups, version pins, and CI environments?
9. [codebase] What does `state.sh` currently do — what public functions does it expose, who calls each one, what does it persist, and what is the lifecycle of its persisted artifacts?
10. [codebase] What is the overall shape of the `hooks/` layer today — what files exist, what each enforces or audits, where each is invoked from, and what `hooks/lib/bash-detect.sh` does in particular?
11. [web] What does Anthropic's Claude Code native sandboxing cover today — which tools and operations the kernel-level sandbox mediates per supported platform, what configuration surface it exposes, and what gaps or known limitations are documented for it?
12. [web] How does the literature characterize the analysis of shell command lines for the purpose of inferring their effects — what techniques are used, what their accuracy properties are, and how they compare to alternative mechanisms for the same goals?
13. [codebase] Where across implementer prompts, reviewer prompts, per-task-orchestrator templates, task-spec scaffolding, and commit-message guidance do internal-to-the-methodology identifiers and external tracker references appear, and in what contexts (code identifiers, string literals, comments, test names, prompt text, commit-message examples) do they show up?
14. [web] What do mainstream style guides and engineering culture sources prescribe regarding the appearance of issue-tracker IDs and project-internal reference IDs across code identifiers, string literals consumed at runtime, comments, test names, commit messages, and PR descriptions?
15. [codebase] How does the Implement skill route a task through TDD today — what steps the per-task orchestrator runs, what the implementer is asked to produce, what the reviewer is asked to evaluate, and how this flow is described across `implement/SKILL.md` and its templates?
16. [web] What prior art exists for differentiating task types in development-automation systems along any axis, and what governance, classification, and correction patterns do those systems document?
17. [codebase] What is the current Research → Design handoff in qrspi-plus — what artifacts Research produces, what Design reads, and where the handoff is described in the skill prompts?
18. [web] What shapes do source-authored summary blocks take at the head of long-form research, investigation, or technical reports across prior art, and what tradeoffs do different summary structures carry for downstream readers?
19. [codebase] Where in implementer prompts, reviewer prompts, templates, and acceptance-test fixtures does commenting guidance appear today, and how is that guidance phrased?
20. [web] What guidance do mainstream style guides, programming books, and engineering culture sources provide on the purpose and content of code comments — what categorizations of comments do they document, and what examples of good and poor comments do they cite?
21. [codebase] What is the shape of the qrspi-plus test corpus under `tests/` — how are tests organized by directory and naming, what each category asserts against, and what regression class each category protects?
22. [web] What patterns do prompt-driven and AI-assisted development projects use to guard against unintended prompt regressions, and what tradeoffs do those patterns carry across maintenance cost, signal quality, and false-positive rate?
23. [codebase] How does `skills/integrate/` orchestrate the multi-task merge — what steps it runs, what review passes it dispatches, what gates it enforces, and what artifacts it consumes and produces?
24. [codebase] How are task-spec frontmatter and metadata fields currently parsed and consumed across the qrspi-plus pipeline — which fields exist, where each is read, and how downstream skills route on their values?
25. [codebase] Where, if anywhere, do implementer, reviewer, and per-task-orchestrator templates today address separation of perspective between the agent that produces work and the agent that reviews it, and how is that separation phrased or enforced?
26. [codebase] How does the Plan / Parallelize / Implement chain currently determine which subagent runs which role for a given task, and where in the prompts is the assignment of roles to dispatch sites declared?
27. [web] How do published agentic-development frameworks structure the transfer of information between research and design stages, and what evidence is reported on the quality and cost properties of each approach?
28. [codebase] What CI configuration governs the qrspi-plus test suite today — which suites run, what platform matrix is used, and what conditional gating (e.g., environment-flagged suites) is already in place?
