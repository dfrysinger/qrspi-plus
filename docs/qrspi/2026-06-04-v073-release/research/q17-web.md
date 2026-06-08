---
status: draft
question_ids: [17]
research_type: web
---

# Q17: Patterns for organizing and structuring long-running prompt libraries in LLM agent systems while preserving behavioral correctness

## Summary

**TL;DR:** Production LLM agent systems have converged on several overlapping patterns for managing prompt libraries: file-based modular storage (one YAML/Jinja2 file per prompt with embedded metadata), prompt versioning via commit-history in centralized registries, evaluation-driven correctness gates integrated into CI/CD, and workflow decomposition patterns (chaining, routing, parallelization, orchestrator-workers) that isolate each prompt's behavioral surface. The strongest behavioral-correctness guarantees come from pairing version control with explicit evaluation suites that are run before any prompt is promoted to production.

**Key findings:**
- **Evals-before-prompting discipline**: Multiple authoritative sources (Anthropic, Eugene Yan, PromptFlow) prescribe defining success criteria and building labeled evaluation sets (≥100 examples) _before_ writing or modifying prompts, so regressions are detectable.
- **File-based modular storage**: Microsoft Semantic Kernel and PromptFlow use per-function YAML files containing the prompt template, variable declarations, execution settings, and metadata—organized in a directory tree by plugin/capability. Microsoft PromptFlow uses Jinja2 template files alongside YAML descriptor files.
- **Centralized prompt registries with versioning**: LangChain Hub, LangFuse, Helicone, Agenta, and PromptLayer all provide a commit-based version history where every prompt save creates a new immutable version; rollback is explicit. SDK-based pull-by-name (`hub.pull("owner/prompt-name")`) decouples prompt identity from file path.
- **Workflow decomposition patterns**: Anthropic identifies five canonical patterns—Augmented LLM, Prompt Chaining, Routing, Parallelization (sectioning + voting), Orchestrator-Workers, and Evaluator-Optimizer—each of which scopes individual prompts to a narrower behavioral role, making regression testing more tractable.
- **DSPy "programming not prompting"**: Stanford DSPy replaces handwritten string prompts with typed Python _Signatures_ and composable modules; prompt text is produced by a compiler/optimizer, removing direct human editing of production prompt strings.
- **Variants/A-B pattern**: PromptFlow's Variants concept provides side-by-side comparison across different prompt texts and model settings before any variant is designated canonical.
- **Prompt-as-artifact separation**: The consistent recommendation across Anthropic, Helicone, and the Applied LLMs community is to decouple prompts from source code—stored separately and deployed independently—so non-engineers can iterate without a code change cycle.

**Surprises:** Anthropic explicitly states that for their SWE-bench coding agent, engineers spent _more_ time optimizing tool definitions (which are effectively structured prompts) than the overall system prompt—suggesting that in tool-using agents, tool documentation is a first-class part of the prompt library.

**Caveats:** Most public material is from vendor documentation, practitioner blogs, and framework READMEs (2023–2025). Peer-reviewed empirical studies comparing organizational patterns are sparse. The DSPy "compiler" approach is the subject of academic papers but its production adoption at large scale is less documented than the registry/versioning pattern. Sites using heavy client-side JavaScript (Helicone, LangFuse, W&B) could not be fully scraped; some content was inferred from partial renders and README files.

---

## Full findings

### 1. The Evals-First Behavioral Correctness Pattern

Multiple high-authority sources converge on a single prerequisite for behavioral correctness: **evaluations must exist before prompt engineering begins**, not after.

- **Anthropic's prompt engineering guide** (https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview): "Before prompt engineering... Have a clear definition of the success criteria for your use case. Some ways to empirically test against those criteria. A first draft prompt you want to improve."

- **Eugene Yan** (https://eugeneyan.com/writing/prompting/): "Before doing any major prompt engineering, we need reliable evals. Without evals, how would we measure improvements or regressions? Workflow: (i) manually label ~100 eval examples, (ii) write initial prompt, (iii) run eval, and iterate on prompt and evals, (iv) eval on held-out test set before deployment."

- **Microsoft PromptFlow** (https://microsoft.github.io/promptflow/) defines a distinct **Evaluation Flow** type (separate from Standard and Chat flows) specifically for running batch eval on prompt outputs and computing quality metrics. The README states that CI/CD integration of eval is a core design goal: "Integrate the testing and evaluation into your CI/CD system to ensure quality of your flow."

- **Helicone** (https://www.helicone.ai/blog/prompt-management) explicitly warns: "Not testing across different models: Prompts optimized for one model may not perform well on another. Always test across multiple LLMs before deployment." and "Monitor model drift—prompt effectiveness may change over time."

The common technique set for correctness verification includes:
- **Automated metrics**: LLM-as-judge, exact match, custom scoring functions
- **Human evaluation / human-in-the-loop annotation**
- **A/B testing**: comparing candidate versions against each other with real or held-out data
- **Regression test suites**: maintained eval sets that detect behavioral change on any new prompt version

---

### 2. File-Based Modular Prompt Storage

Two major production frameworks use a per-prompt-file storage pattern:

#### Microsoft Semantic Kernel (directory-based YAML plugins)

Source: https://github.com/microsoft/semantic-kernel (README + `CreatePromptPluginFromDirectory.cs` sample)

Structure:
```
./Plugins/PluginName/
    function_name.yml
```

Each `.yml` file contains:
- `name`: function name
- `template`: the prompt string (with Handlebars-style `{{$variable}}` slots)
- `template_format`: e.g., `semantic-kernel`
- `description`: human-readable description of the prompt's purpose
- `input_variables`: list of typed variable declarations with descriptions and `is_required`
- `output_variable`: description of expected output
- `execution_settings`: model parameters (temperature, max_tokens, etc.)

This structure is loaded via `kernel.ImportPluginFromPromptDirectoryYaml(path, "PluginName")` and each YAML file becomes a discrete `KernelFunction` callable within the agent.

#### Microsoft PromptFlow (DAG flows with Jinja2 templates)

Source: https://microsoft.github.io/promptflow/concepts/concept-flows.html + raw template files in the repo

Each LLM step in a DAG flow is defined as a Jinja2 template file (`.jinja2`) referenced from the flow's `flow.dag.yaml`. Example from `examples/flows/standard/web-classification/classify_with_llm.jinja2`:

```jinja2
# system:
Your task is to classify a given url into one of the following categories...

# user:
The selection range of the value of "category" must be within ...
Here are a few examples:
{% for ex in examples %}
URL: {{ex.url}}
...
{% endfor %}
For a given URL and text content, classify the url:
URL: {{url}}
```

PromptFlow distinguishes three flow types:
1. **Standard flow**: for building LLM applications
2. **Chat flow**: like standard, adds `chat_history`, `chat_input`, `chat_output` support
3. **Evaluation flow**: consumes outputs of standard/chat flows and computes quality metrics

---

### 3. Centralized Prompt Registries with Version History

Multiple platforms provide a registry pattern where prompts are stored externally from source code, versioned, and fetched at runtime.

#### LangChain Hub / LangSmith
Source: https://www.langchain.com/blog/langchain-prompt-hub (announcement, Sep 2023)

- **Pull by name**: `from langchain import hub; prompt = hub.pull("hwchase17/eli5-solar-system")`
- **Push with commit**: `hub.push("<handle>/prompt-name", prompt)` — each push creates a new immutable commit
- **Rollback**: any prior commit is addressable; "you can easily access previous versions of prompts should you want to go back"
- **Tags**: model compatibility tags (e.g., which model the prompt was tested on)
- **Playground**: "Try it" button opens the prompt for interactive testing before committing
- **Organizational collaboration**: designed for cross-functional teams (engineers + non-engineers) to collaborate without requiring code deploys

Key design rationale from announcement: "we don't believe that prompts should be treated as traditional code—it's simply not the best way to facilitate this kind of collaboration."

#### Agenta
Source: https://github.com/Agenta-AI/agenta (README)

Features from Agenta README:
- **Version control**: "Version prompts and configurations with branching and environments"
- **Multi-model playground**: compare same prompt across 50+ models side-by-side
- **Testsets**: create from production data, playground experiments, or CSV upload
- **Evaluators**: 20+ pre-built evaluators including LLM-as-judge; custom evaluators supported
- **Environments**: branching with dev/staging/prod environment promotion

#### Helicone
Source: https://www.helicone.ai/blog/prompt-management

Key patterns from Helicone's model:
- **Version control with rollback**: track all prompt versions, revert if performance degrades
- **Prompt Experiments**: compare prompt variants against real production data
- **Prompt Editor**: live preview of how changes affect outputs before promotion
- **Prompt isolation from code**: "Decouple prompts from code to enable rapid iteration and testing"
- **Common pitfall**: "Hardcoding prompts into the codebase: Embedding prompts directly into application code makes iteration slow and inefficient. Instead, use a versioned prompt management system."

---

### 4. Workflow Decomposition Patterns (Anthropic's Taxonomy)

Source: https://www.anthropic.com/engineering/building-effective-agents

Anthropic identifies composable patterns that each scope a single LLM call to a narrower behavioral role. Narrower roles make individual prompts easier to test and maintain:

1. **Augmented LLM** (base building block): LLM enhanced with retrieval, tools, memory. Single-call scope. "Tailoring these capabilities to your specific use case and ensuring they provide an easy, well-documented interface for your LLM."

2. **Prompt Chaining**: Decompose task into sequential LLM calls; each call processes the output of the prior. Programmatic "gate" checks can be inserted between steps. "Trade off latency for higher accuracy, by making each LLM call an easier task."

3. **Routing**: A classification prompt routes inputs to specialized downstream prompts. Separation of concerns prevents cross-domain prompt conflicts. Use case: directing "refund requests" vs. "technical support" vs. "general questions" to different prompts/models.

4. **Parallelization** (two sub-patterns):
   - *Sectioning*: Break task into independent subtasks run simultaneously (e.g., guardrail LLM + response LLM run in parallel)
   - *Voting*: Run the same prompt N times for diverse outputs, aggregate (e.g., N independent code review prompts, each flagging vulnerabilities independently)

5. **Orchestrator-Workers**: Central LLM dynamically plans and delegates subtasks to worker LLMs. Subtasks are not predefined—orchestrator decides based on input. Different from parallelization's pre-defined structure.

6. **Evaluator-Optimizer**: One LLM generates responses; another evaluates and provides feedback in a loop. For use when "LLM responses can be demonstrably improved when a human articulates their feedback." The evaluator prompt is a first-class library member.

---

### 5. DSPy: Programs Not Prompts

Source: https://github.com/stanfordnlp/dspy (README, Oct 2023 paper: arXiv:2310.03714)

DSPy takes a fundamentally different approach to organizing a prompt library: **instead of maintaining prompt strings, developers write typed Python modules** (called Signatures and Predictors), and a compiler/optimizer algorithm produces the actual prompts used at inference time.

Key concepts:
- **Signatures**: typed Python functions declaring input/output fields with descriptions (e.g., `question: str -> answer: str`) — these replace handwritten prompt strings
- **Modules**: composable building blocks like `ChainOfThought`, `ReAct`, `MultiChainComparison`
- **Teleprompters/Optimizers**: automated algorithms that search over prompt formulations (including few-shot examples) to find the best-performing combination given a metric function
- **No brittle strings**: "Instead of brittle prompts, you write compositional Python code and use DSPy to teach your LM to deliver high-quality outputs"

DSPy behavioral correctness mechanism: the optimizer directly optimizes against a specified metric (i.e., correctness is a first-class objective during prompt generation). Papers: "Optimizing Instructions and Demonstrations for Multi-Stage Language Model Programs" (Jun 2024) and "DSPy Assertions: Computational Constraints for Self-Refining Language Model Pipelines" (Dec 2023).

---

### 6. Prompt Variants and A/B Testing Pattern

Source: https://microsoft.github.io/promptflow/concepts/concept-variants.html

Microsoft PromptFlow's **Variants** concept: within a single flow node, multiple variants can be defined, each with different prompt text or model settings:

| Variant | Prompt | Temperature |
|---|---|---|
| Variant 0 | `Summary: {{input sentences}}` | 1.0 |
| Variant 1 | `Summary: {{input sentences}}` | 0.7 |
| Variant 2 | `What is the main point? {{input sentences}}` | 1.0 |
| Variant 3 | `What is the main point? {{input sentences}}` | 0.7 |

Benefits cited:
- "Track and compare the performance of each prompt version"
- "Manage the historical versions of your LLM nodes, facilitating updates based on any variant without the risk of forgetting previous iterations"
- "Effortlessly compare the results obtained from different variants side by side"

---

### 7. Prompt Engineering for Tools (ACI Pattern)

Source: https://www.anthropic.com/engineering/building-effective-agents (Appendix 2)

Anthropic's Appendix 2 specifically addresses **tool definitions as a part of the prompt library** — tool descriptions and parameter definitions require the same engineering rigor as system prompts:

Key guidance:
- "Tool definitions and specifications should be given just as much prompt engineering attention as your overall prompts."
- Tool documentation should include: "example usage, edge cases, input format requirements, and clear boundaries from other tools"
- Format selection principles: give the model enough "thinking" tokens; keep format close to natural internet text; avoid "overhead" (e.g., line-count tracking in diffs)
- "We actually spent more time optimizing our tools than the overall prompt" (for the SWE-bench agent)
- Poka-yoke principle: "Change the arguments so that it is harder to make mistakes" — e.g., requiring absolute file paths instead of relative paths

This establishes tool definitions as members of the prompt library with their own correctness requirements.

---

### 8. Guidance / Constrained Generation Pattern

Source: https://github.com/guidance-ai/guidance (README)

Microsoft's Guidance library represents a different organizational pattern: **interleaving generation and control flow in a single Python program** using context managers and generation primitives:

```python
with system():
    lm += "You are a helpful assistant"
with user():
    lm += "Hello. What is your name?"
with assistant():
    lm += gen(name="lm_response", max_tokens=20)
```

Behavioral correctness mechanism:
- `gen(regex=r"\d+")` — constrain output to match regex, enforced at the token level
- `select(["A", "B", "C", "D"])` — constrain output to a finite set
- Context Free Grammar constraints for arbitrary structural constraints
- **Offline grammar validation**: "When iterating on constraints, you can validate candidate strings locally and test a full run with the `Mock` model" (no API calls needed for structural testing)

This pattern moves behavioral correctness from evaluation after the fact to **compile-time and inference-time constraints**.

---

### 9. System Prompt Structural Organization within a Single Prompt

Source: Anthropic documentation (Claude model card, API docs)

For complex system prompts that must cover multiple behavioral aspects, Anthropic recommends using XML tags to create explicit sections within the prompt string:

- XML-tagged sections separate identity, task context, constraints, tool descriptions, and format instructions
- Claude is specifically trained to respond to XML structure in prompts
- Common section pattern: `<identity>`, `<instructions>`, `<constraints>`, `<examples>`, `<output_format>`
- This is an intra-prompt organizational pattern rather than a cross-prompt library pattern

The DAIR.AI Prompt Engineering Guide (https://github.com/dair-ai/Prompt-Engineering-Guide) catalogs additional structural techniques including role assignment, few-shot examples, chain-of-thought, and retrieval-augmented context as distinct compositional sections.

---

### 10. Cross-Cutting Principles from Production Experience

From Helicone's "Common Pitfalls to Avoid" and the broader practitioner community:

1. **Never hardcode prompts in source code**: Embeds prompts in the deployment cycle; blocks iteration by non-engineers
2. **Test across models before deployment**: Prompts are model-specific; Claude prefers XML encoding, Llama2 uses SYS/INST tokens; cross-model compatibility must be explicitly verified
3. **Avoid overengineering prompts**: "Long, overly engineered prompts often produce inconsistent results. Aim for clarity and conciseness."
4. **Monitor prompt drift**: Model updates can change how prompts are interpreted even if the text is unchanged; periodic re-eval is required
5. **Input sanitization for injection prevention**: Prompt injection is a structural attack vector against any prompt library; input validation and sandboxed execution are required for correctness under adversarial conditions (per Helicone's "Prompt Injection Attack Prevention" section)
6. **Start simple**: Anthropic's "Building Effective Agents" repeatedly recommends starting with the simplest possible solution: "Success in the LLM space isn't about building the most sophisticated system."
