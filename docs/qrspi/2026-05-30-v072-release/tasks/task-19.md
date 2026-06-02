---
status: approved
task: 19
phase: 1
pipeline: full
goal_ids: [G27]
task_type: code
model: opus
sizing_exception: reusable primitives
---

# Task 19: G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration

- **Target files:** `scripts/second-reviewer-available.sh`, `scripts/_host-detect.sh`, `scripts/_resolve-lib.sh`, `skills/goals/SKILL.md`, `skills/using-qrspi/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, `tests/unit/test-second-reviewer-available.bats`, `tests/unit/test-dispatch-companion-availability.bats`, `tests/unit/test-routing-matrix-application.bats`
- **Dependencies:** Task 16. **Blocks:** Task 20.
- **LOC estimate:** ~210

**Overview**

Deliver the host-aware second-reviewer availability primitive and migrate the Goals-facing consumer prose away from the Claude-only Codex glob so Copilot CLI users are not silently opted out of second-model review. The task also centralizes host detection and the default second-reviewer matrix lookup so probe and dispatcher-facing tests use the same source of truth. (Why: see goals.md ### G27. Approach: see design.md ## G27.)

**Scope**

- **In:**
  - Create `scripts/_host-detect.sh` with a source-safe `detect_host` function that returns the canonical host identifiers for Copilot CLI, Claude Code, future Codex CLI support, and unknown hosts without filesystem probing or wrapper side effects.
  - Create executable `scripts/second-reviewer-available.sh` with no-arg default-vendor lookup, optional diagnostic vendor override, shared `_resolve-lib.sh` matrix consumption, and exactly one `[second-reviewer-unavailable]` stderr diagnostic on unavailable paths.
  - Extend `scripts/_resolve-lib.sh` with the host × vendor matrix and default-second-reviewer lookup helpers consumed by both the probe and dispatcher-facing routing tests, without a parallel hardcoded host table in the probe.
  - Migrate `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` from the Claude-only `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` glob to `bash scripts/second-reviewer-available.sh`, the vendor-neutral second-model-review question, and `second_reviewer: false` on probe failure.
  - Migrate `skills/reviewer-protocol/SKILL.md` same-surface prose and Expected-Reviewer Matrix field naming from `codex_reviews:` to `second_reviewer:` and make config-validation prose reject stray legacy `codex_reviews:` loudly rather than aliasing it.
  - Add or update the three named bats surfaces to pin probe behavior, shared-matrix use, dispatcher-facing second-reviewer fan-out coverage, and unavailable-second-reviewer halt behavior.

- **Out:**
  - Dispatch script renames, the shared reviewer-dispatch prose include, `await-round.sh` draining, and the twelve review-producing skill dispatch migrations — Task 20 owns that rename-and-dispatch surface.
  - Evergreen-output-rule snippet creation and include-site migration across artifact-producing skills — Task 27 owns that shared G27 sibling surface.
  - Multi-second-reviewer fan-out, per-reviewer-agent second-reviewer toggles, realized-dispatch telemetry, and DeepSeek or other v0.7.3+ default second-reviewer choices — explicitly out of G27 v0.7.2 scope.

**Definition of done**

- `scripts/_host-detect.sh` is safe to source under `QRSPI_SOURCE_ONLY=1`, performs no filesystem probes or wrapper side effects, and returns `copilot-cli`, `claude-code`, future `codex-cli`, or `unknown` for the supported environment signals.
- `scripts/second-reviewer-available.sh` exists, is executable, accepts an optional vendor override, and uses `_host-detect.sh` plus `_resolve-lib.sh` matrix helpers rather than local host-detection or host × vendor tables.
- The probe exits 0 for Copilot CLI and Claude Code defaults because the shared matrix names `openai-codex` as the default second-reviewer vendor for both hosts.
- Unknown host, missing default vendor, unknown vendor, and unavailable vendor all exit non-zero with exactly one stderr line beginning `[second-reviewer-unavailable]` and naming the detected host plus requested/default vendor.
- `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` contain no live Claude-only Codex availability glob and describe the vendor-neutral second-model-review flow using `bash scripts/second-reviewer-available.sh`.
- `skills/using-qrspi/SKILL.md` documents `second_reviewer:` as the canonical config field and the config-validation prose rejects legacy `codex_reviews:` with a rename-naming diagnostic instead of aliasing it.
- `skills/reviewer-protocol/SKILL.md` no longer contains `codex_reviews` and its Expected-Reviewer Matrix / same-surface prose uses `second_reviewer: true|false`.
- Routing-matrix coverage demonstrates that `second_reviewer: true` can emit primary and second-reviewer entries at the same tier, and unavailable second-reviewer resolution halts with `[second-reviewer-unavailable]` instead of silently falling back to single-reviewer dispatch.
- `_resolve-lib.sh`'s host × vendor matrix lookup halts loudly with `[second-reviewer-same-vendor]` when a `second_reviewer: true` resolution returns the same vendor for both the primary and second-reviewer slots in a single round; it never silently emits two dispatch spec lines that resolve to the same vendor under distinct reviewer tags. (The probe in `second-reviewer-available.sh` checks reachability only — slot distinctness is enforced at matrix-lookup time here.)

**Test expectations**

- Source-safety and host-signal tests for `_host-detect.sh`: `COPILOT_CLI=1` returns `copilot-cli`, `CLAUDE_PROJECT_DIR` returns `claude-code`, the future Codex signal returns `codex-cli` when implemented, and no known signal returns `unknown`.
- Executability and behavior tests for `scripts/second-reviewer-available.sh`: Copilot CLI and Claude Code default paths exit 0; unknown host, missing default vendor, unknown vendor, and unavailable vendor exit non-zero with one `[second-reviewer-unavailable]` diagnostic containing host and vendor.
- Override-boundary tests prove `second-reviewer-available.sh <vendor>` supports diagnostic vendor override but does not read `model_routing:` or enforce primary/second vendor distinctness.
- Shared-source tests fail if the probe carries a parallel hardcoded host table instead of using `_resolve-lib.sh` host × vendor/default-second-reviewer lookup helpers.
- Grep audits confirm `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` no longer contain `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`.
- Grep audit confirms `grep -nE 'codex_reviews' skills/reviewer-protocol/SKILL.md` returns no matches after the migration.
- Config-validation tests or grep-pinned prose confirm a stray legacy `codex_reviews:` field is rejected loudly with the rename-naming diagnostic and is not aliased to `second_reviewer:`.
- `tests/unit/test-routing-matrix-application.bats` proves same-tier primary + second-reviewer dispatch coverage under `second_reviewer: true` and `[second-reviewer-unavailable]` halt behavior when no eligible second reviewer exists.
- `tests/unit/test-routing-matrix-application.bats` also proves `[second-reviewer-same-vendor]` halt behavior: when a `second_reviewer: true` dispatch resolves primary and second-reviewer slots to the same vendor, `_resolve-lib.sh` halts with the diagnostic and emits no dispatch spec lines for that round.

**References**

- goals.md ### G27 — problem framing for the Claude-only availability glob and Copilot CLI silent opt-out.
- design.md ## G27 — D1-D6 config rename, probe script, SKILL prose rewrite, runtime routing, matrix extension, and reviewer-protocol matrix sweep.
- structure.md ### `scripts/_resolve-lib.sh` — shared host × vendor matrix and default-second-reviewer lookup helpers.
- structure.md ### `scripts/second-reviewer-available.sh` — probe interface, diagnostic boundary, and tests.
- structure.md ### `scripts/_host-detect.sh` — source-safe canonical host-detection primitive.
- structure.md ### `skills/using-qrspi/SKILL.md` — second-reviewer probe prose and `second_reviewer:` config documentation surface.
- structure.md ### `skills/goals/SKILL.md` — Goals reviewer/second-reviewer consumer surface touched by this migration.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer contract file whose Expected-Reviewer Matrix field naming is swept by G27.
- structure.md ### `tests/unit/test-second-reviewer-available.bats` — direct probe-unit coverage.
- structure.md ### `tests/unit/test-codex-review-codex-availability.bats` — rename-source block for `tests/unit/test-dispatch-companion-availability.bats` availability coverage.
- structure.md ### `tests/unit/test-routing-matrix-application.bats` — same-tier second-reviewer fan-out and unavailable-second-reviewer halt coverage.
