---
reviewer: spec-claude
task: 16
round: 6
verdict: clean
scope: fix-5 delta (round-06) — 8 round-05 correctness findings
---

# Spec-gate verdict — task-16 round-06 (fix-5 delta): CLEAN

Scope of review = the fix-5 delta only (round-05 cleared the full task's spec
gate). All 8 round-05 correctness findings are resolved, the fix is additive,
and no scope creep was introduced.

## Finding-by-finding verification

- **F01 (none-halt defeated by inline comment) — FIXED.**
  `resolve_model` now strips the `${tier}:` key prefix then normalizes ONCE via
  `_normalize_tier_value` (sed strips a whitespace-preceded `#` comment, then
  `tr -d` strips surrounding whitespace) at `_resolve-lib.sh:153-155`. The SAME
  normalized `$value` drives both the `none`-check (line 159) and the success
  emit (line 166), so an inline `# operator opts in` comment can neither defeat
  the none-halt nor leak into stdout. Behavioral regression test pins it
  (test-config-model-routing.bats:430-439, asserts exit≠0 + HALT on
  `extra-low: none  # operator opts in`).

- **F02 (CONFIG-missing de-mask) — FIXED, additive.**
  `resolve_model:131-135` hard-fails immediately with a DISTINCT
  "CONFIG_MD is unset or not a readable file" diagnostic BEFORE the row lookup,
  separating a config-path error from an unconfigured-tier error.
  `resolve_tier:87-110` adds a `config_present` flag and the Layer-4 warning
  now names CONFIG_MD-unset vs present-but-no-default_tier as the cause. The
  precedence chain itself is untouched — these are guards, not a refactor.
  Tests: lines 421-428 (resolve_tier cause naming) and 465-470 (resolve_model
  distinct diagnostic).

- **F03 (tier allowlist before interpolation) — FIXED, additive.**
  New `_validate_tier` helper (lines 53-58) allowlist-guards the five legal
  tiers and is called at the top of `resolve_model` (line 125) BEFORE any
  grep/sed interpolation, and at each resolved layer in `resolve_tier`
  (lines 67, 79, 95). Rejects the `low|medium` ERE-alternation injection and
  `/`-bearing tiers. The row grep anchor was tightened from `^[[:space:]]*` to
  `^[[:space:]]+` (line 140) per the finding's partial-mitigation recommendation.
  Tests: lines 472-510 (injection + invalid-tier from override/agent/default).

- **F04 (stale "step 4" wording) — FIXED.**
  using-qrspi/SKILL.md:484 replaced the old four-layer-chain "step 4" language
  with new-schema wording: "there is no agent-bundled `model:` field; for a
  normal dispatch the dispatcher resolves the model from the agent's own
  `tier:` via `resolve_tier` (with no override)". No "step 4 / agent-bundled
  model:" concept remains.

- **F05 (extra-high prose contradiction) — FIXED, config value preserved.**
  Both config.md:35 and using-qrspi/SKILL.md:462 now state only `extra-low`
  defaults to `none`, and describe `extra-high` as the pre-configured
  high-ceiling escalation tier (`claude-opus-4.7-high`) an operator MAY set to
  `none`. The config value (`extra-high: { vendor: claude, model:
  claude-opus-4.7-high }`) is unchanged, as the finding directed.

- **F06 (stale RED/GREEN drafting comment) — FIXED.**
  test-routing-matrix-application.bats:168-176 now carries a forward-looking
  invariant description ("the count of agents whose frontmatter carries
  `tier: low` or `tier: medium` equals the total agent count") with no RED/GREEN
  drafting narration.

- **F07 (header overclaims scope re trusted_path) — FIXED.**
  Header (lines 1-12) scopes the library to "shared routing-resolution library"
  and adds an explicit NOT-implemented note that `trusted_path:` is a
  dispatch-site short-circuit evaluated before this library is consulted.

- **F08 (resolver tests prose/grep-only) — FIXED.**
  Behavioral exec block (test-config-model-routing.bats:325-520) sources the lib
  under `QRSPI_SOURCE_ONLY=1` and executes `resolve_tier`/`resolve_model`
  against hermetic fixtures: all four precedence layers (372-419), F01 none-halt
  with inline comment (430-439), clean commented-row emit (441-449),
  unconfigured-row halt (451-463), distinct CONFIG_MD-missing diagnostic
  (465-470), F03 allowlist rejection from override/agent/default (472-510), and
  the out-of-block shadow gap documented as a skip (512-520).

## Scope / preservation checks

- **resolve_tier Layer-4 hardcoded-medium fallback PRESERVED** — lines 106-112
  still `printf 'medium\n'; return 0` with a LOUD stderr warning (de-masked,
  NOT converted to a halt). Verified.
- **No scope creep — trusted_path enforcement correctly DEFERRED** — the lib
  does not add trusted_path evaluation; the header (lines 9-12) explicitly marks
  it dispatch-site-owned and out of scope. No flag.
- **bash 3.2 portability preserved** — `_normalize_tier_value` uses
  printf/sed/tr; `_validate_tier` uses `case`. No associative arrays, no
  `${var^^}`. Verified.
- **Fail-loud contract phrases (G7b/#204) intact** — using-qrspi:466, 484, 497,
  515 preserve the pinned silent-fallback-class prose.
- **Carve-outs respected** — G5 reference table, guarded `model: "sonnet"`
  examples, and intentional G7b/#204 fail-loud-halt prose not flagged.

## Advisory (non-blocking, not a spec-gate defect)

using-qrspi/SKILL.md:484 refers to "the new four-tier schema" while line 462
correctly describes "exactly five tier rows". The "four" most likely refers to
the four-LAYER precedence chain rather than the five-tier model_routing schema;
it is an imprecise adjective, not a correctness or completeness defect, and the
substantive F04 fix (removing the agent-bundled `model:` / "step 4" reference)
is correct. Surfaced here for the downstream clarity reviewer; does not gate.
