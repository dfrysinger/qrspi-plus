---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L75-L87]
artifact: research
round: 1
reviewer: quality-claude
---

The combined Q4/Q5 section addresses two `[web]` research questions about OpenAI-compatible third-party LLM endpoints and CLI/agent invocation patterns, but none of its four Key findings bullets carry a URL or source-attribution citation. The bullets make specific factual assertions about named third-party providers — "DeepSeek, Mistral, Together, Fireworks, xAI, Groq, Anthropic, and several aggregator/hosted APIs document OpenAI-style Chat Completions compatibility", "Streaming semantics are highly consistent across fetched provider docs: `stream: true` returns `text/event-stream` / SSE chunks, usually object type `chat.completion.chunk`, with deltas under `choices[].delta`, and a terminal `data: [DONE]` sentinel", "Together documents OpenAI-like `error.message/type/param/code`; Fireworks and Perplexity expose validation-style `422` bodies; Groq documents `400` for unsupported fields; Anthropic says it preserves OpenAI-compatible error format but not identical detailed messages", "CLI/agent harness writeups converge on base-URL/key configuration, model aliases or provider-prefixed model IDs, OpenAI SDK reuse" — and the Surprises bullet asserts comparative behavior across Anthropic vs. Groq compatibility pages. None of these claims cite the documentation page that supports them.

The Caveats note "investigation used WebFetch and source URLs" and "WebFetch intermittently failed for some source pages", but a generic Caveats reference is not equivalent to per-claim URL attribution. The reviewer-protocol research check requires `[web]` research to include URLs and source attribution for every factual claim; without per-claim URLs, downstream consumers cannot verify which provider's documentation supports each behavior claim.
