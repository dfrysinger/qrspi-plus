---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: [skills/using-qrspi/SKILL.md, docs/qrspi/2026-05-27-v071-hardening/config.md, tests/unit/test-agent-frontmatter-no-model.bats]
artifact: integration
round: 4
reviewer: integration-claude
materialized_by: orchestrator
materialization_reason: reviewer environment writes output to response text only; orchestrator materializes
---

# integration-claude F01 — Tier-source orphaning: haiku/sonnet/opus rows unreachable after T9's `model:` removal

**Category:** Data-flow correctness across task boundaries (T9 ↔ T10)

The new `#### Model Routing` H4 at `skills/using-qrspi/SKILL.md:524-527` defines the tier source as "the abstract Claude tier name carried on the agent (`haiku`, `sonnet`, `opus`, or the implicit `inherit` when the agent declares no explicit `model:` field)." The schema H4 at `SKILL.md:450` and the resolution step at `SKILL.md:534-537` both treat the agent's `model:` field as the canonical tier-name carrier.

T9 (already merged, pinned by `tests/unit/test-agent-frontmatter-no-model.bats:65-71`) forbids a top-level `model:` key in every one of the 41 `agents/qrspi-*.md` frontmatter blocks. T10's own TE4 docstring acknowledges this state: "matches Claude's resolver default for custom agents that do not declare an explicit `model:` (which T9 removed from all 41 agent files)" (`test-agent-frontmatter-no-model.bats:491-493`).

**End-to-end data flow today:**
- Any `agents/qrspi-*.md` dispatched → no `model:` field present (T9 invariant) → tier resolves to `inherit` → `model_routing[<host>][inherit]` → `claude-sonnet-4.6` (per `config.md:88,94` and `config.md:93,99`).

The `haiku`, `sonnet`, and `opus` rows pinned by TE1–TE3 (`test-agent-frontmatter-no-model.bats:392-486`) exist in the table but have **no live agent-dispatch source** that can ever select them. They are write-only schema rows for the canonical agent-routing path established by the rest of v0.7.1.

Step 1 ("Per-task `model:` override") and step 2 ("Hardcoded dispatch-site `model:`") of the precedence chain (`SKILL.md:503-504`) can theoretically supply a tier name, but neither step is documented to carry tier-name values — both speak of `model:` as a versioned model ID per the legacy contract. The precedence-chain prose does not say "step 1/2 may also be a tier short-form that re-enters the model_routing table"; the loop closure is therefore not established by the merged text.

**Why this is high-severity correctness, not clarity:** the schema is locking in an invariant (three of four pinned tier rows must be present at exact values) where the production effect of those rows is unreachable. Any future contributor who edits a haiku/opus row will break the pin without changing any observable dispatch behavior, and any contributor who relies on per-tier differentiation for performance/cost reasons will silently get sonnet for every agent. The fail-loud philosophy of v0.7.1 (G7b/#204) is undermined the moment the schema documents a tier-selection knob that has no input wired to it.

**Fix (one of):**
1. Define and pin the actual tier source for the post-T9 world — likely `model_role:` (already declared on three agents) extended with a documented role→tier mapping, OR a new `model_tier:` frontmatter key explicitly carved out of T9's `model:` ban. Update the Model Routing H4 to name that source and add a sweep test analogous to T9's that pins the allowed values.
2. Or, scope T10 to `inherit`-only resolution for v0.7.1 and document the haiku/sonnet/opus rows as **forward-compatibility scaffolding only** (with explicit prose saying "no dispatch path in v0.7.1 selects these rows; they are reserved for a future tier-frontmatter task"). Drop the per-tier pins for haiku/sonnet/opus from TE1–TE3 since the rows have no behavioral surface to defend.

Either fix is acceptable; option (1) closes the contract, option (2) honestly documents the scaffolding state. The current text picks neither and ships internally contradictory.
