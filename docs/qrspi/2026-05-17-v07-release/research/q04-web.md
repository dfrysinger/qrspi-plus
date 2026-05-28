---
status: draft
question_ids: [4,5]
research_type: web
---

# Q4, Q5: OpenAI-compatible third-party LLM endpoints and CLI/agent invocation patterns

## Summary

**TL;DR:** Current third-party LLM endpoints commonly expose an OpenAI-style `POST /v1/chat/completions` surface with `model`, `messages`, OpenAI-like generation controls, `choices[]`, `usage`, and SSE streaming terminated by `data: [DONE]`. Compatibility is uneven: providers add reasoning/search/cost/performance fields, silently ignore some OpenAI parameters, or reject unsupported parameters with `400`/validation errors. Public CLI and agent-harness writeups repeatedly use the same integration pattern: configure a provider key plus OpenAI-compatible base URL, keep an OpenAI SDK or OpenAI-shaped client, route model names through provider-specific prefixes/aliases, and account for streaming, tools, token limits, cost, and per-provider feature drift.

**Key findings:**
- DeepSeek, Mistral, Together, Fireworks, xAI, Groq, Anthropic, and several aggregator/hosted APIs document OpenAI-style Chat Completions compatibility, usually centered on `messages`, `model`, OpenAI-like optional parameters, `choices`, `usage`, and SSE chunks.
- Streaming semantics are highly consistent across fetched provider docs: `stream: true` returns `text/event-stream` / SSE chunks, usually object type `chat.completion.chunk`, with deltas under `choices[].delta`, and a terminal `data: [DONE]` sentinel.
- Error conventions are less consistent than request/response shape: Together documents OpenAI-like `error.message/type/param/code`; Fireworks and Perplexity expose validation-style `422` bodies; Groq documents `400` for unsupported fields; Anthropic says it preserves OpenAI-compatible error format but not identical detailed messages.
- CLI/agent harness writeups converge on base-URL/key configuration, model aliases or provider-prefixed model IDs, OpenAI SDK reuse, and per-provider compatibility checks for tool calling, streaming, JSON/structured output, rate limits, context windows, and cost.

**Surprises:** Anthropic's compatibility layer is explicitly positioned as a testing/comparison layer rather than a production-ready long-term interface, and it documents many ignored OpenAI fields rather than hard errors. Groq's OpenAI compatibility page states unsupported supplied fields produce `400`, while Anthropic states most unsupported fields are silently ignored.

**Caveats:** No WebSearch tool was available in this environment; investigation used WebFetch and source URLs. WebFetch intermittently failed for some source pages because the safety classifier was temporarily unavailable, so Q5 includes cited public documentation pages and source-attributed patterns but is not an exhaustive survey of all public writeups. Provider docs change frequently; findings are as of the fetched documentation during this run.

## Full findings

### Query planning

For Q4, I searched for official third-party API documentation pages that either claim OpenAI compatibility or expose a Chat Completions endpoint: DeepSeek, Mistral, Together AI, xAI, Groq, Fireworks, Perplexity, Anthropic's OpenAI SDK compatibility layer, and aggregator/hosted services such as OpenRouter/Cerebras/Vertex AI where fetches were attempted. I extracted endpoint/base URL, request fields, response fields, streaming behavior, and error conventions.

For Q5, I targeted public developer or tool documentation for CLI/agent harnesses and OpenAI-compatible routing: LiteLLM, Aider, Simon Willison's `llm` CLI, Continue, plus provider OpenAI-SDK compatibility pages that show how an OpenAI-shaped client is pointed at a non-OpenAI endpoint. I looked for recurring invocation patterns: environment variables, base URL overrides, provider-prefixed model names, aliases, streaming/tool behavior, retries/fallbacks, rate limits, and cost tracking.

### Q4: Current third-party OpenAI Chat Completions compatibility surfaces

#### Common compatibility surface

Across fetched provider docs, the common compatibility surface is an HTTP JSON API shaped like OpenAI Chat Completions:

- Endpoint pattern: usually `POST /v1/chat/completions` or a provider-specific base URL plus `/chat/completions`.
- Authentication pattern: bearer token in `Authorization` headers.
- Required request fields: `model` and `messages`.
- Message shape: role/content objects with roles such as `system`, `user`, `assistant`, and `tool`; several providers also support deprecated `function`/`function_call` compatibility fields.
- Optional generation controls: `temperature`, `top_p`, `max_tokens` or `max_completion_tokens`, `stop`, `stream`, `n`, penalties, `seed`, `tools`, `tool_choice`, `response_format`, and logprob-related fields, though support differs by provider/model.
- Non-streaming response shape: `id`, `object`, `created`, `model`, `choices`, and `usage`, with each choice carrying `index`, `message`, and `finish_reason`.
- Streaming response shape: SSE / `text/event-stream`, `chat.completion.chunk` objects, partial deltas under `choices[].delta`, and `data: [DONE]` termination.

#### DeepSeek

Source: https://api-docs.deepseek.com/api/create-chat-completion

DeepSeek documents a `POST /chat/completions` endpoint that creates a model response for a chat conversation. The fetched page lists a beta base URL for prefix features, `https://api.deepseek.com/beta`, and otherwise presents an OpenAI-shaped chat-completion request.

Request shape:

- Required `messages` array with at least one message.
- Required `model`, with documented values `deepseek-v4-flash` and `deepseek-v4-pro` in the fetched page.
- Supported roles: `system`, `user`, `assistant`, and `tool`.
- Optional fields include `thinking`, `max_tokens`, `response_format`, `stop`, `stream`, `stream_options.include_usage`, `temperature`, `top_p`, `tools`, `tool_choice`, `logprobs`, `top_logprobs`, and `user_id`.
- `frequency_penalty` and `presence_penalty` are described as deprecated/no-op in the fetched output.

Response shape:

- Non-streaming responses return `object: chat.completion`, with `id`, `created`, `model`, `system_fingerprint`, `choices`, and `usage`.
- Choices include `index`, `finish_reason`, `message.role`, `message.content`, optional `reasoning_content`, optional `tool_calls`, and optional `logprobs`.
- Usage includes `completion_tokens`, `prompt_tokens`, cache hit/miss token counts, `total_tokens`, and `completion_tokens_details.reasoning_tokens`.

Streaming:

- `stream` returns `text/event-stream`.
- Partial message deltas are delivered as data-only SSE events.
- Chunks use `object: chat.completion.chunk` and carry `delta.content`, optional `delta.reasoning_content`, optional `delta.role`, nullable `finish_reason`, and nullable `logprobs`.
- `stream_options.include_usage` adds an extra usage chunk before `[DONE]`; that chunk has empty `choices`.
- The stream terminates with `data: [DONE]`.

Error/finish conventions:

- The fetched page did not list general HTTP error codes.
- It defines `finish_reason` values: `stop`, `length`, `content_filter`, `tool_calls`, and `insufficient_system_resource`.

#### Mistral AI

Source: https://docs.mistral.ai/api/endpoint/chat

Mistral documents `POST https://api.mistral.ai/v1/chat/completions` / `POST /v1/chat/completions` as its Chat Completion API.

Request shape:

- Required `model` string and `messages` array.
- Message roles include system, user, assistant, and tool messages.
- Optional fields include `max_tokens`, `temperature`, `top_p`, `stream`, `tools`, `tool_choice`, `response_format`, penalties, `random_seed`, `stop`, and `n`.

Response shape:

- Non-streaming success returns JSON with required `id`, `object`, `created`, `model`, `choices`, and `usage`.
- Each choice includes fields such as `finish_reason`, `index`, and `message`.

Streaming:

- `stream: true` returns data-only server-sent events.
- The stream ends with `data: [DONE]`.
- Successful response content types include `application/json` and `text/event-stream`.

Error conventions:

- The fetched page content only showed `200` successful responses and did not specify error status codes or error body shape.

#### Together AI

Source: https://api.together.ai/v1/chat/completions

Together documents an OpenAI-style endpoint at base URL `https://api.together.ai/v1`, method/path `POST /chat/completions`, with bearer token authentication and `application/json` content type.

Request shape:

- Required `model` and `messages`.
- Roles: `system`, `user`, `assistant`, `tool`, and deprecated `function`.
- User content may be a string or multimodal array containing `text`, `image_url`, `video_url`, `audio_url`, or `input_audio`.
- Common generation fields include `max_tokens`, `temperature`, `top_p`, `top_k`, `min_p`, `stop`, `stream`, `n`, `seed`, `repetition_penalty`, `presence_penalty`, `frequency_penalty`, `logit_bias`, `logprobs`, and `echo`.
- Tool/function fields include `tools`, `tool_choice`, and deprecated-style `function_call`.
- Structured output options include `response_format` values `text`, `json_object`, and `json_schema`.
- Provider-specific fields include `context_length_exceeded_behavior`, `safety_model`, `reasoning_effort`, `reasoning.enabled`, `chat_template_kwargs`, and `compliance`.

Response shape:

- Non-streaming responses include `id`, `object: chat.completion`, `created`, `model`, `choices`, `usage`, `prompt`, and `warnings`.
- Choice messages include assistant `role`, `content`, `tool_calls`, `function_call`, and `reasoning`.
- Usage includes `prompt_tokens`, `completion_tokens`, and `total_tokens`.
- Finish reasons include `stop`, `eos`, `length`, `tool_calls`, and `function_call`.

Streaming:

- `stream: true` returns SSE.
- Stream chunks have object type `chat.completion.chunk`.
- Each chunk contains `choices[].delta`, which may include role, content, reasoning, tool calls, or function call data.
- The stream ends with `data: [DONE]`.

Error conventions:

- Documented HTTP statuses: `400` BadRequest, `401` Unauthorized, `404` NotFound, `429` RateLimit, `503` Overloaded, and `504` Timeout.
- Error body shape is OpenAI-like: top-level `error` with `message`, `type`, `param`, and `code`.

#### xAI

Source: https://api.x.ai/v1

xAI documents `POST https://api.x.ai/v1/chat/completions`, with OpenAI SDK examples using `base_url="https://api.x.ai/v1"` in Python and `baseURL: "https://api.x.ai/v1"` in JavaScript.

Request shape:

- Required `model` and `messages`.
- OpenAI-style parameters include `temperature`, `top_p`, `n`, `stream`, `stop`, `tools`, `tool_choice`, `parallel_tool_calls`, `response_format`, `logprobs`, `top_logprobs`, `user`, `seed`, and `max_completion_tokens`.
- `max_tokens` is deprecated in favor of `max_completion_tokens`.
- `logit_bias` is marked unsupported.
- Some reasoning models do not support `frequency_penalty`, `presence_penalty`, and `stop`; `logprobs`/`top_logprobs` are ignored for some newer models.
- Provider additions include `search_parameters` and `web_search_options`.

Response shape:

- Response fields include `id`, `object: chat.completion`, `created`, `model`, `choices`, `usage`, `system_fingerprint`, optional `citations`, and optional `output_files`.
- `choices[].message` can include `role`, `content`, `reasoning_content`, `refusal`, and `tool_calls`.
- Usage includes token counts plus provider-specific details such as `cost_in_usd_ticks` and `num_sources_used`.

Streaming:

- `stream: true` enables partial deltas over SSE.
- The stream ends with `data: [DONE]`.
- `stream_options.include_usage` can add a usage chunk before final done.

Error/deferred conventions:

- The fetched content explicitly documented deferred-completion status behavior: `200` for completed and `202` for pending.
- It did not include a general Chat Completions error-code table.

#### Groq

Source: https://console.groq.com/docs/openai

Groq states that its API is mostly compatible with OpenAI's client libraries. It instructs users to configure OpenAI clients with `base_url="https://api.groq.com/openai/v1"` and `api_key` set to `GROQ_API_KEY`.

Compatibility details:

- The fetched page implies existing OpenAI client-library usage works after changing the base URL and key.
- It does not document a full Chat Completions request/response schema on that page.
- Unsupported supplied fields produce a `400` error.
- Unsupported/request-constrained fields include `logprobs`, `logit_bias`, `top_logprobs`, and `messages[].name`.
- `N` must equal `1` if supplied.
- `temperature: 0` is converted to `1e-8`; Groq recommends using a float32 value greater than `0` and less than or equal to `2` if issues occur.

Streaming:

- The fetched OpenAI compatibility page did not specify streaming semantics.

#### Fireworks AI

Source: https://docs.fireworks.ai/llms.txt and endpoint `POST https://api.fireworks.ai/inference/v1/chat/completions`

Fireworks exposes an OpenAI-style Chat Completions endpoint at `/v1/chat/completions` under `https://api.fireworks.ai/inference/v1/chat/completions`.

Request shape:

- Required `model` and `messages`.
- Message fields include role, optional content, `reasoning_content`, `tool_calls`, and `tool_call_id`.
- Tool/function support includes OpenAI-style `tools`, `tool_choice`, and deprecated compatibility fields `functions` and `function_call`.
- Generation controls include `temperature`, `top_p`, `max_tokens`, `stop`, `n`, `presence_penalty`, `frequency_penalty`, `logprobs`, `top_logprobs`, `seed`, and `response_format`.
- Provider additions include prompt-cache controls, safe tokenization, prompt truncation behavior, reasoning controls, thinking config, speculative decoding/prediction, service tier, rollout/session-affinity controls, and MoE router replay.

Response shape:

- Non-streaming responses include `id`, `object`, `created`, `model`, `choices`, optional `usage`, optional `perf_metrics`, and optional prompt token IDs.
- Choices include `index`, `message`, optional `finish_reason`, optional `logprobs`, optional `raw_output`, and optional generated token IDs.

Streaming:

- `stream` sends partial chunks as SSE.
- Chunks use `object: chat.completion.chunk`, with deltas under `choices[].delta`.
- The stream ends with `data: [DONE]`.

Error conventions:

- Validation failure is documented as HTTP `422` with an `HTTPValidationError` body containing `detail` entries.

#### Perplexity

Source: https://docs.perplexity.ai/llms.txt and API server `https://api.perplexity.ai`

Perplexity's fetched documentation describes a chat-completion-like operation at base URL `https://api.perplexity.ai`, endpoint `POST /v1/sonar`, operation summary `Create Chat Completion`.

Request shape:

- Required `model` and `messages`.
- Message roles include `system`, `user`, `assistant`, and `tool`.
- Message content can be a string, structured content array, or null.
- Common chat-completion parameters include `max_tokens`, `temperature`, `top_p`, `stop`, `stream`, and `response_format`.
- Supported models in the fetched page include `sonar`, `sonar-pro`, `sonar-deep-research`, and `sonar-reasoning-pro`.

Response shape:

- Successful response fields include `id`, `model`, `created`, `object` defaulting to `chat.completion`, `choices`, optional `usage`, optional `citations`, optional `search_results`, optional `images`, and optional `related_questions`.
- Choices include `index`, `finish_reason`, `message`, and `delta`.
- Finish reasons include `stop` and `length`.

Streaming:

- `stream: true` returns SSE.
- `stream_mode` controls event format: `full` suppresses reasoning events and includes metadata inline; `concise` emits reasoning events separately.

Error conventions:

- `200` indicates successful response.
- `422` validation errors return `HTTPValidationError` with `detail[]` entries containing `loc`, `msg`, and `type`.

Provider additions:

- Search controls include `web_search_options`, `search_mode`, `enable_search_classifier`, `disable_search`, domain/language/recency/date filters.
- Citation/search/media outputs include `citations`, `search_results`, `return_images`, and `return_related_questions`.
- Reasoning/language controls include `reasoning_effort` and `language_preference`.
- Usage includes a `cost` object with token, search, citation, and total cost fields.

#### Anthropic OpenAI SDK compatibility layer

Source: https://platform.claude.com/docs/en/api/openai-sdk

Anthropic provides an OpenAI SDK compatibility layer using the base URL `https://api.anthropic.com/v1/` with Anthropic API keys and Claude model names. The page states the layer is primarily intended to test and compare model capabilities and is not considered a long-term or production-ready solution for most use cases.

Request compatibility:

- Standard OpenAI SDK `client.chat.completions.create()` examples are shown for Python and TypeScript.
- Supported simple fields include `model`, `max_tokens`, `max_completion_tokens`, `stream`, `stream_options`, `top_p`, `parallel_tool_calls`, `stop`, and `temperature`.
- `temperature` is accepted between `0` and `1`; values greater than `1` are capped at `1`.
- `n` must be exactly `1`.
- Many OpenAI fields are ignored: `logprobs`, `metadata`, `response_format`, `prediction`, penalties, `seed`, `service_tier`, `audio`, `logit_bias`, `store`, `user`, `modalities`, `top_logprobs`, and `reasoning_effort`.
- `tools`/`functions` names, descriptions, and parameters are supported, but `strict` is ignored.
- User text and image URL content are supported; audio/file input is ignored.
- System/developer messages are hoisted and concatenated into a single initial system message because Anthropic supports a single initial system message.

Response compatibility:

- Supported response fields include `id`, `choices[]`, `choices[].finish_reason`, `choices[].index`, `choices[].message.role`, `choices[].message.content`, `choices[].message.tool_calls`, `object`, `created`, `model`, `usage.completion_tokens`, `usage.prompt_tokens`, and `usage.total_tokens`.
- `choices[]` always has length `1`.
- Some fields are always empty: `usage.completion_tokens_details`, `usage.prompt_tokens_details`, `choices[].message.refusal`, `choices[].message.audio`, `logprobs`, `service_tier`, and `system_fingerprint`.

Streaming and errors:

- `stream` and `stream_options` are documented as fully supported.
- Rate limits follow Anthropic's standard limits for `/v1/messages`.
- Anthropic states the compatibility layer maintains consistent error formats with the OpenAI API, but detailed error messages are not equivalent.
- Supported header compatibility includes OpenAI-style rate-limit headers, `retry-after`, `request-id`, `authorization`, and fixed/empty OpenAI-specific compatibility headers.

### Q5: Public CLI/agent-harness patterns for invoking third-party LLM endpoints

#### Pattern 1: Reuse OpenAI clients by changing base URL, key, and model

Provider and tool docs repeatedly show the same minimal integration path: keep an OpenAI-compatible SDK/client and replace three configuration values.

Examples:

- Anthropic shows Python `OpenAI(api_key=os.environ.get("ANTHROPIC_API_KEY"), base_url="https://api.anthropic.com/v1/")` and then calls `client.chat.completions.create(...)` with a Claude model. Source: https://platform.claude.com/docs/en/api/openai-sdk
- Groq instructs configuring OpenAI clients with `base_url="https://api.groq.com/openai/v1"` and `api_key` set to `GROQ_API_KEY`. Source: https://console.groq.com/docs/openai
- xAI documents OpenAI SDK compatibility via `base_url="https://api.x.ai/v1"` in Python and `baseURL: "https://api.x.ai/v1"` in JavaScript. Source: https://api.x.ai/v1
- Together uses base URL `https://api.together.ai/v1` with `POST /chat/completions`. Source: https://api.together.ai/v1/chat/completions

Recurring concern: the OpenAI-shaped request may be syntactically accepted while individual fields are ignored, capped, rejected, or model-dependent. Anthropic documents many ignored fields; Groq documents `400` for unsupported fields; xAI marks some parameters unsupported or ignored for specific models.

#### Pattern 2: CLI/agent tools externalize provider details into env vars and config

Public CLI and agent-harness docs commonly avoid hard-coding provider credentials and endpoints. They use environment variables or config files for keys, API bases, model aliases, and provider names.

Examples and cited pages:

- Aider's OpenAI-compatible model documentation describes invoking non-OpenAI endpoints from a coding CLI by configuring an OpenAI-compatible API base/key and model name. Source: https://aider.chat/docs/llms/openai-compatible.html
- LiteLLM's documentation presents a gateway/proxy and SDK layer for calling many LLM providers through OpenAI-compatible request shapes, commonly configured through model/provider names, API keys, base URLs, and routing config. Source: https://docs.litellm.ai/docs/
- Simon Willison's `llm` CLI documents third-party model access through plugins and configured API keys/model aliases rather than a single hard-coded provider. Source: https://llm.datasette.io/en/stable/other-models.html
- Continue's model-provider documentation describes configuring model providers for an IDE/agent harness, including OpenAI-compatible providers through provider configuration, API base values, keys, and model roles. Source: https://docs.continue.dev/customize/model-providers/openai

Recurring concern: a harness must carry enough configuration to distinguish chat, edit, autocomplete, embedding, and reranking use cases, because a model/provider that works for interactive chat may not support low-latency autocomplete, tools, images, embeddings, or structured outputs.

#### Pattern 3: Provider-prefixed model identifiers and aliases decouple harness commands from endpoint details

CLI and agent harness writeups often route model selection through names that include a provider prefix, local alias, or configured model object. This gives the CLI a stable command-line selector while the underlying endpoint/base URL/key differ.

Examples:

- OpenAI-compatible provider docs require provider-specific model IDs even when the SDK class remains `OpenAI`; Anthropic examples use Claude model names, Groq uses Groq-hosted model names, and xAI uses Grok model names. Sources: https://platform.claude.com/docs/en/api/openai-sdk, https://console.groq.com/docs/openai, https://api.x.ai/v1
- LiteLLM-style routing uses provider/model names and a proxy to normalize multi-provider access. Source: https://docs.litellm.ai/docs/
- `llm` CLI documents plugin-backed model access and aliases for invoking non-default providers from the command line. Source: https://llm.datasette.io/en/stable/other-models.html

Recurring concern: aliases hide endpoint complexity but do not eliminate compatibility differences. Harnesses still need provider/model metadata for context windows, max output tokens, pricing, image support, tool support, and streaming behavior.

#### Pattern 4: Streaming is treated as a first-class harness concern

Provider docs for DeepSeek, Mistral, Together, Fireworks, Perplexity, and xAI all document streaming via SSE or `text/event-stream`; most use OpenAI-like `chat.completion.chunk` events and terminate with `data: [DONE]`. Sources: https://api-docs.deepseek.com/api/create-chat-completion, https://docs.mistral.ai/api/endpoint/chat, https://api.together.ai/v1/chat/completions, https://docs.fireworks.ai/llms.txt, https://docs.perplexity.ai/llms.txt, https://api.x.ai/v1

Patterns for CLI/agent harnesses:

- Stream tokens to the terminal or IDE as chunks arrive.
- Parse OpenAI-like `choices[].delta` for content/tool deltas.
- Handle a final sentinel (`data: [DONE]`) and optional usage chunk before done.
- Keep non-streaming fallback paths because not every compatibility page documents streaming in detail; Groq's fetched OpenAI compatibility page did not specify streaming behavior on that page.

Recurring concern: token streaming is not just a display feature for agents; it affects cancellation, partial-output handling, tool-call accumulation, terminal UI refresh, and usage accounting.

#### Pattern 5: Tool calling and structured output require provider-specific checks

OpenAI-compatible surfaces expose tool/function fields, but support differs.

Examples:

- Together supports `tools`, `tool_choice`, deprecated `function_call`, and `response_format` values including `json_object` and `json_schema`. Source: https://api.together.ai/v1/chat/completions
- Fireworks supports `tools`, `tool_choice`, and deprecated `functions`/`function_call`, plus provider-specific reasoning/thinking and raw-output fields. Source: https://docs.fireworks.ai/llms.txt
- Anthropic supports tool/function names, descriptions, and parameters through its compatibility layer, but ignores `strict` and recommends native Claude API structured outputs for guaranteed schema conformance. Source: https://platform.claude.com/docs/en/api/openai-sdk
- DeepSeek supports function tools and `tool_choice`, plus `reasoning_content` and thinking controls. Source: https://api-docs.deepseek.com/api/create-chat-completion

Recurring concern: an agent harness cannot infer full tool-calling reliability from the presence of an OpenAI-shaped field. It must know whether `strict` schemas, parallel tool calls, JSON response formats, tool deltas in streaming, and provider-specific reasoning fields are actually honored.

#### Pattern 6: Error handling and retry logic cannot rely on a single universal convention

The fetched docs show several error styles:

- Together documents OpenAI-like error bodies with `error.message`, `error.type`, `error.param`, and `error.code`, and status codes including `400`, `401`, `404`, `429`, `503`, and `504`. Source: https://api.together.ai/v1/chat/completions
- Fireworks documents `422` validation failures with `HTTPValidationError.detail`. Source: https://docs.fireworks.ai/llms.txt
- Perplexity documents `422` validation errors with `detail[]` entries containing `loc`, `msg`, and `type`. Source: https://docs.perplexity.ai/llms.txt
- Groq documents `400` for unsupported supplied fields. Source: https://console.groq.com/docs/openai
- Anthropic states its compatibility layer keeps OpenAI-compatible error formats, but detailed messages are not equivalent. Source: https://platform.claude.com/docs/en/api/openai-sdk

Recurring concern: CLI/agent harnesses need normalized error classification for authentication failures, validation failures, unsupported parameters, rate limits, overloaded providers, timeouts, and context-length issues. OpenAI-compatible request shape does not imply identical error status codes or bodies.

#### Pattern 7: Cost, usage, and provider telemetry are increasingly part of the response surface

OpenAI-style `usage` fields are common, but providers add accounting or telemetry fields.

Examples:

- xAI usage includes token details plus `cost_in_usd_ticks` and `num_sources_used`. Source: https://api.x.ai/v1
- Perplexity usage includes a `cost` object with token, search, citation, and total cost fields. Source: https://docs.perplexity.ai/llms.txt
- Fireworks responses can include `perf_metrics`, raw outputs, and token IDs. Source: https://docs.fireworks.ai/llms.txt
- DeepSeek usage includes prompt-cache hit/miss token counts and reasoning-token details. Source: https://api-docs.deepseek.com/api/create-chat-completion

Recurring concern: agent harnesses that route across providers need usage normalization for billing display, budget limits, cache accounting, and model/provider comparison. A plain OpenAI `prompt_tokens`/`completion_tokens` parser loses provider-specific cost and performance data.

#### Pattern 8: Compatibility layers are documented as partial, not exact

The strongest repeated theme is that “OpenAI compatible” means a convenient integration baseline, not identical semantics.

Examples:

- Anthropic explicitly says its OpenAI SDK compatibility layer is primarily for testing/comparison and not a production-ready long-term solution for most use cases; it lists many ignored fields. Source: https://platform.claude.com/docs/en/api/openai-sdk
- Groq says it is “mostly compatible” with OpenAI client libraries and lists unsupported fields that return `400`. Source: https://console.groq.com/docs/openai
- xAI lists deprecated, unsupported, and model-specific ignored fields. Source: https://api.x.ai/v1
- Mistral, DeepSeek, Together, Fireworks, and Perplexity expose OpenAI-like schemas while adding provider-specific extensions for reasoning, search, safety, compliance, cache controls, performance, and cost. Sources: https://docs.mistral.ai/api/endpoint/chat, https://api-docs.deepseek.com/api/create-chat-completion, https://api.together.ai/v1/chat/completions, https://docs.fireworks.ai/llms.txt, https://docs.perplexity.ai/llms.txt

Recurring concern: CLI-driven and agent harnesses need a compatibility matrix or runtime capability model rather than treating every endpoint with `/chat/completions` as interchangeable.
