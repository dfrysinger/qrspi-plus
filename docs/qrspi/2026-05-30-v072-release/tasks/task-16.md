---
status: approved
task: 16
phase: 1
pipeline: full
goal_ids: [G22]
task_type: code
model: opus
sizing_exception: schema-migration
---

# Task 16: G22 `model_routing` config schema and agent-sweep migration

- **Target files:** modify `config.md`; create/modify `scripts/_resolve-lib.sh`; create/modify `skills/_shared/config-validation-procedure.md`; modify `skills/using-qrspi/SKILL.md`; modify `skills/plan/SKILL.md`; modify `skills/implement/SKILL.md`; modify `skills/test/SKILL.md`; modify all `agents/qrspi-*.md`; modify `tests/unit/test-config-model-routing.bats`; modify `tests/unit/test-routing-matrix-application.bats`
- **Dependencies:** none. **Blocks:** T17 (G23 validation-table row and fail-loud cross-links depend on this task's canonical schema and stable fail-loud paragraphs); T19 (extends `scripts/_resolve-lib.sh` with the host × vendor matrix and default-second-reviewer lookup helpers and the matrix-lookup-time `[second-reviewer-same-vendor]` halt).
- **LOC estimate:** ~320

**Overview**

Migrate routing to the unified vendor-neutral `model_routing:` schema and single agent/task `tier:` signal, covering config docs, resolver behavior, skill-prose cleanup, agent frontmatter, and routing tests in one coordinated schema-migration wave. This intentionally stays bundled so no dispatch path reads deleted `model_role:` / `model:` fields or silently falls through to stale hardcoded model defaults. (Why: see goals.md ### G22. Architecture: see design.md ### CD-1. Residual rubric/doc cleanup: see design.md ## G22.)

**Scope**

- **In:**
  - Update `config.md` to expose the five-tier vendor-neutral `model_routing:` shape (`extra-low`, `low`, `medium`, `high`, `extra-high`), `default_tier: medium`, and `extra-low: none` as the explicit operator opt-in surface.
  - Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → hardcoded `medium` with loud warning), tier-to-`(vendor, model)` lookup, host/vendor routing lookup, and halt-on-`none` behavior.
  - Create/update `skills/_shared/config-validation-procedure.md` so missing or malformed `model_routing:` configuration fails loudly with repair-or-abort guidance.
  - Rewrite the G22 surfaces in `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md`: remove the old per-host `haiku`/`sonnet`/`opus`/`inherit` schema, remove the role-keyed G5 matrix, emit per-task `tier:` instead of `model:`, and read per-task `tier:` for Implement-phase test-writer dispatch with the test-writer agent's medium default for Test-phase acceptance dispatch.
  - Sweep all `agents/qrspi-*.md` frontmatter to add exactly one `tier:` field using the G22 rubric, delete the four legacy `model_role:` declarations, and add the `DISPATCH_FILE=<path>` first-action instruction to reviewer agents.
  - Preserve the dispatch order contract: TDD test-writer dispatch runs first, then implementer dispatch after the RED-verification gate, and high-tier code tasks co-escalate both dispatches to the same resolved `(vendor, model)` pair.
  - Update `tests/unit/test-config-model-routing.bats` and `tests/unit/test-routing-matrix-application.bats` to pin schema shape, validation, per-tag tier overrides, `none`-tier halt behavior, and implementer/test-writer co-escalation.

- **Out:**
  - Adding the `model_routing:` validation-table row and bidirectional fail-loud paragraph cross-links in `skills/using-qrspi/SKILL.md` — T17 owns.
  - Creating and including the Evergreen-Output Rule snippet across artifact-producing skills — T27 owns the shared G22-adjacent prose-quality surface.
  - Auto-escalating fix-retry-2/3 to `extra-high`, per-reviewer deep-mode tier escalation, and realized-tier telemetry — explicitly deferred by design.md ## G22 as future work.

**Definition of done**

- `config.md` documents the five-tier `model_routing:` block, includes `default_tier: medium`, and keeps `extra-low: none` as an operator opt-in surface.
- `_resolve-lib.sh` resolves tiers in the specified precedence order and halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model.
- The shared config-validation procedure fails missing or malformed `model_routing:` configuration with repair-or-abort guidance.
- Every `agents/qrspi-*.md` file has exactly one `tier:` frontmatter field; the five low-tier agents are `qrspi-finding-verifier`, `qrspi-implementer-lightweight`, `qrspi-research-collator`, `qrspi-research-specialist`, and `qrspi-scope-tagger`; all remaining agents are medium.
- The four legacy `model_role:` declarations are removed from agent frontmatter, and no dispatch prose instructs authors to use `model_role:` for routing.
- Every reviewer agent reads `DISPATCH_FILE=<path>` as its full dispatch before any other procedural step.
- `skills/using-qrspi/SKILL.md`, `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, and `skills/test/SKILL.md` no longer document or consume the superseded schema fields; Plan emits `tier:` using `lightweight → low`, ordinary code → `medium`, escalated code → `high`.
- A high-tier code task's per-task implementer dispatch and TDD test-writer dispatch resolve to the same `(vendor, model)` pair.
- Grep coverage confirms no `Agent({ ..., model: "sonnet" })` hardcoded dispatch argument remains in skill prose after migration.

**Test expectations**

- Inspect `config.md` for the five-tier vendor-neutral `model_routing:` block, `default_tier: medium`, and explicit `extra-low: none` row.
- Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and hardcoded-medium-with-warning precedence.
- Verify a dispatch resolving to a tier configured as `none` halts with a diagnostic naming the unresolved tier and does not fall back.
- Verify missing and malformed `model_routing:` configurations fail through the shared config-validation procedure with repair-or-abort guidance.
- Run an agent-frontmatter sweep: exactly five `tier: low` agents match the locked rubric, all other `agents/qrspi-*.md` files carry `tier: medium`, and no agent file carries `model_role:`.
- Grep reviewer agents for the `DISPATCH_FILE=<path>` first-action instruction.
- Grep skill prose to confirm the old per-host schema, role-keyed G5 routing matrix, `model:` task-routing field guidance, `test_writer_model`, and hardcoded `model: "sonnet"` dispatch arguments are gone from the migrated surfaces.
- Run/extend `tests/unit/test-config-model-routing.bats` for schema shape, missing `model_routing:` validation, malformed tier values, `none`-tier halt behavior, and fail-loud routing behavior.
- Run/extend `tests/unit/test-routing-matrix-application.bats` for per-tag `--tier-override` application in multi-agent dispatches and the implementer/test-writer co-escalation invariant.

**References**

- goals.md ### G22 — problem framing for contradictory `model_routing:` documentation and dead schema scaffolding.
- design.md ### CD-1 — universal dispatch architecture, tier precedence, config-owned model mapping, resolver behavior, and `DISPATCH_FILE` migration.
- design.md ## G22 — initial 41-agent tier rubric, doc-cleanup sweep, per-task `model:` → `tier:` migration, and acceptance criteria.
- structure.md ### `config.md` — schema-authority block for `model_routing:`, `default_tier:`, and `none` semantics.
- structure.md ### `scripts/_resolve-lib.sh` — shared resolver library responsibilities and precedence chain.
- structure.md ### `skills/_shared/config-validation-procedure.md` — repair-or-abort validation procedure for routing configuration.
- structure.md ### `skills/using-qrspi/SKILL.md` — high-traffic documentation rewrite surface for schema, trusted path, precedence, and validation adjacency.
- structure.md ### `skills/plan/SKILL.md` — Plan Step 2 migration from `model:` to `tier:` and co-escalation source field.
- structure.md ### `skills/implement/SKILL.md` — removal of the old four-layer chain / role-keyed G5 matrix and replacement pointers.
- structure.md ### `skills/test/SKILL.md` — test-writer dispatch migration to per-task `tier:` with medium fallback.
- structure.md ### `agents/qrspi-implementer.md` — dedicated implementer frontmatter tier row.
- structure.md ### `agents/qrspi-code-quality-reviewer.md` — representative reviewer `tier:` plus `DISPATCH_FILE` first-action row.
- structure.md ### `agents/qrspi-plan-reviewer.md` — reviewer `tier:` plus `DISPATCH_FILE` first-action row.
- structure.md ### `agents/qrspi-test-writer.md` — test-writer `tier:` row and `model_role:` deletion.
- structure.md ### `agents/*.md` (sweep — all 41 files) — full agent-frontmatter sweep, reviewer-body instruction, and `model_role:` deletion.
- structure.md ### `tests/unit/test-config-model-routing.bats` — schema, validation, and `none`-tier halt tests.
- structure.md ### `tests/unit/test-routing-matrix-application.bats` — per-tag override and co-escalation routing tests.
