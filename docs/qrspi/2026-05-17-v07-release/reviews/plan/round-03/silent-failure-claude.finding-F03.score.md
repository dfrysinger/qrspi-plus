---
finding_id: R3-F03
reviewer: silent-failure-claude
verifier_score: 95
verdict: KEEP
---

CRITICAL ARCHITECTURE. Verified: T03 L219 ships unconditional cache_control insertion keyed on `supports_prompt_cache: true`. This contaminates T33's spike measurement — the probe cannot distinguish Path A (auto-cache works) from Path A-with-markers. T43's "conditional addition" is then redundant. Load-bearing for cluster resolution. Chose Resolution 1 variant: add `emit_cache_control_markers` flag (default false) — T01 schema, T03 dispatcher gating by dual-flag, T43 sets to true on Path B, T07/T36 update accordingly.
