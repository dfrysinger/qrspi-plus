---
finding_id: F02
severity: high
change_type: correctness
referenced_files: [skills/using-qrspi/SKILL.md, tests/unit/test-agent-frontmatter-no-model.bats, docs/qrspi/2026-05-27-v071-hardening/config.md]
artifact: integration
round: 4
reviewer: integration-codex
materialized_by: orchestrator
materialization_reason: gpt-5.5 reviewer environment forbids file writes; finding returned inline
---

# integration-codex F02 — T10 tier lookup has no live tier source after T9 removed all agent `model:` fields

**Severity:** High
**Category:** Data-flow correctness / cross-task interface mismatch

T10's Model Routing flow says the tier comes from "the abstract Claude tier name carried on the agent" and uses `inherit` only when the agent declares no explicit `model:` field (`skills/using-qrspi/SKILL.md:524-527`, `skills/using-qrspi/SKILL.md:534-546`). But T9's lint enforces that all 41 `agents/qrspi-*.md` files have no top-level `model:` field (`tests/unit/test-agent-frontmatter-no-model.bats:65-71`), and T10's own test describes `inherit` as the state after T9 removed `model:` from all agents (`tests/unit/test-agent-frontmatter-no-model.bats:612-617`).

That means the data flow for normal agent dispatches is now: agent has no `model:` → resolver uses `inherit` → config maps `inherit` to Sonnet (`docs/qrspi/2026-05-27-v071-hardening/config.md:94-105`). The `haiku`, `sonnet`, and `opus` rows exist in the table, but T10 does not define a remaining agent/frontmatter field or dispatch metadata source that can select them. This makes the non-`inherit` tier rows effectively orphaned for the agent-routing path and loses any intended per-agent tier differentiation.

**Fix:** Define and test the actual tier source after `model:` removal — for example, a new non-host-model field such as `model_tier:` / `model_role:`, or an explicit dispatch-site tier override — and update Model Routing prose/tests to consume that source instead of the removed `model:` field.
