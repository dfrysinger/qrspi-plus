---
finding_id: R5-F01
severity: medium
change_type: security
referenced_files:
  - skills/using-qrspi/SKILL.md
  - tests/unit/test-using-qrspi-vocab.bats
artifact: integration
round: 5
reviewer: security-codex
materialized_by: orchestrator
materialization_reason: gpt-5.5 reviewer agent runs under env that forbids disk writes per established inline-handling pattern; orchestrator persists finding body returned in response text.
---

## Trusted-path fix closes R4-F01 locally, but other step-4 bypasses still reach the empty agent-bundled default

The new `trusted_path:` paragraph does close security-claude's three enumerated choices for that specific branch: it requires halt/report and forbids silent fallback to both `model_routing:` and host CLI re-routing (`skills/using-qrspi/SKILL.md:488`). However, the closure is not full because the merged SKILL still has other dispatch paths that explicitly bypass `model_routing:` and route to the agent-bundled default, which is empty after the T9 sweep.

Remaining bypass paths:

1. **Validator trusted-model re-run bypasses `model_routing:` and goes to empty step 4.**
   The citation-density validator says a failed dispatch triggers "a trusted-model re-run" to "the agent-bundled default model (bypassing `model_routing:`)" (`skills/using-qrspi/SKILL.md:499`). Post-T9, that default has no concrete value. Unlike the fixed `trusted_path:` branch, this path has no fail-loud rule, so a dispatcher can still silently fall to either `model_routing:` or the host CLI default when the validator fires.

2. **Missing `model_routing:` still proceeds with agent-bundled defaults.**
   The "Missing `model_routing:` block" section instructs the dispatcher to warn once and continue "using agent-bundled defaults for this session" (`skills/using-qrspi/SKILL.md:512-517`), with in-memory defaults applied thereafter (`skills/using-qrspi/SKILL.md:518-522`). That is also empty after T9, and it bypasses the fail-loud invariant that normal `model_routing:` corruption must halt rather than fall through (`skills/using-qrspi/SKILL.md:470`, `skills/using-qrspi/SKILL.md:545-548`).

The regression tests added in this fix only pin the `trusted_path:` H4 (`tests/unit/test-using-qrspi-vocab.bats:136-159`), so they would not catch either remaining bypass.

This means the R4 trusted-path gap is fixed, but the underlying cross-task class remains: after T9 removed agent `model:` fields, any prose path that says "bypass `model_routing:` and use the agent-bundled default" can still resolve to an empty model and silently defer to host behavior. A complete closure should either add the same fail-loud contract to these paths or centralize a rule that **any** attempt to use step 4 when the agent has no concrete `model:` halts and reports rather than falling through.
