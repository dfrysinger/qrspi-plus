---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L25-L38]
artifact: research
round: 1
reviewer: quality-claude
---

The Q2 section is a `[web]` research question (it asks how open-source plugin and agent frameworks express per-component model-routing policies), but none of its five Key findings bullets carry a URL or source-attribution citation. Each bullet makes a specific factual assertion about an external system — "Claude Code plugin agents support a `model` frontmatter field; plugin `settings.json` can also select one plugin agent as the main thread, applying that agent's prompt, tools, and model", "OpenHands has both TOML named LLM configs (`[llm.<name>]`) referenced by agent sections through `llm_config`, and SDK-level `LLM(usage_id=...)` / `LLMRegistry` / router-object patterns", "AutoGen stable AgentChat routes models by passing `model_client` per `AssistantAgent`; AutoGen's component config shape serializes clients as `{provider, config: {model: ...}}`", "LangGraph's prebuilt `create_react_agent` accepts `model` as a string, language-model object, or callable that can return a model per state/runtime", "Aider does not expose per-agent routing; it exposes flat per-role options such as `model`, `weak-model`, and `editor-model`" — and none of those claims cite the documentation page or source file that supports it.

The Caveats note "Some LangGraph documentation pages redirected or failed through WebFetch" and mentions WebFetch generally, but a generic Caveats reference is not equivalent to per-claim URL attribution. The reviewer-protocol research check requires `[web]` research to include URLs and source attribution for every factual claim; uncited web assertions are a finding. The same defect blocks downstream consumers from auditing the specific schema/API claims against current documentation.
