# Round-06 spec gate — Codex (gpt-5.3-codex) — ✅ APPROVED (orchestrator-persisted; Codex returns chat-only)

Scope: fix-5 delta only (round-05 cleared the full task spec gate).
Verified: F01 normalize-once for both none-check+emit (_resolve-lib.sh:149-167);
F02 distinct CONFIG-missing halt (127-135); F03 allowlist before interpolation (122-126) +
indented row anchor (137-141); resolve_tier Layer-4 medium fallback preserved (100-113, warn+exit0);
trusted_path correctly deferred (header 9-12, using-qrspi 482-485); bash 3.2 portable;
behavioral tests added (test-config-model-routing.bats:325-520).
Advisory (non-blocking): _normalize_tier_value `tr -d '[:space:]'` collapses internal whitespace
in the emitted { vendor:, model: } object — acceptable while no executable resolve_model consumer
exists (dispatch-agent.sh absent); semantics preserved. Surfaced to clarity reviewer.
