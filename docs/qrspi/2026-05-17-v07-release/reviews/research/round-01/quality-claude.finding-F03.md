---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L142-L155]
artifact: research
round: 1
reviewer: quality-claude
---

The combined Q9/Q28 section addresses two `[web]` research questions about large stable inputs and freshness contracts for derived prompt inputs. None of its five Key findings bullets carry a URL or source-attribution citation. The bullets make specific quantitative factual assertions about provider behavior — "Anthropic prompt caching uses explicit or automatic cache breakpoints over the ordered prefix hierarchy `tools -> system -> messages`, with 5-minute and 1-hour ephemeral TTLs", "Azure OpenAI prompt caching is enabled by default for supported models, works on identical initial prompt prefixes of at least 1,024 tokens, reports `cached_tokens`, and has in-memory retention usually cleared after 5-10 minutes of inactivity and always within one hour of last use; newer/eligible models can use extended retention up to 24 hours", "Vertex AI context caching supports explicit reusable cached content for Gemini prompts, with a default 60-minute TTL", and "CrewAI publishes a more operational memory contract... `recall()` waits for pending background writes before searching" — and the Caveats note "OpenAI platform docs returned HTTP 403, so Azure OpenAI and OpenAI's public prompt-caching announcement were used".

None of these specific TTL/threshold/retention numbers cite the documentation page from which they came. The reviewer-protocol research check requires `[web]` research to include URLs and source attribution for every factual claim. The Caveats acknowledgement of which providers were substituted does not equal a URL trail for each cited number.
