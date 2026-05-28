---
status: draft
question_ids: [11,27]
research_type: web
---

# Q11, Q27: LLM coding-agent test/code role splits and A/B evaluation methodologies

## Summary

**TL;DR:** Published work supports a distinction between code-producing agents and independent validation or testing mechanisms, but the literature found here more often studies role-structured multi-agent workflows and external benchmark tests than a clean controlled experiment where one LLM writes production code and another independently authors tests. The recurring quality finding is that independent or staged validation exposes correctness gaps hidden by weak tests, while role separation is reported to reduce inconsistency and cascading hallucination in multi-agent workflows. For A/B comparisons, the dominant methodologies are benchmark replay harnesses, unit-test or hidden-test pass rates, benchmark hardening, and patch-validation workflows.

**Key findings:**
- Multi-agent software-development systems such as ChatDev and MetaGPT use separated roles or staged responsibilities across design, coding, and testing, and report that structure is intended to reduce hallucination, inconsistency, and workflow fragmentation.
- Independent or strengthened test suites, as in EvalPlus, materially reduce reported pass rates and can change model rankings, showing that weak tests overstate coding quality.
- SWE-bench-style replay harnesses compare agents by applying generated patches to real repositories and checking whether issue-linked tests pass.
- Agentless reports that benchmark quality itself can confound A/B comparisons; SWE-bench Lite contained cases with patch leakage or insufficient/misleading issue descriptions, motivating a cleaned SWE-bench Lite-S subset.
- Execution-feedback harnesses such as InterCode evaluate agents through iterative code execution, surfacing failures that static prompt-to-code evaluation can miss.

**Surprises:** The searched literature contained more evidence about independent validation and role-structured agent workflows than about a direct head-to-head comparison of “same agent writes code and tests” versus “separate agent writes tests.”

**Caveats:** WebFetch rate limits prevented fetching several additional candidate sources, including some leaderboard and benchmark pages. Findings are based on the fetched sources listed below and general published-paper metadata available at those URLs.

## Full findings

### Query planning

For Q11, the search plan was to identify:
- multi-agent LLM software-engineering papers with separated roles such as developer, reviewer, tester, or staged SOPs;
- papers evaluating code generation with external tests or independently generated tests;
- reported quality differences and failure modes linked to role separation, weak tests, hallucination, inconsistency, or test insufficiency.

For Q27, the search plan was to identify:
- benchmark replay harnesses for real-world coding agents;
- golden-output, unit-test, or hidden-test comparison methods;
- benchmark-cleaning or benchmark-hardening methods;
- blind or rubric-based judging where automated tests are insufficient;
- reported failure modes surfaced by these methods.

### Q11: Published findings on splitting test authoring from production-code authoring

#### Multi-agent role separation is studied mainly as staged software workflow, not always as isolated test/code authoring

ChatDev presents “Communicative Agents for Software Development,” a multi-agent framework in which LLM agents collaborate across software-development phases including design, coding, and testing. The fetched abstract/page summary describes a “chat chain” and “communicative dehallucination” mechanism, with natural-language interaction used for system design and programming-language interaction used for debugging. It identifies a workflow-level failure mode in earlier phase-specific systems: separate phase-specific models can create inconsistent tooling across design, coding, and testing, weakening the development workflow. Source: https://arxiv.org/abs/2307.07924

MetaGPT presents “Meta Programming for A Multi-Agent Collaborative Framework,” using standardized operating procedures encoded into prompts and an assembly-line paradigm for specialized agents. The fetched source reports that domain-specific roles check intermediate outputs and that the framework targets “logic inconsistencies” and “cascading hallucinations” in naïvely chained LLM-agent systems. This is relevant to test/code separation because testing and review appear as staged verification responsibilities rather than being collapsed into one undifferentiated agent. Source: https://arxiv.org/abs/2308.00352

The common finding across these role-structured systems is that separation is framed as a mechanism for coordination and verification. The reported failure modes are not simply “bad tests” but workflow-level errors: inconsistent intermediate artifacts, hallucinated assumptions, and cascaded mistakes from one phase to the next.

#### Independent validation exposes quality gaps hidden by weak tests

EvalPlus, “Is Your Code Generated by ChatGPT Really Correct?”, directly addresses test adequacy for LLM-generated code. It expands HumanEval into HumanEval+ using automatic input generation and evaluates 26 LLMs with pass@k. The fetched source reports that insufficient tests can inflate pass@k, allow incorrect generated code to pass public/original tests, and cause model mis-ranking. It reports pass@k reductions of up to 19.3–28.9% under stronger tests. Source: https://arxiv.org/abs/2305.01210

This is directly relevant to splitting test authoring from production-code authoring because it shows that when validation is strengthened independently of the model’s generated solution, measured quality drops and previously hidden failures appear. The surfaced failure modes include:
- solutions passing sparse public tests while failing expanded hidden-style tests;
- incorrect benchmark rankings caused by weak test suites;
- overestimation of correctness from original benchmark tests.

#### Agentic coding systems often run tests, but fetched sources did not show a clean test-author-vs-code-author ablation

SWE-agent, “Agent-Computer Interfaces Enable Automated Software Engineering,” evaluates an LLM coding agent on SWE-bench and HumanEvalFix. The fetched source reports pass@1 results and emphasizes an agent-computer interface for editing files, navigating repositories, and running tests/programs. It does not describe a separate test-authoring agent or a controlled comparison where test writing is split from code writing. Source: https://arxiv.org/abs/2405.15793

InterCode, “Standardizing and Benchmarking Interactive Coding with Execution Feedback,” models coding as an interactive environment where generated code is executed and execution results become observations. It uses Docker environments and benchmarks for Bash, SQL, and Python. The fetched source does not describe explicit separation between test writing and code writing; it instead studies execution feedback as a mechanism to reduce static benchmark limitations and error propagation. Source: https://arxiv.org/abs/2306.14898

These sources show a distinction between code generation and validation/execution feedback, but not necessarily independent test authoring. The quality difference identified is that interactive execution can surface runtime failures that static instruction-to-code evaluation may miss.

#### Benchmark and task defects can distort conclusions about role split quality

Agentless, “Demystifying LLM-based Software Engineering Agents,” evaluates a simpler localization-repair-validation workflow on SWE-bench Lite and compares it against open-source LLM software agents. The fetched source reports that the authors manually reviewed SWE-bench Lite and created SWE-bench Lite-S after finding problems such as exact ground-truth patch leakage and insufficient or misleading issue descriptions. Source: https://arxiv.org/abs/2407.01489

For Q11, this matters because any claimed quality difference between a code-writing agent and a test-writing/reviewing agent can be confounded by benchmark defects. If an issue description leaks the patch or is misleading, a split workflow may appear better or worse for reasons unrelated to test/code role separation.

### Q27: Methodologies for A/B-comparing outputs of LLM coding agents

#### Replay harnesses with real repository issues and tests

SWE-bench is a benchmark for evaluating whether models can resolve real-world GitHub issues. The fetched source describes 2,294 problems from 12 Python repositories, pairing GitHub issues with pull requests. Agents receive a repository and issue description and must modify the code. Competing agents can be A/B compared by whether their generated patches resolve the same issue instances. Source: https://arxiv.org/abs/2310.06770

Failure modes surfaced by SWE-bench-style replay:
- inability to coordinate edits across multiple functions, classes, or files;
- insufficient repository navigation and long-context handling;
- need for multi-step reasoning and execution-environment interaction;
- very low solve rates in early evaluations, with the fetched source reporting Claude 2 solved 1.96% of issues.

SWE-agent builds on this kind of replay-style evaluation and emphasizes the agent-computer interface as a variable affecting agent performance. Source: https://arxiv.org/abs/2405.15793

#### Golden-output and hidden-test comparison

HumanEval-style and EvalPlus-style methods compare generated code against expected behavior using unit tests. EvalPlus hardens this by generating additional tests through LLM-based and mutation-based strategies. Source: https://arxiv.org/abs/2305.01210

Failure modes surfaced:
- benchmark tests are too sparse to catch incorrect solutions;
- models pass original/public tests while failing expanded tests;
- pass@k metrics are inflated by weak tests;
- rankings can change when stronger tests are used.

This methodology is strong for deterministic programming tasks with executable specifications, but it measures behavioral equivalence under test coverage rather than full semantic correctness.

#### Patch validation and cleaned benchmark subsets

Agentless uses a three-step workflow of localization, repair, and patch validation on SWE-bench Lite. It also introduces SWE-bench Lite-S after manual review removed problematic cases. Source: https://arxiv.org/abs/2407.01489

This methodology surfaces two classes of failure:
- agent failure, where localization, repair, or validation does not produce a passing patch;
- benchmark failure, where examples contain patch leakage, insufficient descriptions, or misleading descriptions.

The second category is important for A/B comparisons because it means apparent differences between agents can be caused by contaminated or ambiguous tasks.

#### Interactive execution-feedback harnesses

InterCode standardizes interactive coding with execution feedback. It treats code outputs as actions and execution results as observations, using Dockerized environments for reproducibility. Source: https://arxiv.org/abs/2306.14898

Failure modes surfaced:
- static code generation can suffer from error propagation;
- generated code may not match the real execution setting;
- agents may fail to use runtime feedback effectively;
- iterative correction ability becomes measurable, unlike in one-shot golden-output evaluation.

This methodology is useful when comparing agents that differ in tool use, planning, and feedback handling, because it evaluates behavior over a trajectory rather than a single generated answer.

#### Multi-agent workflow benchmarks and staged artifact checking

ChatDev and MetaGPT evaluate multi-agent software-development workflows where multiple role-specialized agents produce and check artifacts across phases. Sources: https://arxiv.org/abs/2307.07924 and https://arxiv.org/abs/2308.00352

Failure modes surfaced:
- inconsistent artifacts between phases;
- hallucinated intermediate assumptions;
- cascading hallucinations from early steps into later implementation;
- coordination failures across role boundaries.

These methods are less like simple golden-output comparison and more like workflow evaluation. They are relevant for A/B testing agent architectures, especially when the outputs include designs, plans, tests, code, and review comments rather than only a final code patch.

#### Practical implications visible across the methodologies

Across the fetched literature, A/B comparisons of LLM coding agents depend heavily on the evaluation substrate:
- Unit-test and hidden-test methods expose behavioral correctness gaps.
- Replay harnesses expose repository-navigation, patch-integration, and multi-file reasoning failures.
- Interactive harnesses expose feedback-use and iterative-debugging failures.
- Cleaned benchmark subsets expose dataset leakage and ambiguous-task failures.
- Multi-agent workflow evaluations expose coordination, artifact-consistency, and hallucination-propagation failures.

The strongest methodological pattern is triangulation: papers increasingly combine executable validation with benchmark hardening or manual inspection because a single pass/fail metric can hide benchmark contamination, weak tests, or workflow-level defects.
