---
status: draft
question_ids: [6]
research_type: codebase
---

# Q6: `model_routing:` schema, skill descriptions, and agent frontmatter survey

## Summary

**TL;DR:** The `model_routing:` block is a two-level YAML map keyed by dispatch host then by tier name (`haiku`, `sonnet`, `opus`, `inherit`), with values being fully versioned model IDs — as canonically defined in `skills/using-qrspi/SKILL.md`. By contrast, `skills/implement/SKILL.md`'s G5 routing matrix describes a different view: a role-to-`(provider, model)` mapping keyed by `model_role:` value. The v0.7.2 `config.md` does **not** contain a `model_routing:` block at all. Of the 41 agent files, exactly 4 declare `model_role:` and 0 declare `model:` — all 41 agents implicitly resolve via the `inherit` row after the T9 sweep.

**Key findings:**
- `skills/using-qrspi/SKILL.md` §"model_routing: block" (line 448) defines the schema as `{host} → {tier (haiku|sonnet|opus|inherit)} → fully versioned model ID`; two hosts shown: `claude-code` and `copilot-cli`.
- `skills/implement/SKILL.md` §"G5 Initial Routing Matrix" (line 548) describes the routing table as a `model_role: → (provider, model)` mapping with 5 named roles and a `Tier` + `Rationale` column — a structurally different shape from the using-qrspi schema.
- The current `config.md` for the v0.7.2 run (`docs/qrspi/2026-05-30-v072-release/config.md`) contains no `model_routing:` block; using-qrspi/SKILL.md line 516 specifies that the dispatcher fires a one-time in-memory warning and falls back to agent-bundled defaults in this case.
- 4 of 41 agents carry `model_role:` in their frontmatter: `qrspi-research-collator` (`research-collator`), `qrspi-research-specialist` (`research-specialist`), `qrspi-implementer-lightweight` (`lightweight-implementer`), `qrspi-test-writer` (`test-writer`).
- 0 of 41 agents carry a `model:` field in their frontmatter; using-qrspi/SKILL.md line 550 explicitly states this is "the state established for all 41 agents after the T9 sweep."
- All 41 agents implicitly use `inherit` (the routing row for agents with no explicit `model:` field).

**Surprises:** The two SKILL.md files describe structurally different schemas for the `model_routing:` block — `using-qrspi/SKILL.md` describes a host-keyed tier table, while `implement/SKILL.md` Layer 2 and the G5 matrix describe a role-keyed provider+model table. These are not reconciled into a single unified schema in either file.

**Caveats:** Only the v0.7.2 `config.md` was inspected (earlier run configs were not checked for active `model_routing:` blocks). The SKILL.md files were searched by line-level grep and targeted view; full sequential read was not performed on their entirety.

## Full findings

### Q6: `model_routing:` block schema and agent frontmatter survey

#### Schema defined in `skills/using-qrspi/SKILL.md` (dispatcher section)

**File:** `skills/using-qrspi/SKILL.md`, lines 448–553

The canonical schema is defined in the section `#### model_routing: block` (line 448). The schema is:

```yaml
model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
  copilot-cli:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
```

**Structure rules** (lines 450, 466–470):
- Top-level keys are host names emitted by `detect_host` — currently `claude-code` and `copilot-cli`.
- Each host sub-mapping contains **exactly four tier rows**: `haiku`, `sonnet`, `opus`, and `inherit`.
- Values must be **fully versioned model IDs** (e.g., `claude-haiku-4.5`), not bare tier short-forms (`haiku`, `sonnet`, `opus`). Bare short-forms cause Copilot CLI's model proxy to emit a "model not available" warning.
- The `inherit` row exists so agents that declare no explicit `model:` field still resolve to a concrete model ID.

**Validation:** The orchestrator validates these invariants at config-load time and on every dispatch. Missing top-level host keys, missing tier rows, or bare short-form values all cause the dispatcher to halt and report the missing/invalid entry (line 470). Silent fallback to agent-bundled defaults or host CLI re-routing is explicitly prohibited.

**Missing block behavior** (lines 514–526): When `model_routing:` is absent from `config.md`, the dispatcher fires a one-time in-memory warning `model_routing: absent from config.md — using agent-bundled defaults for this session` and proceeds in-memory only; the on-disk config is never mutated.

**Resolution flow** (lines 528–552 `#### Model Routing`): The dispatcher performs a two-step lookup — (1) host column selection via `detect_host`, (2) tier row selection from the agent's tier name or `inherit` for agents with no `model:` field. The resolved value is the concrete versioned model ID.

**Precedence chain** (lines 503–512):
1. Per-task `model:` override (highest)
2. Hardcoded dispatch-site `model:` override
3. `model_routing:` host/tier lookup (this block)
4. Agent-bundled default (lowest)
`trusted_path:` is a short-circuit outside this chain.

#### Schema described in `skills/implement/SKILL.md` (G5 routing matrix section)

**File:** `skills/implement/SKILL.md`, lines 525–560

The implement skill describes the routing table in two distinct ways:

**Four-Layer Chain (lines 525–541):** Layer 2 of the chain ("Layer 2 — `model_routing:` role-to-provider+model lookup," line 537) describes `model_routing:` as a **role-keyed table**: the dispatcher reads the agent's `model_role:` frontmatter field and looks up `config.md`'s `model_routing:` table for that role, yielding a `(provider, model)` pair. This is structurally different from the host-keyed tier schema in using-qrspi/SKILL.md.

**G5 Initial Routing Matrix (lines 548–560):** The matrix has columns `model_role:`, `Default route`, `Tier`, and `Rationale`. It contains 5 rows:

| `model_role:` | Default route | Tier |
|---|---|---|
| `qrspi-research-collator` | DeepSeek V3 (or current cheap tier) | cheap-model eligible |
| `qrspi-implementer-lightweight` | DeepSeek V3 (or current cheap tier) | cheap-model eligible |
| `qrspi-research-specialist` | DeepSeek V3, citation-density gated | cheap-model eligible (conditional) |
| general-purpose / Explore agent | Sonnet (Claude) | trusted |
| `qrspi-test-writer` | Sonnet (Claude) | trusted |

This matrix maps named agent roles to provider+model pairs, not to abstract tier names within a host sub-table. The implement skill describes this as "the role-to-`(provider, model)` mapping that ships as the default `model_routing:` block in `config.md`" (line 550).

**Contrast with using-qrspi schema:** The using-qrspi schema is host × tier → versioned model ID (no role-awareness). The implement G5 matrix is model_role → provider + model (no host-awareness). The two descriptions are not explicitly reconciled; `implement/SKILL.md` line 541 defers the warning text and backfill contract to `using-qrspi/SKILL.md` T01 but does not resolve the structural difference in the table format.

#### Current state of `config.md` (v0.7.2 run)

**File:** `docs/qrspi/2026-05-30-v072-release/config.md`

The v0.7.2 run config contains no `model_routing:` block. The frontmatter contains only: `created`, `pipeline`, `codex_reviews`, `route` (list), `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`. There is no `model_routing:`, `trusted_path:`, `validators:`, or `providers:` block.

Per `skills/using-qrspi/SKILL.md` line 516, the dispatcher will fire a one-time in-memory warning and use agent-bundled defaults for this session.

#### Agent frontmatter survey: `model_role:` and `model:`

**Total agent files:** 41 (confirmed by `find /agents -name "*.md" | wc -l`)

**Agents declaring `model_role:`** (4 of 41):

| Agent file | `model_role:` value |
|---|---|
| `agents/qrspi-research-collator.md` (line 4) | `research-collator` |
| `agents/qrspi-research-specialist.md` (line 4) | `research-specialist` |
| `agents/qrspi-implementer-lightweight.md` (line 4) | `lightweight-implementer` |
| `agents/qrspi-test-writer.md` (line 4) | `test-writer` |

**Agents declaring `model:`:** 0 of 41. No agent file has a `model:` field in its frontmatter.

**`inherit` vs. specific tier name:** Since no agent carries a `model:` field, all 41 agents implicitly resolve to the `inherit` row of the routing table at dispatch time. `skills/using-qrspi/SKILL.md` line 550 states this explicitly: "the state established for all 41 agents after the T9 sweep." Zero agents use a specific tier name (`haiku`, `sonnet`, `opus`) in their frontmatter.

**Agents with neither `model_role:` nor `model:`:** 37 of 41. These agents have no routing-relevant frontmatter fields at all and rely entirely on the `inherit` row and/or agent-bundled defaults.
