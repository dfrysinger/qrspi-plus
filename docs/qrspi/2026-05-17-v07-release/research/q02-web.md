---
status: draft
question_ids: [2]
research_type: web
---

# Q2: How do open-source plugin and agent frameworks express per-component model-routing policies in configuration, and what schema shapes are common in their published configs?

## Summary

**TL;DR:** The named frameworks express per-component model routing mostly through per-agent/per-role model fields or injected model-client objects, not through one universal routing DSL. Claude Code plugins and OpenHands expose explicit per-agent `model`/`llm_config` style fields, AutoGen and LangGraph commonly bind a model client/model argument at agent construction time, and Aider uses flat role-specific config keys for main/editor/weak models. Common schema shapes are: frontmatter fields on component files, TOML named profiles referenced by agents, Python constructor injection, JSON/YAML `provider` + `config.model` component objects, and flat CLI/YAML role keys.

**Key findings:**
- Claude Code plugin agents support a `model` frontmatter field; plugin `settings.json` can also select one plugin agent as the main thread, applying that agent's prompt, tools, and model.
- OpenHands has both TOML named LLM configs (`[llm.<name>]`) referenced by agent sections through `llm_config`, and SDK-level `LLM(usage_id=...)` / `LLMRegistry` / router-object patterns.
- AutoGen stable AgentChat routes models by passing `model_client` per `AssistantAgent`; AutoGen's component config shape serializes clients as `{provider, config: {model: ...}}`.
- LangGraph's prebuilt `create_react_agent` accepts `model` as a string, language-model object, or callable that can return a model per state/runtime; multi-agent routing is usually achieved by constructing different agents/nodes with different model arguments.
- Aider does not expose per-agent routing; it exposes flat per-role options such as `model`, `weak-model`, and `editor-model` in CLI/env/YAML config.

**Surprises:** Claude Code plugin hooks include `prompt` and `agent` hook types, but the plugin hook schema researched here did not show a per-hook model field; model selection is documented on plugin agents rather than hooks.

**Caveats:** This was a web/documentation-source investigation, not an exhaustive source-code audit. Some LangGraph documentation pages redirected or failed through WebFetch, so the LangGraph finding relies on the public GitHub source signature for `create_react_agent` plus framework documentation behavior surfaced by available pages. OpenDevin is now OpenHands; findings cite current OpenHands docs/source rather than legacy OpenDevin docs.

## Full findings

### Query planning

Planned source targets before search/fetch:
- Claude Code plugin docs and plugin reference for plugin manifest, agent frontmatter, hooks, and settings schema.
- OpenHands/OpenDevin docs for LLM config, custom LLM configs, SDK LLM registry, routing, and agent settings.
- AutoGen stable docs for AgentChat agents, model clients, and component config; AutoGen 0.2 docs for the older `config_list` pattern still visible in published configs.
- LangGraph docs/source for `create_react_agent`, multi-agent construction, and model argument schema.
- Aider config docs and sample config for role-specific model keys.

### Claude Code plugins

Source URLs:
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/plugins-reference

Claude Code plugins express model selection on plugin-shipped agent definitions, not in the top-level plugin manifest as a centralized router table. The plugin reference documents agent markdown frontmatter with this example shape:

```markdown
---
name: agent-name
description: What this agent specializes in and when Claude should invoke it
model: sonnet
effort: medium
maxTurns: 20
disallowedTools: Write, Edit
---
```

The same page states that plugin agents support `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, and `isolation` frontmatter fields. In schema-shape terms, Claude Code uses **component-local Markdown frontmatter** for per-agent model routing.

The plugin manifest schema (`.claude-plugin/plugin.json`) uses path/object fields to locate components, for example `skills`, `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`, and `experimental.monitors`. The manifest's `agents` field points to agent files, while the model itself lives inside each agent file's frontmatter.

Claude Code plugin `settings.json` can select a plugin agent as the main thread. The docs state that currently only `agent` and `subagentStatusLine` keys are supported, and that setting `agent` activates one of the plugin's custom agents as the main thread, applying that agent's system prompt, tool restrictions, and model. Example:

```json
{
  "agent": "security-reviewer"
}
```

Plugin skills have frontmatter such as `description` and `disable-model-invocation` in the quickstart example, but the fetched plugin docs did not show a skill-level `model` field. Plugin hooks are configured as JSON event matchers/actions under `hooks`, with hook types `command`, `http`, `mcp_tool`, `prompt`, and `agent`; the researched hook schema did not show a per-hook model field.

### OpenHands / OpenDevin

Source URLs:
- https://docs.openhands.dev/llms.txt
- https://docs.openhands.dev/openhands/usage/llms/custom-llm-configs.md
- https://docs.openhands.dev/sdk/guides/llm-registry.md
- https://docs.openhands.dev/sdk/guides/llm-routing.md
- https://docs.openhands.dev/sdk/guides/agent-settings.md
- https://github.com/All-Hands-AI/OpenHands/blob/main/config.template.toml
- https://github.com/All-Hands-AI/OpenHands/blob/main/openhands/app_server/settings/llm_profiles.py

OpenHands has multiple model-routing/configuration shapes.

The Web/App `config.toml` pattern supports a default `[llm]` table and named LLM tables under `[llm.<name>]`. The custom LLM docs show this shape:

```toml
[llm]
model = "gpt-4"
api_key = "your-api-key"
temperature = 0.0

[llm.gpt3]
model = "gpt-3.5-turbo"
temperature = 0.2

[llm.high-creativity]
model = "gpt-4"
temperature = 0.8
top_p = 0.9
```

Those named LLM configs can be referenced by agents through `llm_config` fields:

```toml
[agent.RepoExplorerAgent]
llm_config = "gpt3"

[agent.CodeWriterAgent]
llm_config = "high-creativity"
```

The same docs identify a reserved/special-purpose named profile, `[llm.draft_editor]`, for preliminary code-edit drafting:

```toml
[llm.draft_editor]
model = "gpt-4"
temperature = 0.2
top_p = 0.95
presence_penalty = 0.0
frequency_penalty = 0.0
```

The current `config.template.toml` source also shows agent sections (`[agent]`, `[agent.CustomAgent]`) and condenser configuration. It documents that condensers can reference a named LLM config with `llm_config = "condenser"`, and includes an example named LLM profile:

```toml
[condenser]
type = "llm"
llm_config = "condenser"

[llm.condenser]
model = "gpt-4o"
temperature = 0.1
max_input_tokens = 1024
```

At SDK level, OpenHands also supports named LLM objects using `usage_id` and an `LLMRegistry`:

```python
main_llm = LLM(
    usage_id="agent",
    model=model,
    base_url=base_url,
    api_key=SecretStr(api_key),
)

llm_registry = LLMRegistry()
llm_registry.add(main_llm)
llm = llm_registry.get("agent")
```

The registry API shown in docs includes `add`, `get`, and `list_usage_ids`. This is a **named profile registry** shape, with `usage_id` as the logical routing key.

OpenHands SDK routing can also be object-based: the routing guide shows passing a router object as an agent's LLM. The documented `MultimodalRouter` example has this shape:

```python
multimodal_router = MultimodalRouter(
    usage_id="multimodal-router",
    llms_for_routing={"primary": primary_llm, "secondary": secondary_llm},
)
agent = Agent(llm=multimodal_router, tools=tools)
```

The SDK `OpenHandsAgentSettings` guide shows agent configuration as serializable Pydantic data containing an `llm` object, tools, and optional condenser settings:

```python
OpenHandsAgentSettings(
    llm=LLM(
        model="anthropic/claude-sonnet-4-5-20250929",
        api_key=SecretStr("your-api-key"),
        base_url=os.getenv("LLM_BASE_URL"),
    ),
    tools=[Tool(name=TerminalTool.name), Tool(name=FileEditorTool.name)],
    condenser=CondenserSettings(enabled=True, max_size=50),
)
```

The OpenHands source file `openhands/app_server/settings/llm_profiles.py` defines an `LLMProfiles` container with `profiles: dict[str, LLM]` and an `active` profile name, matching the named-profile schema shape.

### AutoGen

Source URLs:
- https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/agents.html
- https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/components/model-clients.html
- https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/framework/component-config.html
- https://microsoft.github.io/autogen/0.2/docs/topics/llm_configuration/

AutoGen stable AgentChat expresses per-agent model selection by injecting a `model_client` into each agent instance. The AgentChat docs show:

```python
model_client = OpenAIChatCompletionClient(
    model="gpt-4.1-nano",
)

agent = AssistantAgent(
    name="assistant",
    model_client=model_client,
    system_message="Use tools to solve tasks.",
)
```

Because `model_client` is an argument to each `AssistantAgent`, different agents can receive different clients. The schema shape is **constructor injection**: `AssistantAgent(name=..., model_client=<client>, tools=..., system_message=...)`.

AutoGen's core model-client docs show the same per-agent injection pattern for lower-level agents registered with a runtime: construct a `ChatCompletionClient`, then pass it into the agent factory (`lambda: SimpleAgent(model_client=model_client)`). Model clients implement a common `ChatCompletionClient` protocol.

AutoGen stable also has declarative component configuration. The component-config docs show a model-client config object shaped like:

```json
{
  "provider": "openai_chat_completion_client",
  "config": {
    "model": "gpt-4o"
  }
}
```

That object can be loaded through `ChatCompletionClient.load_component(config)`. The page also describes component classes exposing `component_type` and `component_config_schema`, but the visible schema for a model client is `provider` plus nested `config.model`.

AutoGen 0.2 published docs show an older but common external config shape: `llm_config` with a `config_list`, passed to an agent constructor:

```python
llm_config = {
    "config_list": [{"model": "gpt-4", "api_key": os.environ["OPENAI_API_KEY"]}],
}
assistant = autogen.AssistantAgent(name="assistant", llm_config=llm_config)
```

The `config_list` can contain multiple endpoint/model dictionaries for fallback. Docs state agents use the first available model and fall back on failure; they do not implicitly pick the best model for the task.

AutoGen 0.2 also supports filtering a shared config list per agent with `filter_dict`, including by `model` or `tags`:

```python
filter_dict = {"model": ["gpt-3.5-turbo"]}
config_list = autogen.filter_config(config_list, filter_dict)
```

Tag-based filtering examples use config entries like:

```python
{"model": "llama-7B", "base_url": "http://127.0.0.1:8080", "tags": ["llama", "local"]}
```

This creates a common shape of **shared endpoint list + per-agent filtered subset**.

### LangGraph

Source URLs:
- https://github.com/langchain-ai/langgraph/blob/main/libs/prebuilt/langgraph/prebuilt/chat_agent_executor.py
- https://langchain-ai.github.io/langgraph/concepts/multi_agent/ (redirected/fetch content was not usable during this investigation)

LangGraph expresses model selection primarily in code at agent/node construction time. The public `create_react_agent` source signature in `libs/prebuilt/langgraph/prebuilt/chat_agent_executor.py` accepts a `model` parameter with this type shape:

```python
def create_react_agent(
    model: str
    | LanguageModelLike
    | Callable[[StateSchema, Runtime[ContextT]], BaseChatModel]
    | Callable[[StateSchema, Runtime[ContextT]], Awaitable[BaseChatModel]]
    | Callable[[StateSchema, Runtime[ContextT]], Runnable[LanguageModelInput, BaseMessage]]
    | Callable[[StateSchema, Runtime[ContextT]], Awaitable[Runnable[LanguageModelInput, BaseMessage]]],
    tools: Sequence[BaseTool | Callable | dict[str, Any]] | ToolNode,
    *,
    ...
) -> CompiledStateGraph:
```

This is more flexible than a static config map: a LangGraph agent can be constructed with a model string, a chat model object, or a callable that selects/returns a model from graph state and runtime context. Per-component routing in LangGraph therefore commonly appears as **different graph nodes or agents instantiated with different model arguments**, or as a callable model selector for dynamic routing.

No fetched LangGraph page in this investigation showed a centralized YAML/JSON schema mapping node names to model names. The available source signature supports code-first model binding rather than a published config-file router schema.

### Aider

Source URLs:
- https://aider.chat/docs/config/options.html
- https://aider.chat/docs/config/aider_conf.html
- https://github.com/Aider-AI/aider/blob/main/aider/website/assets/sample.aider.conf.yml

Aider expresses model routing through flat role-specific options that can be provided as CLI flags, environment variables, or `.aider.conf.yml` keys. The options docs identify these model-related routing keys:

- `--model MODEL`: primary model for the main chat.
- `--weak-model WEAK_MODEL`: model used for commit messages and chat-history summarization.
- `--editor-model EDITOR_MODEL`: model used for editor tasks.
- `--architect`: enables architect mode, where the main model plans and the editor model applies changes.
- `--edit-format` / `--chat-mode`: edit format for the main LLM.
- `--editor-edit-format`: edit format for the editor model.
- `--alias ALIAS:MODEL`: alias definitions usable in role model fields.
- `--reasoning-effort` and `--thinking-tokens`: model behavior/tuning options.

The YAML config docs state that most Aider options can be set in `.aider.conf.yml`, loaded from home, repo root, and current directory with later files taking priority. The schema shape is a **flat YAML/CLI option namespace**, e.g. conceptually:

```yaml
model: gpt-4o
weak-model: gpt-4o-mini
editor-model: gpt-4.1
architect: true
editor-edit-format: editor-diff
```

Aider does not present an agent graph or per-component manifest in the docs researched here; instead, it has built-in roles and assigns models to those roles through flat config keys.

## Common schema shapes across frameworks

1. **Component-local frontmatter:** Claude Code plugin agents use Markdown frontmatter fields such as `model`, `effort`, `maxTurns`, and tool allow/deny lists.

2. **Named profile tables plus references:** OpenHands TOML uses `[llm]` and `[llm.<name>]` sections, then binds agents/components through fields such as `llm_config = "name"`. Condensers use the same reference pattern.

3. **Object registry keyed by logical usage:** OpenHands SDK uses `LLM(usage_id=...)` plus `LLMRegistry.get("usage_id")`.

4. **Router object as model:** OpenHands SDK can pass `MultimodalRouter(usage_id=..., llms_for_routing={...})` as `Agent(llm=...)`, making routing behavior an object implementing the LLM interface.

5. **Constructor injection:** AutoGen stable and LangGraph commonly bind models by passing a model client/model argument into each agent or node constructor.

6. **Declarative component object:** AutoGen stable component config uses `{ "provider": "...", "config": { "model": "..." } }` for serializable model-client construction.

7. **Shared endpoint list plus filter:** AutoGen 0.2 uses `llm_config.config_list` with per-agent filtering by `model` or `tags`.

8. **Flat role keys:** Aider uses flat CLI/YAML/env keys for built-in roles (`model`, `weak-model`, `editor-model`) rather than arbitrary component names.

Across the named frameworks, the most common primitives are a model string (`model`), a named profile/key (`llm_config`, `usage_id`, profile name), and a nested provider/client config (`provider` + `config.model` or `config_list[]`). Centralized policy maps are less common than per-component binding plus fallback/filter/registry mechanisms.