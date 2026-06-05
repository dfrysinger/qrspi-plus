---
finding_id: R9-F01
severity: high
change_type: correctness
referenced_files:
  - plan.md:L986-L987
  - plan.md:L1001
  - plan.md:L1013-L1015
---

# Fail-open model-routing default — hardcoded `medium` fallback when tier/default unresolved

**Problem.** The model-routing resolver permits a hardcoded `medium` fallback when the tier or default resolution fails, instead of mandatory halt (fail-closed) on an unresolved tier/default.

**Evidence.**
- `plan.md` L986-L987: tier-resolution path includes `medium` fallback.
- `plan.md` L1001: resolver fallthrough.
- `plan.md` L1013-L1015: default-derivation includes the hardcoded `medium`.

**Impact (per reviewer).** Misconfigured routing can still dispatch prompt content to an LLM under an implicit default, violating fail-closed behavior.

(Materialized by orchestrator from Codex chat-only return — Codex CLI chat-only-output constraint recurred.)
