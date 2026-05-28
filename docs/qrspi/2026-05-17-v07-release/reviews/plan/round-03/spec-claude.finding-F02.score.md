---
finding_id: R3-F02
reviewer: spec-claude
verifier_score: 90
verdict: KEEP
---

High-severity. Verified: T01 defines only two transport_type values (`openai-chat-completions`, `codex-broker`); "Anthropic SDK path" appears nowhere in schema. Implementer cannot resolve the condition. Convergent with quality.R3-F04, test-coverage.R3-F01. Resolved via cluster's dual-flag gating.
