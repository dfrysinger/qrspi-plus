---
finding_id: R3-F04
reviewer: quality-claude
verifier_score: 85
verdict: KEEP
---

Verified contradiction: T36 L1111 references `openai-chat-completions` transport for Path B cache_control, but T43 L1304 explicitly excludes non-Anthropic openai-chat-completions providers. Convergent with spec.R3-F02, test-coverage.R3-F01. Resolved via dual-flag (`supports_prompt_cache` + `emit_cache_control_markers`) in cluster.
