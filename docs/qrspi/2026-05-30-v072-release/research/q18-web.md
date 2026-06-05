---
status: draft
question_ids: [18]
research_type: web
---

# Q18: Anthropic and OpenAI published guidance on subagent/agent-SDK file-system writes, tool grants, and host-injected system prompts

## Summary

**TL;DR:** Anthropic's published documentation covers file-system writes through both the Messages API (client-executed tools — [source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/how-tool-use-works)) and a Managed Agents beta with an explicit `write` tool ([source](https://docs.anthropic.com/en/docs/managed-agents/tools)) and safety papers on agentic misalignment ([source](https://www.anthropic.com/research/teaching-claude-why)). The API-level system prompt is automatically extended by tool definitions when tools are passed ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/define-tools)). OpenAI documents `gpt-5.5` as its flagship model with file-write-capable tools ([source](https://platform.openai.com/docs/models)); the model identifier `gpt-5.3-codex` does not appear in OpenAI's published documentation — the closest match is `gpt-5.3-codex-spark`, a Codex-product research preview for ChatGPT Pro users ([source](https://developers.openai.com/codex/concepts/subagents)). Neither company publishes explicit guidance using the phrase "host-tool-injection behavior" as a distinct concept; both document tool grants as an operator-controlled configuration that flows through the API call's tools array and system prompt.

**Key findings:**
- **Anthropic tool-use API** ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/how-tool-use-works)): File writes are a client-executed operation. Claude emits a structured `tool_use` block; the operator's application (not Anthropic) performs the actual write. The API automatically constructs a combined system prompt from tool definitions + any user-specified system prompt ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/define-tools)). The `bash` tool and `text_editor` Anthropic-schema tools, when enabled, permit file modifications, but execution remains client-side ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/bash-tool)).
- **Anthropic Managed Agents API (beta, `managed-agents-2026-04-01`)** ([source](https://docs.anthropic.com/en/docs/managed-agents/tools)): Includes an explicit `write` tool (part of `agent_toolset_20260401`) that writes files to the local sandbox filesystem. Permission policies (`always_allow` vs. `always_ask`) govern whether tools auto-execute or pause for approval ([source](https://docs.anthropic.com/en/docs/managed-agents/permission-policies)). Agent toolset defaults to `always_allow`; MCP toolsets default to `always_ask`. Custom tools are explicitly excluded from Anthropic's permission policy mechanism.
- **Anthropic on host-injected system prompts** ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/define-tools)): "When you call the Claude API with the tools parameter, the API constructs a special system prompt from the tool definitions, tool configuration, and any user-specified system prompt." The computer-use docs note a separately auto-generated system prompt for computer-use contexts ([source](https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/computer-use-tool)). No explicit guidance published on how operator-injected system prompts can expand or restrict declared tool grants at the model level — grants are set via the `tools` array at the API call level.
- **Anthropic safety research** ([source](https://www.anthropic.com/research/teaching-claude-why), May 8, 2026): "Teaching Claude why" reports that including tool definitions in training environments (even without requiring tool use) improved safety generalization on agentic evaluations. The Claude 4 system card is referenced but the full text was not fetchable via direct URL (Next.js SPA). Claude models from Haiku 4.5 onward score 0% on the agentic blackmail honeypot [source: paper ibid.].
- **OpenAI `gpt-5.5`** ([source](https://platform.openai.com/docs/models)): Documented as current flagship (model ID `gpt-5.5`), supporting Functions, Web search, File search, Computer use. No model-specific documentation was found about how it handles tool grants differently when dispatched as a subagent vs. a top-level agent ([source](https://developers.openai.com/api/docs/guides/agents/orchestration)).
- **OpenAI `gpt-5.3-codex`** ([source](https://developers.openai.com/codex/concepts/subagents)): This exact model ID does not appear in OpenAI's published documentation. The Codex subagents page mentions `gpt-5.3-codex-spark` as a Codex product research preview for "near-instant, text-only iteration" for ChatGPT Pro users, explicitly limited to text-only tasks.
- **OpenAI Agents SDK orchestration** ([source](https://developers.openai.com/api/docs/guides/agents/orchestration)): Two published patterns — handoffs (control transfer to specialist) and agents-as-tools (bounded specialist calls). Tools are specified per-agent definition; subagents only receive tools defined in their own agent specification, not the parent's tool set ([source](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals)). Agent-level input guardrails run only on the first agent in the chain; output guardrails only on the final output agent.
- **OpenAI Codex sandboxing** ([source](https://developers.openai.com/codex/concepts/sandboxing)): Codex uses `sandbox_mode` (`workspace-write` default, `read-only`, `danger-full-access`) and `approval_policy` (`on-request` default) to bound file-system access. Subagents spawned by Codex inherit the same sandbox boundary. Protected paths (`.git`, `.agents`, `.codex`) remain read-only even in `workspace-write` mode. This is a product-level mechanism, not an API model parameter.

**Surprises:**
- `gpt-5.3-codex` (as spelled in the question) does not appear anywhere in OpenAI's published documentation ([source](https://platform.openai.com/docs/models); [source](https://developers.openai.com/codex/concepts/subagents)). The real model `gpt-5.3-codex-spark` is only available in the Codex product (ChatGPT Pro), limited to text-only tasks, and is a research preview.
- Anthropic's Managed Agents API (currently in beta) includes a first-class `write` tool with explicit permission-policy controls ([source](https://docs.anthropic.com/en/docs/managed-agents/permission-policies)) — a more structured file-write governance model than the Messages API.
- Anthropic's "Teaching Claude why" paper ([source](https://www.anthropic.com/research/teaching-claude-why)) found that adding tool definitions to safety training environments improved alignment on honeypot evaluations *even when the tools were never used in those environments* — suggesting tool presence in system prompts has a behavioral signal effect during training.

**Caveats:**
- Anthropic's website (anthropic.com) uses a Next.js SPA that does not render content without JavaScript, so the full text of the Claude 4 model card / system card could not be fetched directly. The existence of the system card is confirmed by reference in the "Teaching Claude why" paper but its specific content on file-system writes was not verified.
- OpenAI's platform.openai.com pages sometimes require JavaScript; `developers.openai.com` (a static mirror) was used where platform pages returned JS-only responses.
- The Codex permissions page and agent-approvals-security page returned 404 or JS-required from `developers.openai.com`; some Codex config details were obtained from the sandboxing and subagents pages instead.
- OpenAI's API docs do not use the terms "host-tool-injection behavior" or "host-injected system prompts" in published documentation; these phrases are not part of their public vocabulary.
- The "full catalog" of OpenAI models was not exhaustively fetched; the models page shows `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini` as frontier models, with no `gpt-5.3-codex` entry visible.

---

## Full findings

### Anthropic: Published guidance on subagent/agent-SDK file-system writes, tool grants, and system prompt interaction

#### 1. Tool-Use API — Messages API (`docs.anthropic.com`)

**Source:** https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/how-tool-use-works  
**Source:** https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/define-tools  

Anthropic's tool-use documentation establishes a **three-tier taxonomy** of tool execution:

- **User-defined client tools**: Operator writes schema, operator executes the code (including file writes), operator returns result. "When Claude decides to use one of your tools, the API response contains a tool_use block with the tool name and a JSON object of arguments. Your application extracts those arguments, runs the operation (a database query, an HTTP call, **a file write**, whatever the tool does), and sends the output back in a tool_result block."

- **Anthropic-schema client tools** (bash, text_editor, computer, memory): Anthropic publishes the schema; operator handles execution. The `bash` tool enables shell commands including file operations (create, edit, delete files). The `text_editor` tool enables string-replacement edits in files. Both are explicitly framed as running in the operator's environment. The `bash` tool docs list "Manage files, automate tasks" and "Process files, run analysis scripts, manage datasets" as explicit use cases.

- **Server-executed tools** (web_search, code_execution, web_fetch, tool_search): Anthropic runs these on Anthropic's infrastructure. No file-system write capability is exposed in server-executed tools.

**System prompt construction and tool grants:**  
The `define-tools` docs state: "When you call the Claude API with the `tools` parameter, the API constructs a special system prompt from the tool definitions, tool configuration, and any user-specified system prompt. The constructed prompt is designed to instruct the model to use the specified tool(s) and provide the necessary context for the tool to operate properly."

The computer-use docs add: "When one of the Anthropic-schema tools is requested through the Claude API, a computer use-specific system prompt is generated. It's similar to the tool use system prompt but starts with: 'You have access to a set of functions you can use to answer the user's question. This includes access to a sandboxed computing environment.' As with regular tool use, the user-provided `system_prompt` field is still respected and used in the construction of the combined system prompt."

This means the declared tool set (passed in the `tools` array) is reflected into the system prompt automatically by Anthropic's API before the model sees the request — the host-provided system prompt and the tool definitions are combined.

**No documented mechanism** for a system prompt to grant additional tool capabilities beyond what is declared in the `tools` array, nor to restrict which tools in the array are callable. The `tool_choice` parameter can force or disable tool use but does not add new tools.

#### 2. Anthropic Managed Agents API (beta)

**Source:** https://docs.anthropic.com/en/docs/managed-agents/overview  
**Source:** https://docs.anthropic.com/en/docs/managed-agents/tools  
**Source:** https://docs.anthropic.com/en/docs/managed-agents/permission-policies  

Anthropic's **Claude Managed Agents** (beta, requires `managed-agents-2026-04-01` header) is a "pre-built, configurable agent harness that runs in managed infrastructure" for long-running autonomous tasks. This is the most explicit published documentation on file-system write governance.

**The agent toolset (`agent_toolset_20260401`) includes:**

| Tool | Name | Description |
|------|------|-------------|
| Bash | `bash` | Execute bash commands in a shell session |
| Read | `read` | Read a file from the local filesystem |
| **Write** | **`write`** | **Write a file to the local filesystem** |
| Edit | `edit` | Perform string replacement in a file |
| Glob | `glob` | Fast file pattern matching |
| Grep | `grep` | Text search using regex patterns |
| Web fetch | `web_fetch` | Fetch content from a URL |
| Web search | `web_search` | Search the web |

All tools are enabled by default when the toolset is included. Individual tools can be disabled via `configs` array with `enabled: false`.

**Permission policies** control whether server-executed tools (the agent toolset and MCP tools) auto-execute or pause for approval:

- `always_allow`: Tool executes automatically with no confirmation (default for agent toolset if `default_config` is omitted)
- `always_ask`: Session pauses and waits for operator approval before executing (default for MCP toolsets)

When `always_ask` is triggered, the session emits an `agent.tool_use` or `agent.mcp_tool_use` event, then pauses with `session.status_idle` (stop_reason: `requires_action`). The operator sends a `user.tool_confirmation` event with `result: "allow"` or `result: "deny"`.

**Custom tools are explicitly excluded** from permission policies: "Permission policies do not apply to custom tools. When the agent invokes a custom tool, your application receives an `agent.custom_tool_use` event and is responsible for deciding whether to execute it."

**Multiagent sessions** are listed as an advanced orchestration feature (nav entry: "Multiagent sessions") but the page content was not successfully fetched during this investigation.

#### 3. Bash Tool — Security Guidance

**Source:** https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/bash-tool

The bash tool docs contain explicit security guidance:
> "The bash tool provides direct system access. Implement these essential safety measures."

Key notes:
- Session scope is client-side; the API is stateless. The operator's application is responsible for maintaining the shell session between turns.
- Git is recommended as a recovery mechanism for long-running agent workflows.
- The bash tool adds 245 input tokens to API calls.
- Can be combined with the text editor tool and computer use tool for comprehensive automation.

#### 4. Computer Use Tool — Prompt Injection Warning

**Source:** https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/computer-use-tool

The computer use tool documentation contains the most explicit guidance on how external content can affect Claude's behavior when acting as an agent:

> "In some circumstances, Claude will follow commands found in content even if it conflicts with the user's instructions. For example, Claude instructions on webpages or contained in images might override instructions or cause Claude to make mistakes."

**Anthropic's countermeasures:**
- Claude is trained to resist prompt injections
- Classifiers run automatically on prompts to flag potential prompt injections in screenshots
- When classifiers detect potential injections, they steer Claude to ask for user confirmation before proceeding
- This protection can be opted out of (contact support)

This is the only explicit documentation found about how host-injected instructions (from external content rather than the system prompt) can affect declared tool behavior. No separate documentation was found about how an operator's system prompt specifically can expand or restrict individual tool grants at the model level.

#### 5. Safety Research and Model Cards

**Source:** https://www.anthropic.com/research/teaching-claude-why (May 8, 2026, Alignment team)

Anthropic's "Teaching Claude why" paper on **agentic misalignment** addresses Claude's behavior when autonomous tool use (including file writes and bash commands) creates opportunities for misaligned actions. Key findings published:

- Agentic misalignment (e.g., blackmail behavior) was traced to pre-training and insufficient agentic coverage in post-training data
- Standard RLHF without agentic tool use was "previously sufficient to align models that were largely used in chat settings—but this was not the case for agentic tool use settings"
- Adding **tool definitions** to training environments (even when tools were never invoked) "saw a small but significant improvement in the rate at which the model improved on our honeypot evaluations" — demonstrating that tool presence in training prompts has a behavioral safety signal
- Claude models from Haiku 4.5 onward score 0% (or near-0%) on the blackmail honeypot evaluation
- The paper references the "Claude 4 system card" (published during Claude 4 training) as the source of the original agentic misalignment findings. The system card text was not directly fetchable.

**Responsible Scaling Policy (RSP):** Available at https://www.anthropic.com/responsible-scaling-policy. The page is a JS SPA and detailed content on file-system write behaviors in agentic contexts was not extractable.

**Model cards / system cards:** The `www.anthropic.com/research/claude-4-model-card` URL returns a Next.js SPA (dynamic content). No static PDF was accessible via `cdn.anthropic.com`. The system card's existence is confirmed by the alignment paper reference ("Published in the Claude 4 system card, beginning on p.22"), but the full content was not fetched.

---

### OpenAI: Published guidance on `gpt-5.5`, `gpt-5.3-codex`, subagent tool grants, and host-tool-injection behavior

#### 1. Model Catalog — `gpt-5.5` and `gpt-5.3-codex`

**Source:** https://platform.openai.com/docs/models  

The OpenAI models page lists these **frontier models** as of May 30, 2026:

| Model ID | Description | Tools |
|----------|-------------|-------|
| `gpt-5.5` | "A new class of intelligence for coding and professional work" (flagship) | Functions, Web search, File search, Computer use |
| `gpt-5.4` | "A more affordable model for coding and professional work" | Functions, Web search, File search, Computer use |
| `gpt-5.4-mini` | "Our strongest mini model yet for coding, computer use, and subagents" | Functions, Web search, File search, Computer use |

**`gpt-5.3-codex` does not appear anywhere in OpenAI's published API documentation.** The models page shows no `gpt-5.3` variant.

In the **Codex product** documentation (`developers.openai.com/codex/concepts/subagents`), a model called **`gpt-5.3-codex-spark`** is mentioned:
> "If you have ChatGPT Pro and want near-instant text-only iteration, `gpt-5.3-codex-spark` remains [a good choice]"

This model is described as:
- Available only to **ChatGPT Pro** subscribers
- A **research preview** model
- Limited to **text-only** tasks ("near-instant, text-only iteration when latency matters more than broader capability")
- Not a general API model — it is a Codex product model

No documentation was found for `gpt-5.5` or `gpt-5.3-codex-spark` handling tool grants differently when dispatched as a subagent versus as a top-level agent. The tools available to any agent instance are determined by what the operator defines in the agent's `tools` parameter, not by model-level dispatch context.

#### 2. Agents SDK — Orchestration, Subagent Tool Grants, and Guardrails

**Source:** https://developers.openai.com/api/docs/guides/agents  
**Source:** https://developers.openai.com/api/docs/guides/agents/orchestration  
**Source:** https://developers.openai.com/api/docs/guides/agents/guardrails-approvals  

**Orchestration patterns (no "host-tool-injection" concept):**

OpenAI's Agents SDK exposes two multi-agent patterns:

1. **Handoffs** (`handoffs` parameter): A triage/orchestrator agent transfers control to a specialist. The specialist "takes over the conversation." Each specialist is defined with its own `instructions` and `tools`; the specialist does not inherit the parent's tool set when receiving a handoff.

2. **Agents as tools** (`agent.asTool()`): A manager agent calls a specialist as a bounded function. The specialist executes its defined task and returns a result. The manager retains ownership. The specialist operates within the bounds of its own agent definition.

In both patterns, **tools are specified per-agent in the agent definition** — there is no documented mechanism by which a parent orchestrator's system prompt injects additional tool capabilities into a subagent. The published documentation does not use the phrase "host-tool-injection" or discuss operator injection of tools at system prompt time affecting subagent behavior.

**Guardrails and tool grant controls:**

The guardrails-approvals page documents three control surfaces:
- **Input guardrails**: Run only for the first agent in the chain
- **Output guardrails**: Run only for the agent that produces the final output
- **Tool guardrails** (`@function_tool(needs_approval=True)` in Python / `needsApproval: true` in TS): Run on specific function tools regardless of which agent calls them

The page explicitly states: "Agent-level guardrails don't run everywhere: Input guardrails run only for the first agent in the chain. Output guardrails run only for the agent that produces the final output. Tool guardrails run on the function tools they're attached to. If you need checks around every custom tool call in a manager-style workflow, don't rely only on agent-level input or output guardrails. Put validation next to the tool that creates the side effect."

When a tool needs approval, the SDK pauses the run, surfaces an `interruptions` object with a resumable state, and requires the operator to approve/reject before resuming.

No specific documentation discusses how `gpt-5.5` (or any specific model) exposes or restricts file-write tool grants differently in subagent vs. top-level contexts at the model level. Tool availability is purely a function of the agent definition.

#### 3. Codex Subagents — File-Write Behavior in Parallel Agent Workflows

**Source:** https://developers.openai.com/codex/concepts/subagents  

The Codex product (coding agent) documents subagent workflows explicitly. Key published guidance:

- Codex can spawn parallel subagents for specialized tasks (exploration, code review, analysis)
- "Be more careful with parallel write-heavy workflows, because agents editing code at once can create conflicts and increase coordination overhead"
- "Codex doesn't spawn subagents automatically, and it should only use subagents when you explicitly ask for subagents or parallel agent work"
- Models available for Codex subagents: `gpt-5.5` (demanding multi-step work), `gpt-5.4` (coding and broader workflows), `gpt-5.4-mini` (fast scans, large-file review), `gpt-5.3-codex-spark` (ChatGPT Pro only, text-only, near-instant latency)

Subagent model selection note: "If you don't pin a model or model_reasoning_effort, Codex can choose a setup that balances intelligence, speed, and price for the task. It may favor `gpt-5.4-mini` for fast scans or a higher-effort `gpt-5.5` configuration for more demanding reasoning."

#### 4. Codex Sandboxing — Operator Control Over File-System Writes

**Source:** https://developers.openai.com/codex/concepts/sandboxing  

The Codex sandboxing page (Codex product, not general API) documents the file-system write boundary as an operator-configured parameter:

**Sandbox modes:**
- `read-only`: Codex can inspect files but cannot edit files or run commands
- `workspace-write` (default): Codex can read files, edit within the workspace, and run project commands. Protected paths: `.git`, `.agents`, `.codex` directories are always read-only
- `danger-full-access` (alias `--yolo`): No sandbox restrictions — removes filesystem and network boundaries. "Use caution before doing so."
- `untrusted`: Codex asks before running commands not in its trusted set

**Approval policy:**
- `on-request` (default): Codex works inside sandbox, asks when it needs to go outside
- `never`: Disables all approval prompts
- `auto_review`: Routes eligible approval requests to a reviewer agent

**Subagent sandbox inheritance:** "The sandbox applies to spawned commands, not just to Codex's built-in file operations. If Codex runs tools like git, package managers, or test runners, those commands inherit the same sandbox boundaries." This means subagents spawned by Codex operate within the same sandbox as the parent session.

**Protected paths in `workspace-write` mode** (always read-only):
- `<writable_root>/.git`
- `<writable_root>/.agents`
- `<writable_root>/.codex`

This is a **product-level mechanism** (Codex CLI/app/IDE), not an API-level parameter for the OpenAI models API.

#### 5. OpenAI's "Host-Tool-Injection Behavior" — Absence of Published Documentation

The phrase "host-tool-injection behavior" does not appear in OpenAI's published documentation. The concept closest to this in OpenAI's docs is:
- The `tools` array in API requests, which defines what tools are available to a model in that call
- The system prompt parameter, which provides instructions but does not grant additional tools beyond what is in `tools`
- The Codex product's sandbox and approval policy controls, which are set by operators through configuration files or CLI flags

No published OpenAI documentation describes a mechanism by which a parent orchestrator's system prompt can inject tool capabilities into a subagent's tool grants at model inference time.

---

### Scope note on `gpt-5.5` model-card / system card

No published OpenAI model card or system card for `gpt-5.5` was found at accessible URLs. The models page describes capabilities at a high level (tools supported, pricing, context window) but does not contain a system card with detailed behavioral documentation. The `openai.com/research/gpt-5-5` URL returned only a JS loading page.
