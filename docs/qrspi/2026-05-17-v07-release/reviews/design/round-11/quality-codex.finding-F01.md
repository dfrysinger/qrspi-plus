---
finding_id: R11-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L176-L182, docs/qrspi/2026-05-17-v07-release/design.md:L91-L97]
artifact: design
round: 11
reviewer: quality-codex
---

The G4 shell-shim caching recommendation says to put explicit `cache_control` markers into both the Codex companion and the future `scripts/run-third-party-llm.sh` request bodies, but G2 defines `run-third-party-llm.sh` as a generic OpenAI Chat Completions dispatcher for providers such as DeepSeek, Mistral, Together, Fireworks, xAI, and Groq. Anthropic-style prompt-cache `cache_control` fields are not a portable OpenAI-compatible request feature, and several OpenAI-compatible providers reject unsupported fields rather than ignoring them. As written, downstream Plan/Implement could add Anthropic-specific cache metadata to every third-party provider call and turn otherwise-valid cheap-path dispatches into 400/validation failures.

Fix: narrow the explicit `cache_control` requirement to provider transports that actually support it, or add a provider capability flag in `providers:` that causes the shell shim to omit cache metadata unless the selected provider declares support. The design can still keep the stable-prefix caching goal, but the OpenAI-compatible dispatcher must not unconditionally emit Anthropic-specific cache controls.
