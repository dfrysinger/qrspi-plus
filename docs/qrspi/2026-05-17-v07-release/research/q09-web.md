---
status: draft
question_ids: [9,28]
research_type: web
---

# Q9, Q28: Large stable inputs and freshness contracts for derived prompt inputs

## Summary

**TL;DR:** Agent frameworks and model APIs commonly handle large recurring inputs with prompt/context caching, persisted thread or memory objects, retrieval-backed memory stores, and chat-history reducers that trim or summarize older context. Published contracts are strongest for provider-level prompt/context caches: vendors specify token thresholds, exact-prefix matching, TTLs or retention windows, isolation boundaries, and usage counters. Published freshness and accuracy contracts for derived or condensed prompt inputs are weaker: frameworks generally describe when summaries, extracted facts, or reduced histories are produced, but do not guarantee lossless or accurate condensation.

**Key findings:**
- Anthropic prompt caching uses explicit or automatic cache breakpoints over the ordered prefix hierarchy `tools -> system -> messages`, with 5-minute and 1-hour ephemeral TTLs, minimum cacheable-prefix token thresholds, organization/workspace isolation, and usage counters for cache reads and writes.
- Azure OpenAI prompt caching is enabled by default for supported models, works on identical initial prompt prefixes of at least 1,024 tokens, reports `cached_tokens`, and has in-memory retention usually cleared after 5-10 minutes of inactivity and always within one hour of last use; newer/eligible models can use extended retention up to 24 hours.
- Vertex AI context caching supports explicit reusable cached content for Gemini prompts, with a default 60-minute TTL, update support limited to expiration/TTL, minimum token thresholds, `cachedContentTokenCount` usage metadata, and a warning not to mutate Cloud Storage source objects before cache expiry or deletion.
- LangChain/LangGraph-style and Semantic Kernel-style frameworks manage recurring context by persisting conversation state, trimming messages, summarizing older turns, or using memory stores; the available documentation found no explicit accuracy guarantees for summaries.
- CrewAI publishes a more operational memory contract than most frameworks: memory recall ranks by semantic similarity, recency decay, and importance; `recall()` waits for pending background writes before searching; and failures fall back to simpler storage or retrieval paths.

**Surprises:** Provider cache documentation is relatively explicit about TTLs and matching, but most framework documentation for summaries and extracted memories does not publish quantitative accuracy/fidelity contracts for the condensed content.

**Caveats:** WebFetch could not access some sources due to redirects, 403s, 404s, 504s, or transient tool availability. OpenAI platform docs returned HTTP 403, so Azure OpenAI and OpenAI's public prompt-caching announcement were used for OpenAI-family caching behavior. LangGraph and Letta source coverage was limited by inaccessible pages.

## Full findings

### Q9: What mechanisms or patterns do agent frameworks use to manage large, stable inputs that recur across dispatches?

#### Query planning

Planned searches targeted four mechanism families:
1. Provider-side prompt/context caches for stable prompt prefixes and reusable documents.
2. Agent-framework memory or thread abstractions that persist state across invocations.
3. History reducers that trim, summarize, or token-budget chat history.
4. Retrieval-backed memory systems that store extracted facts or documents outside the prompt and inject only relevant results.

#### Provider-side prompt and context caching

Anthropic publishes prompt caching as a mechanism to cache frequently used context between API calls, including long system prompts, uploaded or embedded documents, codebase summaries, many-shot examples, multi-turn conversations, and repeated tool-use rounds. Source: Anthropic blog, `https://claude.com/blog/prompt-caching`.

Anthropic's current prompt-caching docs describe two ways to enable caching: automatic caching through a top-level `cache_control` field, and explicit cache breakpoints placed on content blocks. Prefixes are constructed in the fixed hierarchy `tools -> system -> messages`, and explicit breakpoints can be used when sections change at different rates. Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Anthropic describes several recurring-input patterns:
- Place a cache breakpoint on the last block that stays identical across requests, leaving variable suffixes such as timestamps or the latest user message after the cached prefix.
- Use automatic caching for growing conversations where the active breakpoint moves forward turn by turn.
- Use multiple breakpoints when tools, system instructions, documents, and conversation turns change at different frequencies.
- Pre-warm a cache with `max_tokens: 0` for latency-sensitive first requests, placing the breakpoint on the shared prefix rather than on a placeholder user message.
Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Azure OpenAI prompt caching is another provider-side prefix-cache mechanism. Microsoft describes it as retaining temporary processed input-token computations for longer prompts with identical content at the beginning. It is enabled by default for supported models and cannot be disabled. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Azure OpenAI's cacheable content includes complete messages arrays, images in user messages where detail settings match, tool definitions, tool-use messages, and structured-output schemas appended as a system-message prefix. Microsoft recommends structuring requests so repetitive content appears at the beginning of the messages array. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Vertex AI context caching supports reusable cached content for Gemini requests. The page describes operations to create, use, delete, retrieve information about, and update expiration time for caches. Explicit caches default to 60 minutes. Source: Google Cloud docs, `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview`.

Vertex AI supports both implicit and explicit caching with model-specific minimum token requirements. The fetched documentation reported minimums of 4,096 tokens for Gemini 3/3.1 and 2,048 tokens for Gemini 2.0/2.5, and a maximum cacheable blob/text size of 10 MB. Source: Google Cloud docs, `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview`.

#### Persisted thread and conversation-state objects

Semantic Kernel's agent architecture defines `AgentThread` as the abstraction for threads or conversation state. The docs distinguish stateful services that store conversation state service-side and local agents that require the entire chat history to be passed on each invocation. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-architecture`.

Semantic Kernel's `ChatHistory` object is a list-like record of messages from users, assistants, tools, and the system. It is described as the primary mechanism for maintaining context and continuity in a conversation. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/semantic-kernel/concepts/ai-services/chat-completion/chat-history`.

LangChain's overview states that LangChain agents are built on LangGraph, which provides durable execution and persistence. The same page points to Deep Agents for built-in handling of long context via automatic context compression, a virtual filesystem, and subagent spawning. Source: LangChain docs, `https://docs.langchain.com/oss/python/langchain/overview`.

LlamaIndex's deprecated `ChatSummaryMemoryBuffer` example stores recent messages within a configured token limit and maintains a summarized message for earlier conversation history. It can be passed as memory when calling an agent's `.run()` method, allowing chat state to persist across runs. Source: LlamaIndex docs, `https://developers.llamaindex.ai/python/examples/agent/memory/summary_memory_buffer/`.

#### Chat-history reduction: trimming, token budgeting, summarization

Semantic Kernel documents three chat-history reduction strategies:
- Truncation, where oldest messages are removed once history exceeds a predefined limit.
- Summarization, where older messages are condensed into a summary.
- Token-based reduction, where total token count drives removal or summarization.
Source: Microsoft Learn, `https://learn.microsoft.com/en-us/semantic-kernel/concepts/ai-services/chat-completion/chat-history`.

Semantic Kernel's .NET reducers include `ChatHistoryTruncationReducer` and `ChatHistorySummarizationReducer`. The truncation reducer discards removed messages. The summarization reducer truncates history, summarizes removed messages, and adds the summary back as one message. Both preserve system messages. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/semantic-kernel/concepts/ai-services/chat-completion/chat-history`.

Microsoft's Semantic Kernel blog adds reducer invariants: preserve the system message because it guides behavior, and preserve valid function-calling request/response sequences because breaking pairs can create invalid message order. It describes message-count, token-count, and summary reducers. Source: Microsoft Developer Blogs, `https://devblogs.microsoft.com/semantic-kernel/managing-chat-history-for-large-language-models-llms/`.

LlamaIndex's `ChatSummaryMemoryBuffer` combines recent raw messages within `token_limit` with a single summary of earlier history. The example allows a custom `summarize_prompt`; the default prompt asks for a concise summary. Source: LlamaIndex docs, `https://developers.llamaindex.ai/python/examples/agent/memory/summary_memory_buffer/`.

#### Retrieval-backed memory and extracted-fact stores

CrewAI's memory system stores and retrieves reusable context across scripts, crews, agents, and flows through a unified `Memory` class. In crews, setting `memory=True` recalls relevant prior context before each task and extracts facts from task output after each task. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI persists memory by default under `./.crewai/memory`, `$CREWAI_STORAGE_DIR/memory`, or a custom path/backend. It supports hierarchical scopes such as project, agent, and customer branches; `MemoryScope` restricts access to subtrees; and `MemorySlice` combines branches. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI uses embeddings and retrieval for memory recall. Its docs describe vector search over text using configurable embedders, recall ranking that combines semantic similarity, freshness, and importance, deep recall that can analyze queries and explore further, and extraction of larger text into smaller factual records through `extract_memories(content)`. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI also performs consolidation and deduplication: similar existing records can be kept, updated, deleted, or supplemented by a new record, and `remember_many()` performs intra-batch near-duplicate removal. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

### Q28: What freshness and accuracy contracts are published for derived or condensed prompt inputs used in agent frameworks?

#### Query planning

Planned searches separated two contract types:
1. Freshness and cache-validity contracts for provider-derived artifacts such as processed prefix caches.
2. Accuracy or fidelity contracts for framework-derived artifacts such as summaries, extracted memories, reduced histories, and retrieval-selected context.

#### Provider cache freshness contracts

Anthropic publishes explicit prompt-cache TTL contracts. The default TTL is 5 minutes, refreshed for free on each hit. A 1-hour TTL can be specified with `"ttl": "1h"`. Anthropic also documents that 5-minute cache writes cost 1.25x base input, 1-hour writes cost 2x base input, and reads cost 0.1x base input. Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Anthropic publishes cache matching and invalidation rules. Cache reads walk backward up to 20 blocks from the breakpoint looking for prior writes. Cached prompt segments must be 100% identical up to the breakpoint. Changes cascade down the `tools -> system -> messages` hierarchy, so changes to tool definitions invalidate tools, system, and messages, while some lower-level changes invalidate only later hierarchy levels. Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Anthropic publishes cache isolation and availability boundaries. The fetched documentation states caches are organization-isolated and, as of February 5, 2026, also workspace-isolated on Claude API, AWS, and Microsoft Foundry, while Bedrock and Vertex AI remain org-only. Concurrent requests only see a cache entry after the first response begins, so the first hit must be serialized before parallel fan-out if callers require the cache to be populated. Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Anthropic publishes cache-observability fields: `cache_creation_input_tokens`, `cache_read_input_tokens`, and `input_tokens`, plus a `cache_creation` breakdown for mixed 5-minute and 1-hour TTLs. Source: Anthropic docs, `https://platform.claude.com/docs/en/docs/build-with-claude/prompt-caching`.

Azure OpenAI publishes prompt-cache retention contracts. In-memory cache retention is typically cleared within 5-10 minutes of inactivity and always removed within one hour of the cache's last use. Extended prompt-cache retention can keep cached prefixes active up to 24 hours for eligible models. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Azure OpenAI publishes matching contracts. A request must be at least 1,024 tokens, and the first 1,024 tokens must be identical. After the first 1,024 tokens, cache hits occur for every 128 additional identical tokens. A single-character difference in the first 1,024 tokens yields a cache miss with `cached_tokens` equal to 0. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Azure OpenAI publishes isolation and observability details. Prompt caches are not shared between Azure subscriptions. Cache hits are reported as `cached_tokens` under `prompt_tokens_details` in chat-completions usage. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Azure OpenAI explicitly states that prompt caching has no impact on output content beyond latency and cost reduction. This is an accuracy contract for the cache mechanism itself: the cached artifact is processed input-token computation, not a condensed or rewritten prompt. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/prompt-caching`.

Vertex AI publishes TTL and update contracts for explicit context caches. Explicit caches default to 60 minutes, the minimum lifetime after creation is 1 minute, the page stated no maximum cache duration, and updates are limited to expiration/TTL rather than changing cached content. Source: Google Cloud docs, `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview`.

Vertex AI publishes a source-stability warning for cached content backed by Cloud Storage: source objects should not be changed until cached contents expire or are deleted, and changing objects can make cached contents unusable. Source: Google Cloud docs, `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview`.

Vertex AI publishes observability through `cachedContentTokenCount`, which reports how many input tokens came from cached content. Source: Google Cloud docs, `https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview`.

#### Accuracy contracts for summaries and condensed histories

Semantic Kernel documents reduction behavior, but the fetched docs do not state quantitative accuracy guarantees for summaries. The `ChatHistorySummarizationReducer` summarizes removed messages and returns the summary as a single message, while preserving system messages. Source: Microsoft Learn, `https://learn.microsoft.com/en-us/semantic-kernel/concepts/ai-services/chat-completion/chat-history`.

The Semantic Kernel blog describes summaries as retaining context while reducing token usage and reports that the summary approach preserved expected context in one restaurant-ordering example. It does not publish a general accuracy guarantee for summary reducers. Source: Microsoft Developer Blogs, `https://devblogs.microsoft.com/semantic-kernel/managing-chat-history-for-large-language-models-llms/`.

LlamaIndex's `ChatSummaryMemoryBuffer` documentation states that older conversation history is summarized into a single message while recent messages remain raw within the token limit. The fetched page does not define a freshness interval or accuracy guarantee for the summary, and it notes that the example is deprecated in favor of the newer `Memory` class. Source: LlamaIndex docs, `https://developers.llamaindex.ai/python/examples/agent/memory/summary_memory_buffer/`.

LangChain's overview mentions automatic context compression in Deep Agents but the fetched overview did not state freshness or accuracy guarantees for compressed context. Source: LangChain docs, `https://docs.langchain.com/oss/python/langchain/overview`.

#### Freshness and consistency contracts for memory stores

CrewAI publishes recency mechanics for memory recall. Recall ranking uses a composite score blending semantic similarity, freshness, and importance; freshness uses exponential decay with the formula `0.5^(age_days / half_life_days)`, and the weights for semantic relevance, recency, and importance are configurable. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI publishes a consistency contract for asynchronous writes: `remember_many()` saves in a background thread, `recall()` waits for pending writes before searching, and crew shutdown drains pending memory writes so saves are not lost. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI publishes failure behavior for derived memory artifacts. LLM analysis failures generally do not stop memory operations; saves fall back to root scope, empty categories, and default importance. Extract-memory failures store the original content as one memory. Query-analysis failures fall back to simpler vector retrieval. Storage or embedder failures can still raise errors. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

CrewAI's documentation includes a privacy caveat relevant to derived prompt inputs: memory content may be sent to the configured LLM for analysis, so local LLMs and local embedders are recommended for private or offline use. Source: CrewAI docs, `https://docs.crewai.com/concepts/memory`.

#### Overall contract pattern observed

Provider-level cache contracts are about freshness of cached computations and exactness of input matching. They tend to publish TTLs, minimum token thresholds, identity requirements, invalidation rules, isolation boundaries, and usage counters.

Framework-level derived-input contracts are mostly behavioral rather than fidelity-based. The documentation describes when histories are reduced, what is preserved, where summaries are inserted, how memories are ranked, and what fallbacks occur. Across the fetched Semantic Kernel, LlamaIndex, LangChain, and CrewAI material, no source stated that summaries or extracted memories are lossless, complete, or guaranteed accurate representations of the original prompt history.
