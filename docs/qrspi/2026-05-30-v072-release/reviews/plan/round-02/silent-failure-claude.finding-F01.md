---
finding_id: F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 16 `_resolve-lib.sh` precedence ends in "hardcoded `medium` with loud warning" — log-and-continue instead of halt

## Where

Task 16 (G22 `model_routing` config schema and agent-sweep migration), `**In:**` bullet for `_resolve-lib.sh`, and the matching DoD bullet:

> Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → **hardcoded `medium` with loud warning**), tier-to-`(vendor, model)` lookup, …

> `_resolve-lib.sh` resolves tiers in the specified precedence order and halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model.

The "hardcoded `medium` with loud warning" precedence step contradicts the "never silently falls back … to an agent-bundled model" promise immediately below it: emitting a warning and proceeding at `medium` is exactly a silent fallback to a hard-coded model identifier (just with a log line).

## Why this matters

`goals.md ### G22` frames the problem this release is fixing as exactly this class:

> "silently falls through to stale hardcoded model defaults"

The plan removes the old `model_role:` schema and adds loud halt for missing/malformed `model_routing:` (Task 17) and for `none`-tier selection. But the final precedence step in Task 16 reintroduces a defensive hardcoded-`medium` path. A misconfigured deployment where the override is unrecognized, the agent has no `tier:`, and `default_tier:` is absent/malformed will:

1. Emit one warning line to stderr.
2. Resolve `medium` from the hardcoded constant.
3. Dispatch the reviewer/implementer at whatever vendor/model `medium` maps to in the partially-valid `model_routing:` block.

The caller (orchestrator main chat) cannot distinguish "intentional medium" from "fallback medium" without parsing stderr. The dispatched subagent runs at a tier the operator did not authorise, and the round completes "successfully." This is the LOG_AND_CONTINUE pattern: a critical configuration resolution failure produces telemetry instead of a halt.

It also conflicts with Task 18's class-level invariant paragraph (G25), which the plan says must:

> require a loud halt with a named diagnostic for unresolved routing, model, provider, tier, trusted-path, validator-rerun, or fallback target cases

— "fallback target" specifically. A hardcoded-medium-with-warning final step IS a fallback target.

## What the plan should require instead

The precedence chain should end in **halt** when no resolved tier is available:

`--tier-override` → agent `tier:` → `default_tier:` → **halt with named diagnostic** ("no tier resolved; configure `default_tier:` or pass `--tier-override`").

If a defensive "last-resort default" is genuinely desired for development ergonomics, it should be opt-in via an explicit `QRSPI_ALLOW_TIER_FALLBACK=1` envvar that the validation procedure (and CI) treats as a misconfig signal, not as a normal-runtime branch.

Suggested edit to Task 16's `**In:**` bullet and matching DoD bullet: replace "→ hardcoded `medium` with loud warning" with "→ halt with named diagnostic when no tier is resolved (no silent hardcoded fallback)" and add a Test Expectations row: "A dispatch with no override, no agent `tier:`, and no `default_tier:` exits non-zero with a diagnostic naming the unresolved tier and does not dispatch at a hardcoded default."
